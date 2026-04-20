export type SchemaFieldType = 'text' | 'textarea' | 'number' | 'select' | 'checkbox' | 'enum';

export interface ValidationRule {
  type: 'required' | 'minLength' | 'maxLength' | 'min' | 'max' | 'pattern' | 'options';
  value?: string | number | boolean | string[];
  message?: string;
}

export interface DisplayHint {
  columnWidth?: 'small' | 'medium' | 'large';
  showInTable?: boolean;
  sortable?: boolean;
  primary?: boolean;
  group?: string;
}

export interface SchemaField {
  id: number;
  schema_id: number;
  key: string;
  label: string;
  field_type: SchemaFieldType;
  required: boolean;
  order: number;
  group?: string;
  validation?: ValidationRule[];
  display?: DisplayHint;
  options?: { value: string; label: string }[];
  created_at: string;
  updated_at: string;
}

export interface SchemaVersion {
  id: number;
  schema_id: number;
  version: number;
  fields: SchemaField[];
  is_active: boolean;
  migrated_at?: string;
  created_at: string;
}

export interface ItemTypeSchema {
  id?: number;
  name: string;
  display_name: string;
  plural_name: string;
  icon: string;
  color: string;
  is_active?: boolean;
  unique_fields?: string[];
  item_count?: number;
  created_at?: string;
  updated_at?: string;
  deleted_at?: string;
  fields?: SchemaField[];
  versions?: SchemaVersion[];
}

export interface CreateSchemaRequest {
  name: string;
  display_name: string;
  plural_name: string;
  icon: string;
  color: string;
  is_active?: boolean;
  unique_fields?: string[];
  fields: Omit<SchemaField, 'id' | 'schema_id' | 'created_at' | 'updated_at'>[];
}

export interface UpdateSchemaRequest {
  display_name?: string;
  plural_name?: string;
  icon?: string;
  color?: string;
  is_active?: boolean;
  unique_fields?: string[];
  fields?: Omit<SchemaField, 'id' | 'schema_id' | 'created_at' | 'updated_at'>[];
}

export interface SchemaListResponse {
  schemas: ItemTypeSchema[];
  total?: number;
}

export interface SchemaDetailResponse {
  name: string;
  display_name: string;
  plural_name: string;
  icon: string;
  color: string;
  is_active?: boolean;
  item_count?: number;
  version?: number;
  version_hash?: string;
  fields: SchemaField[];
  versions?: SchemaVersion[];
  current_version?: SchemaVersion;
}