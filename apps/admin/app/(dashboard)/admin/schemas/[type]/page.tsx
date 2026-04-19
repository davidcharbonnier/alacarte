'use client';

import { use } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import Link from 'next/link';
import { schemaApi } from '@/lib/api/schema-api';
import type {
  ItemTypeSchema,
  SchemaField,
  UpdateSchemaRequest,
} from '@/lib/types/schema';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { LoadingSpinner } from '@/components/shared/loading-spinner';
import { ErrorMessage } from '@/components/shared/error-message';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { ArrowLeft, Save, Eye, EyeOff, History, Plus, Trash2, GripVertical } from 'lucide-react';
import { useState } from 'react';
import * as Icons from 'lucide-react';
import { useForm, useFieldArray } from 'react-hook-form';

type SchemaEditorFormData = {
  display_name: string;
  plural_name: string;
  icon: string;
  color: string;
  is_active: boolean;
  unique_fields: string[];
  fields: FieldFormData[];
};

type FieldFormData = {
  id?: number;
  key: string;
  label: string;
  field_type: 'text' | 'textarea' | 'number' | 'select' | 'checkbox' | 'enum';
  required: boolean;
  order: number;
  group?: string;
  options?: { value: string; label: string }[];
  validation?: {
    type: 'required' | 'minLength' | 'maxLength' | 'min' | 'max' | 'pattern' | 'options';
    value?: string | number | boolean | string[];
    message?: string;
  }[];
  display?: {
    columnWidth?: 'small' | 'medium' | 'large';
    showInTable?: boolean;
    sortable?: boolean;
    primary?: boolean;
    group?: string;
  };
};

const FIELD_TYPES = [
  { value: 'text', label: 'Text' },
  { value: 'textarea', label: 'Textarea' },
  { value: 'number', label: 'Number' },
  { value: 'select', label: 'Select' },
  { value: 'checkbox', label: 'Checkbox' },
  { value: 'enum', label: 'Enum' },
];

const ICON_OPTIONS = [
  { value: 'Pizza', label: 'Pizza (Cheese)' },
  { value: 'Wine', label: 'Wine' },
  { value: 'Coffee', label: 'Coffee' },
  { value: 'Flame', label: 'Flame (Hot Sauce)' },
  { value: 'Beer', label: 'Beer' },
  { value: 'Apple', label: 'Apple' },
  { value: 'Cake', label: 'Cake' },
  { value: 'Cookie', label: 'Cookie' },
  { value: 'Cup', label: 'Cup (Tea)' },
  { value: 'Fish', label: 'Fish' },
  { value: 'Salad', label: 'Salad' },
  { value: 'IceCream', label: 'Ice Cream' },
];

const COLOR_OPTIONS = [
  { value: '#E67E22', label: 'Orange' },
  { value: '#9B59B6', label: 'Purple' },
  { value: '#E74C3C', label: 'Red' },
  { value: '#3498DB', label: 'Blue' },
  { value: '#1ABC9C', label: 'Teal' },
  { value: '#27AE60', label: 'Green' },
  { value: '#F39C12', label: 'Yellow' },
  { value: '#2C3E50', label: 'Dark' },
];

export default function SchemaEditorPage({
  params,
}: {
  params: Promise<{ type: string }>;
}) {
  const { type } = use(params);
  const queryClient = useQueryClient();
  const [activeTab, setActiveTab] = useState('fields');

  const { data, isLoading, error } = useQuery({
    queryKey: ['schemas', type],
    queryFn: () => schemaApi.get(type),
  });

  // TODO: Fix caching issue - after schema update, the query data is not properly refreshed.
  // The schema edit page shows stale data even after invalidation, while other pages update correctly.
  // This may be related to React Query's stale-while-revalidate behavior or a race condition.
  const updateMutation = useMutation({
    mutationFn: (updateData: UpdateSchemaRequest) =>
      schemaApi.update(type, updateData),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['schemas'] });
      queryClient.invalidateQueries({ queryKey: ['schemas', type] });
    },
  });

  if (isLoading) {
    return <LoadingSpinner text="Loading schema..." />;
  }

  if (error || !data) {
    return (
      <ErrorMessage
        error={(error as Error) || new Error('Schema not found')}
      />
    );
  }

  const { schema, fields } = data;

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-start">
        <div className="flex items-center gap-4">
          <Link href="/admin/schemas">
            <Button variant="ghost" size="icon">
              <ArrowLeft className="w-4 h-4" />
            </Button>
          </Link>
          <div>
            <div className="flex items-center gap-3 mb-1">
              <div
                className="flex items-center justify-center w-10 h-10 rounded-lg"
                style={{ backgroundColor: `${schema.color}20` }}
              >
                {(() => {
                  const IconComponent =
                    (Icons as any)[schema.icon] || Icons.HelpCircle;
                  return (
                    <IconComponent
                      className="w-5 h-5"
                      style={{ color: schema.color }}
                    />
                  );
                })()}
              </div>
              <h1 className="text-2xl font-bold">{schema.display_name}</h1>
              {schema.is_active ? (
                <Badge className="bg-green-100 text-green-800">Active</Badge>
              ) : (
                <Badge variant="outline">Inactive</Badge>
              )}
            </div>
            <p className="text-muted-foreground">
              Schema editor for {schema.plural_name}
            </p>
          </div>
        </div>

        <div className="flex items-center gap-2">
          <Button
            variant="outline"
            onClick={() => {
              if (schema.is_active) {
                const message = schema.item_count && schema.item_count > 0
                  ? `This schema has ${schema.item_count} ${schema.item_count === 1 ? 'item' : 'items'}. Deactivating will make all items inaccessible through the API, but they won't be deleted. You can reactivate the schema later to restore access.`
                  : `This will deactivate the schema. All items will become inaccessible through the API. You can reactivate the schema later.`;
                if (window.confirm(message)) {
                  updateMutation.mutate({ is_active: false });
                }
              } else {
                updateMutation.mutate({ is_active: true });
              }
            }}
            disabled={updateMutation.isPending}
          >
            {schema.is_active ? (
              <>
                <EyeOff className="w-4 h-4 mr-2" />
                Deactivate
              </>
            ) : (
              <>
                <Eye className="w-4 h-4 mr-2" />
                Activate
              </>
            )}
          </Button>
        </div>
      </div>

      <Tabs value={activeTab} onValueChange={setActiveTab}>
        <TabsList>
          <TabsTrigger value="fields">Fields</TabsTrigger>
          <TabsTrigger value="settings">Settings</TabsTrigger>
          <TabsTrigger value="versions">Version History</TabsTrigger>
        </TabsList>

        <TabsContent value="fields" className="mt-4">
          <SchemaBuilder
            fields={fields}
            onSave={(fieldsData) => {
              updateMutation.mutate({ fields: fieldsData });
            }}
            isSaving={updateMutation.isPending}
          />
        </TabsContent>

        <TabsContent value="settings" className="mt-4">
          <SchemaSettings
            schema={schema}
            fields={fields}
            onSave={(settings) => {
              updateMutation.mutate(settings);
            }}
            isSaving={updateMutation.isPending}
          />
        </TabsContent>

        <TabsContent value="versions" className="mt-4">
          <SchemaVersionHistory schemaType={type} />
        </TabsContent>
      </Tabs>
    </div>
  );
}

function SchemaSettings({
  schema,
  fields,
  onSave,
  isSaving,
}: {
  schema: ItemTypeSchema;
  fields: SchemaField[];
  onSave: (settings: UpdateSchemaRequest) => void;
  isSaving: boolean;
}) {
  const { register, handleSubmit, watch, setValue } = useForm<SchemaEditorFormData>({
    defaultValues: {
      display_name: schema.display_name,
      plural_name: schema.plural_name,
      icon: schema.icon,
      color: schema.color,
      is_active: schema.is_active,
      unique_fields: schema.unique_fields || [],
    },
  });

  const selectedUniqueFields = watch('unique_fields') || [];

  const toggleUniqueField = (fieldKey: string) => {
    const current = selectedUniqueFields;
    if (current.includes(fieldKey)) {
      setValue('unique_fields', current.filter((k) => k !== fieldKey));
    } else {
      setValue('unique_fields', [...current, fieldKey]);
    }
  };

  const selectedIcon = watch('icon');
  const selectedColor = watch('color');

  return (
    <Card>
      <CardHeader>
        <CardTitle>Schema Settings</CardTitle>
        <CardDescription>
          Configure basic information for this schema
        </CardDescription>
      </CardHeader>
      <CardContent>
        <form onSubmit={handleSubmit(onSave)} className="space-y-6">
          <div className="grid grid-cols-2 gap-4">
            <div className="space-y-2">
              <Label htmlFor="display_name">Display Name</Label>
              <Input id="display_name" {...register('display_name')} />
            </div>
            <div className="space-y-2">
              <Label htmlFor="plural_name">Plural Name</Label>
              <Input id="plural_name" {...register('plural_name')} />
            </div>
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div className="space-y-2">
              <Label>Icon</Label>
              <Select
                value={selectedIcon}
                onValueChange={(value) => setValue('icon', value)}
              >
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  {ICON_OPTIONS.map((opt) => (
                    <SelectItem key={opt.value} value={opt.value}>
                      {opt.label}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
            <div className="space-y-2">
              <Label>Color</Label>
              <Select
                value={selectedColor}
                onValueChange={(value) => setValue('color', value)}
              >
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  {COLOR_OPTIONS.map((opt) => (
                    <SelectItem key={opt.value} value={opt.value}>
                      <div className="flex items-center gap-2">
                        <div
                          className="w-4 h-4 rounded"
                          style={{ backgroundColor: opt.value }}
                        />
                        {opt.label}
                      </div>
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
          </div>

          <div className="flex items-center gap-4 p-4 bg-muted rounded-lg">
            <div
              className="flex items-center justify-center w-12 h-12 rounded-xl"
              style={{
                backgroundColor: `${selectedColor}20`,
              }}
            >
              {(() => {
                const IconComponent =
                  (Icons as any)[selectedIcon] || Icons.HelpCircle;
                return (
                  <IconComponent
                    className="w-6 h-6"
                    style={{ color: selectedColor }}
                  />
                );
              })()}
            </div>
            <div>
              <p className="font-medium">Preview</p>
              <p className="text-sm text-muted-foreground">
                How your schema will appear in navigation
              </p>
            </div>
          </div>

          <div className="space-y-3">
            <div>
              <Label>Uniqueness Constraint</Label>
              <p className="text-sm text-muted-foreground mb-3">
                Select fields that together define a unique item. Duplicate values in these fields will be rejected.
              </p>
            </div>
            {fields.length === 0 ? (
              <p className="text-sm text-muted-foreground italic">
                No fields defined yet. Add fields in the Fields tab first.
              </p>
            ) : (
              <div className="flex flex-wrap gap-2">
                {fields.map((field) => (
                  <label
                    key={field.key}
                    className={`flex items-center gap-2 px-3 py-2 rounded-lg border cursor-pointer transition-colors ${
                      selectedUniqueFields.includes(field.key)
                        ? 'border-primary bg-primary/10 text-primary'
                        : 'border-input bg-background hover:bg-muted'
                    }`}
                  >
                    <input
                      type="checkbox"
                      checked={selectedUniqueFields.includes(field.key)}
                      onChange={() => toggleUniqueField(field.key)}
                      className="sr-only"
                    />
                    <span className="text-sm font-medium">{field.label}</span>
                    <span className="text-xs text-muted-foreground">
                      ({field.key})
                    </span>
                  </label>
                ))}
              </div>
            )}
            {selectedUniqueFields.length > 0 && (
              <p className="text-sm text-muted-foreground">
                Items with the same{' '}
                {selectedUniqueFields.map((key) => {
                  const field = fields.find((f) => f.key === key);
                  return field?.label || key;
                }).join(', ')}{' '}
                will be considered duplicates.
              </p>
            )}
          </div>

          <Button type="submit" disabled={isSaving}>
            <Save className="w-4 h-4 mr-2" />
            {isSaving ? 'Saving...' : 'Save Settings'}
          </Button>
        </form>
      </CardContent>
    </Card>
  );
}

function SchemaBuilder({
  fields,
  onSave,
  isSaving,
}: {
  fields: SchemaField[];
  onSave: (fields: any[]) => void;
  isSaving: boolean;
}) {
  const { register, handleSubmit, watch, setValue, control } =
    useForm<SchemaEditorFormData>({
      defaultValues: {
        fields: fields.map((f) => ({
          id: f.id,
          key: f.key,
          label: f.label,
          field_type: f.field_type,
          required: f.required,
          order: f.order,
          group: f.group,
          options: f.options,
          validation: f.validation,
          display: f.display,
        })),
      },
    });

  const { fields: formFields, append, remove, move } = useFieldArray({
    control,
    name: 'fields',
  });

  const addField = () => {
    append({
      key: '',
      label: '',
      field_type: 'text',
      required: false,
      order: formFields.length,
      options: [],
      validation: [],
      display: { showInTable: true, sortable: true },
    });
  };

  const onSubmit = (data: SchemaEditorFormData) => {
    const fieldsData = data.fields.map((f, index) => ({
      ...f,
      order: index,
    }));
    onSave(fieldsData);
  };

  return (
    <Card>
      <CardHeader>
        <div className="flex justify-between items-center">
          <div>
            <CardTitle>Schema Fields</CardTitle>
            <CardDescription>
              Define the fields that make up this item type
            </CardDescription>
          </div>
          <Button type="button" onClick={addField}>
            <Plus className="w-4 h-4 mr-2" />
            Add Field
          </Button>
        </div>
      </CardHeader>
      <CardContent>
        <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
          {formFields.length === 0 ? (
            <div className="text-center py-12 border-2 border-dashed rounded-lg">
              <p className="text-muted-foreground mb-2">
                No fields defined yet
              </p>
              <Button type="button" variant="outline" onClick={addField}>
                <Plus className="w-4 h-4 mr-2" />
                Add your first field
              </Button>
            </div>
          ) : (
            <div className="space-y-4">
              {formFields.map((_field, index) => (
                <FieldEditor
                  key={_field.id}
                  index={index}
                  register={register}
                  watch={watch}
                  setValue={setValue}
                  onRemove={() => remove(index)}
                  onMove={(direction: 'up' | 'down') => {
                    const newIndex =
                      direction === 'up' ? index - 1 : index + 1;
                    if (newIndex >= 0 && newIndex < formFields.length) {
                      move(index, newIndex);
                    }
                  }}
                  canMoveUp={index > 0}
                  canMoveDown={index < formFields.length - 1}
                />
              ))}
            </div>
          )}

          {formFields.length > 0 && (
            <div className="flex justify-end">
              <Button type="submit" disabled={isSaving}>
                <Save className="w-4 h-4 mr-2" />
                {isSaving ? 'Saving...' : 'Save Fields'}
              </Button>
            </div>
          )}
        </form>
      </CardContent>
    </Card>
  );
}

function FieldEditor({
  index,
  register,
  watch,
  setValue,
  onRemove,
  onMove,
  canMoveUp,
  canMoveDown,
}: {
  field?: any;
  index: number;
  register: any;
  watch: any;
  setValue: any;
  onRemove: () => void;
  onMove: (direction: 'up' | 'down') => void;
  canMoveUp: boolean;
  canMoveDown: boolean;
}) {
  const [isExpanded, setIsExpanded] = useState(true);
  const fieldType = watch(`fields.${index}.field_type`);
  const options = watch(`fields.${index}.options`) || [];
  const validation = watch(`fields.${index}.validation`) || [];
  const display = watch(`fields.${index}.display`) || {};

  const showOptions = fieldType === 'select' || fieldType === 'enum';
  const showValidation =
    fieldType === 'text' || fieldType === 'textarea' || fieldType === 'number';

  return (
    <div className="border rounded-lg overflow-hidden">
      <div
        className="flex items-center justify-between p-4 bg-muted/50 cursor-pointer"
        onClick={() => setIsExpanded(!isExpanded)}
      >
        <div className="flex items-center gap-3">
          <button
            type="button"
            className="cursor-grab active:cursor-grabbing"
            onClick={(e) => e.stopPropagation()}
          >
            <GripVertical className="w-4 h-4 text-muted-foreground" />
          </button>
          <div className="flex items-center gap-2">
            <span className="text-sm font-medium">{index + 1}.</span>
            <Badge variant="secondary">{fieldType}</Badge>
            <span className="font-medium">
              {watch(`fields.${index}.label`) || 'Untitled Field'}
            </span>
            {watch(`fields.${index}.required`) && (
              <span className="text-destructive text-sm">*</span>
            )}
          </div>
        </div>
        <div className="flex items-center gap-2" onClick={(e) => e.stopPropagation()}>
          <Button
            type="button"
            variant="ghost"
            size="icon"
            onClick={() => onMove('up')}
            disabled={!canMoveUp}
          >
            ↑
          </Button>
          <Button
            type="button"
            variant="ghost"
            size="icon"
            onClick={() => onMove('down')}
            disabled={!canMoveDown}
          >
            ↓
          </Button>
          <Button
            type="button"
            variant="ghost"
            size="icon"
            onClick={onRemove}
            className="text-destructive hover:text-destructive"
          >
            <Trash2 className="w-4 h-4" />
          </Button>
        </div>
      </div>

      {isExpanded && (
        <div className="p-4 space-y-4 border-t">
          <div className="grid grid-cols-2 gap-4">
            <div className="space-y-2">
              <Label htmlFor={`fields.${index}.key`}>Field Key</Label>
              <Input
                id={`fields.${index}.key`}
                placeholder="e.g., name, description"
                {...register(`fields.${index}.key`, { required: true })}
              />
              <p className="text-xs text-muted-foreground">
                Unique identifier (lowercase, no spaces)
              </p>
            </div>
            <div className="space-y-2">
              <Label htmlFor={`fields.${index}.label`}>Display Label</Label>
              <Input
                id={`fields.${index}.label`}
                placeholder="e.g., Name, Description"
                {...register(`fields.${index}.label`, { required: true })}
              />
            </div>
          </div>

          <div className="grid grid-cols-3 gap-4">
            <div className="space-y-2">
              <Label>Field Type</Label>
              <Select
                value={fieldType}
                onValueChange={(value) =>
                  setValue(`fields.${index}.field_type`, value)
                }
              >
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  {FIELD_TYPES.map((type) => (
                    <SelectItem key={type.value} value={type.value}>
                      {type.label}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
            <div className="space-y-2">
              <Label htmlFor={`fields.${index}.group`}>Group</Label>
              <Input
                id={`fields.${index}.group`}
                placeholder="e.g., Basic Info"
                {...register(`fields.${index}.group`)}
              />
            </div>
            <div className="flex items-end pb-1">
              <label className="flex items-center gap-2 cursor-pointer">
                <input
                  type="checkbox"
                  {...register(`fields.${index}.required`)}
                />
                <span className="text-sm">Required field</span>
              </label>
            </div>
          </div>

          {showOptions && (
            <OptionsEditor
              options={options}
              onChange={(newOptions) =>
                setValue(`fields.${index}.options`, newOptions)
              }
            />
          )}

          {showValidation && (
            <ValidationEditor
              validation={validation}
              fieldType={fieldType}
              onChange={(newValidation) =>
                setValue(`fields.${index}.validation`, newValidation)
              }
            />
          )}

          <DisplayConfigurator
            display={display}
            onChange={(newDisplay) =>
              setValue(`fields.${index}.display`, newDisplay)
            }
          />
        </div>
      )}
    </div>
  );
}

function OptionsEditor({
  options,
  onChange,
}: {
  options: { value: string; label: string }[];
  onChange: (options: { value: string; label: string }[]) => void;
}) {
  const addOption = () => {
    onChange([...options, { value: '', label: '' }]);
  };

  const updateOption = (index: number, field: 'value' | 'label', value: string) => {
    const newOptions = [...options];
    newOptions[index] = { ...newOptions[index], [field]: value };
    onChange(newOptions);
  };

  const removeOption = (index: number) => {
    onChange(options.filter((_, i) => i !== index));
  };

  return (
    <div className="space-y-2">
      <div className="flex justify-between items-center">
        <Label>Options</Label>
        <Button type="button" variant="ghost" size="sm" onClick={addOption}>
          <Plus className="w-4 h-4 mr-1" />
          Add Option
        </Button>
      </div>
      <div className="space-y-2">
        {options.map((option, index) => (
          <div key={index} className="flex gap-2">
            <Input
              placeholder="Value"
              value={option.value}
              onChange={(e) => updateOption(index, 'value', e.target.value)}
              className="flex-1"
            />
            <Input
              placeholder="Label"
              value={option.label}
              onChange={(e) => updateOption(index, 'label', e.target.value)}
              className="flex-1"
            />
            <Button
              type="button"
              variant="ghost"
              size="icon"
              onClick={() => removeOption(index)}
              className="text-destructive"
            >
              <Trash2 className="w-4 h-4" />
            </Button>
          </div>
        ))}
      </div>
    </div>
  );
}

function ValidationEditor({
  validation,
  fieldType,
  onChange,
}: {
  validation: any[];
  fieldType: string;
  onChange: (validation: any[]) => void;
}) {
  const validationTypes =
    fieldType === 'number'
      ? [
          { value: 'required', label: 'Required' },
          { value: 'min', label: 'Minimum Value' },
          { value: 'max', label: 'Maximum Value' },
        ]
      : [
          { value: 'required', label: 'Required' },
          { value: 'minLength', label: 'Minimum Length' },
          { value: 'maxLength', label: 'Maximum Length' },
          { value: 'pattern', label: 'Pattern (Regex)' },
        ];

  const addValidation = (type: string) => {
    const newValidation = [...validation, { type, value: '', message: '' }];
    onChange(newValidation);
  };

  const updateValidation = (
    index: number,
    field: 'value' | 'message',
    value: any
  ) => {
    const newValidation = [...validation];
    newValidation[index] = { ...newValidation[index], [field]: value };
    onChange(newValidation);
  };

  const removeValidation = (index: number) => {
    onChange(validation.filter((_, i) => i !== index));
  };

  return (
    <div className="space-y-2">
      <div className="flex justify-between items-center">
        <Label>Validation Rules</Label>
        <Select onValueChange={addValidation}>
          <SelectTrigger className="w-[200px]">
            <SelectValue placeholder="Add validation..." />
          </SelectTrigger>
          <SelectContent>
            {validationTypes.map((type) => (
              <SelectItem key={type.value} value={type.value}>
                {type.label}
              </SelectItem>
            ))}
          </SelectContent>
        </Select>
      </div>
      <div className="space-y-2">
        {validation.map((rule, index) => (
          <div key={index} className="flex gap-2 items-center">
            <Badge variant="secondary" className="w-24 justify-center">
              {rule.type}
            </Badge>
            {rule.type !== 'required' && (
              <Input
                placeholder={
                  rule.type === 'pattern' ? 'e.g., ^[a-z]+$' : 'Value'
                }
                value={rule.value || ''}
                onChange={(e) =>
                  updateValidation(
                    index,
                    'value',
                    rule.type === 'min' || rule.type === 'max'
                      ? Number(e.target.value)
                      : e.target.value
                  )
                }
                className="flex-1"
                type={rule.type === 'min' || rule.type === 'max' ? 'number' : 'text'}
              />
            )}
            <Input
              placeholder="Error message"
              value={rule.message || ''}
              onChange={(e) =>
                updateValidation(index, 'message', e.target.value)
              }
              className="flex-1"
            />
            <Button
              type="button"
              variant="ghost"
              size="icon"
              onClick={() => removeValidation(index)}
              className="text-destructive"
            >
              <Trash2 className="w-4 h-4" />
            </Button>
          </div>
        ))}
      </div>
    </div>
  );
}

function DisplayConfigurator({
  display,
  onChange,
}: {
  display: any;
  onChange: (display: any) => void;
}) {
  return (
    <div className="space-y-2">
      <Label>Display Settings</Label>
      <div className="flex flex-wrap gap-4">
        <label className="flex items-center gap-2 cursor-pointer">
          <input
            type="checkbox"
            checked={display.showInTable ?? true}
            onChange={(e) =>
              onChange({ ...display, showInTable: e.target.checked })
            }
          />
          <span className="text-sm">Show in table</span>
        </label>
        <label className="flex items-center gap-2 cursor-pointer">
          <input
            type="checkbox"
            checked={display.sortable ?? true}
            onChange={(e) =>
              onChange({ ...display, sortable: e.target.checked })
            }
          />
          <span className="text-sm">Sortable</span>
        </label>
        <label className="flex items-center gap-2 cursor-pointer">
          <input
            type="checkbox"
            checked={display.primary ?? false}
            onChange={(e) =>
              onChange({ ...display, primary: e.target.checked })
            }
          />
          <span className="text-sm">Primary field</span>
        </label>
        <div className="flex items-center gap-2">
          <span className="text-sm">Width:</span>
          <Select
            value={display.columnWidth || 'medium'}
            onValueChange={(value) =>
              onChange({ ...display, columnWidth: value })
            }
          >
            <SelectTrigger className="w-24">
              <SelectValue />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="small">Small</SelectItem>
              <SelectItem value="medium">Medium</SelectItem>
              <SelectItem value="large">Large</SelectItem>
            </SelectContent>
          </Select>
        </div>
      </div>
    </div>
  );
}

function SchemaVersionHistory({ schemaType }: { schemaType: string }) {
  const { data: schemaData, isLoading } = useQuery({
    queryKey: ['schemas', schemaType],
    queryFn: () => schemaApi.get(schemaType),
  });

  if (isLoading) {
    return <LoadingSpinner text="Loading versions..." />;
  }

  const versions = schemaData?.schema.versions || [];

  return (
    <Card>
      <CardHeader>
        <CardTitle className="flex items-center gap-2">
          <History className="w-5 h-5" />
          Version History
        </CardTitle>
        <CardDescription>
          View previous versions of this schema
        </CardDescription>
      </CardHeader>
      <CardContent>
        {versions.length === 0 ? (
          <div className="text-center py-8 text-muted-foreground">
            <p>No version history available</p>
            <p className="text-sm">Versions are created when you save changes</p>
          </div>
        ) : (
          <div className="space-y-4">
            {versions.map((version: any) => (
              <div
                key={version.id}
                className={`p-4 border rounded-lg ${
                  version.is_active
                    ? 'border-green-500 bg-green-50 dark:bg-green-950/20'
                    : ''
                }`}
              >
                <div className="flex justify-between items-start">
                  <div>
                    <div className="flex items-center gap-2">
                      <span className="font-medium">
                        Version {version.version}
                      </span>
                      {version.is_active && (
                        <Badge className="bg-green-100 text-green-800">
                          Active
                        </Badge>
                      )}
                    </div>
                    <p className="text-sm text-muted-foreground mt-1">
                      {version.fields?.length || 0} fields
                    </p>
                    {version.migrated_at && (
                      <p className="text-xs text-muted-foreground mt-1">
                        Migrated: {new Date(version.migrated_at).toLocaleString()}
                      </p>
                    )}
                    <p className="text-xs text-muted-foreground">
                      Created: {new Date(version.created_at).toLocaleString()}
                    </p>
                  </div>
                </div>
              </div>
            ))}
          </div>
        )}
      </CardContent>
    </Card>
  );
}
