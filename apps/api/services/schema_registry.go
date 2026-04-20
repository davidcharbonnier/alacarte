package services

import (
	"encoding/json"
	"fmt"
	"sync"

	"github.com/davidcharbonnier/alacarte-api/models"
	"github.com/davidcharbonnier/alacarte-api/utils"
	"gorm.io/gorm"
)

type SchemaRegistry struct {
	mu      sync.RWMutex
	schemas map[string]*CachedSchema
}

type CachedSchema struct {
	Schema       *models.ItemTypeSchema
	Fields       []*models.ItemTypeField
	Version      *models.SchemaVersion
	VersionHash  string
	UniqueFields []string
}

var (
	registry     *SchemaRegistry
	registryOnce sync.Once
)

func GetSchemaRegistry() *SchemaRegistry {
	registryOnce.Do(func() {
		registry = &SchemaRegistry{
			schemas: make(map[string]*CachedSchema),
		}
	})
	return registry
}

func (r *SchemaRegistry) LoadSchemas() error {
	r.mu.Lock()
	defer r.mu.Unlock()

	var schemas []models.ItemTypeSchema
	if err := utils.DB.Preload("Fields", func(db *gorm.DB) *gorm.DB {
		return db.Order("`order` ASC")
	}).Where("is_active = ?", true).Find(&schemas).Error; err != nil {
		return fmt.Errorf("failed to load schemas: %w", err)
	}

	type schemaVersionResult struct {
		SchemaID uint
		Version  int
		Fields   string
	}

	var versionResults []schemaVersionResult
	if err := utils.DB.Model(&models.SchemaVersion{}).
		Select("schema_id, version, fields").
		Where("is_active = 1 AND schema_id IN (SELECT id FROM item_type_schemas WHERE is_active = 1)").
		Order("version DESC").
		Find(&versionResults).Error; err != nil {
		return fmt.Errorf("failed to load schema versions: %w", err)
	}

	versionMap := make(map[uint]*models.SchemaVersion)
	for i := range versionResults {
		vr := &versionResults[i]
		if _, exists := versionMap[vr.SchemaID]; !exists {
			versionMap[vr.SchemaID] = &models.SchemaVersion{
				SchemaID: vr.SchemaID,
				Version:  vr.Version,
				Fields:   vr.Fields,
			}
		}
	}

	for i := range schemas {
		schema := &schemas[i]
		fields := make([]*models.ItemTypeField, len(schema.Fields))
		for j := range schema.Fields {
			fields[j] = &schema.Fields[j]
		}

		var versionHash string
		var activeVersion *models.SchemaVersion
		if v, exists := versionMap[schema.ID]; exists {
			activeVersion = v
			versionHash = generateVersionHash(activeVersion)
		}

		var uniqueFields []string
		if schema.UniqueFields != "" {
			json.Unmarshal([]byte(schema.UniqueFields), &uniqueFields)
		}

		r.schemas[schema.Name] = &CachedSchema{
			Schema:       schema,
			Fields:       fields,
			Version:      activeVersion,
			VersionHash:  versionHash,
			UniqueFields: uniqueFields,
		}
	}

	return nil
}

func (r *SchemaRegistry) GetSchema(name string) (*CachedSchema, bool) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	schema, ok := r.schemas[name]
	return schema, ok
}

func (r *SchemaRegistry) GetAllSchemas() []*CachedSchema {
	r.mu.RLock()
	defer r.mu.RUnlock()

	result := make([]*CachedSchema, 0, len(r.schemas))
	for _, schema := range r.schemas {
		result = append(result, schema)
	}
	return result
}

func (r *SchemaRegistry) GetAllSchemasIncludingInactive() ([]models.ItemTypeSchema, error) {
	var schemas []models.ItemTypeSchema
	if err := utils.DB.Order("name ASC").Find(&schemas).Error; err != nil {
		return nil, fmt.Errorf("failed to load schemas: %w", err)
	}
	return schemas, nil
}

func (r *SchemaRegistry) InvalidateSchema(name string) {
	r.mu.Lock()
	defer r.mu.Unlock()
	delete(r.schemas, name)
}

func (r *SchemaRegistry) RefreshSchema(name string) error {
	r.mu.Lock()
	defer r.mu.Unlock()

	var schema models.ItemTypeSchema
	if err := utils.DB.Preload("Fields", func(db *gorm.DB) *gorm.DB {
		return db.Order("`order` ASC")
	}).Where("name = ? AND is_active = ?", name, true).First(&schema).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			delete(r.schemas, name)
			return nil
		}
		return fmt.Errorf("failed to refresh schema %s: %w", name, err)
	}

	fields := make([]*models.ItemTypeField, len(schema.Fields))
	for j := range schema.Fields {
		fields[j] = &schema.Fields[j]
	}

	var activeVersion *models.SchemaVersion
	var versionHash string
	err := utils.DB.Where("schema_id = ? AND is_active = 1", schema.ID).Order("version DESC").Limit(1).First(activeVersion).Error
	if err == nil {
		versionHash = generateVersionHash(activeVersion)
	}

	var uniqueFields []string
	if schema.UniqueFields != "" {
		json.Unmarshal([]byte(schema.UniqueFields), &uniqueFields)
	}

	r.schemas[name] = &CachedSchema{
		Schema:       &schema,
		Fields:       fields,
		Version:      activeVersion,
		VersionHash:  versionHash,
		UniqueFields: uniqueFields,
	}

	return nil
}

func (r *SchemaRegistry) SchemaExists(name string) bool {
	r.mu.RLock()
	defer r.mu.RUnlock()
	_, ok := r.schemas[name]
	return ok
}

func (r *SchemaRegistry) GetFieldByKey(schemaName, fieldKey string) (*models.ItemTypeField, bool) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	cached, ok := r.schemas[schemaName]
	if !ok {
		return nil, false
	}

	for _, field := range cached.Fields {
		if field.Key == fieldKey {
			return field, true
		}
	}

	return nil, false
}

func generateVersionHash(version *models.SchemaVersion) string {
	if version == nil {
		return ""
	}
	hashData := fmt.Sprintf("%d-%d-%s", version.SchemaID, version.Version, version.Fields)
	return fmt.Sprintf("%x", hashData)
}

func ParseFieldOptions(field *models.ItemTypeField) ([]string, error) {
	if field.Options == nil || *field.Options == "" {
		return []string{}, nil
	}

	var options []string
	if err := json.Unmarshal([]byte(*field.Options), &options); err != nil {
		return nil, fmt.Errorf("failed to parse options for field %s: %w", field.Key, err)
	}
	return options, nil
}

func ParseFieldValidation(field *models.ItemTypeField) (map[string]interface{}, error) {
	if field.Validation == nil || *field.Validation == "" {
		return map[string]interface{}{}, nil
	}

	var validation map[string]interface{}
	if err := json.Unmarshal([]byte(*field.Validation), &validation); err != nil {
		return nil, fmt.Errorf("failed to parse validation for field %s: %w", field.Key, err)
	}
	return validation, nil
}

func ParseFieldDisplay(field *models.ItemTypeField) (map[string]interface{}, error) {
	if field.Display == nil || *field.Display == "" {
		return map[string]interface{}{}, nil
	}

	var display map[string]interface{}
	if err := json.Unmarshal([]byte(*field.Display), &display); err != nil {
		return nil, fmt.Errorf("failed to parse display for field %s: %w", field.Key, err)
	}
	return display, nil
}
