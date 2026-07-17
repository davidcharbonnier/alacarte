import { useEffect, useState } from 'react';
import {
  Alert,
  Box,
  Button,
  Card,
  CardContent,
  Checkbox,
  Chip,
  FormControlLabel,
  IconButton,
  MenuItem,
  Snackbar,
  Stack,
  Tab,
  Tabs,
  TextField,
  Typography,
} from '@mui/material';
import ArrowBack from '@mui/icons-material/ArrowBack';
import Save from '@mui/icons-material/Save';
import Visibility from '@mui/icons-material/Visibility';
import VisibilityOff from '@mui/icons-material/VisibilityOff';
import History from '@mui/icons-material/History';
import Add from '@mui/icons-material/Add';
import Delete from '@mui/icons-material/Delete';
import KeyboardArrowUp from '@mui/icons-material/KeyboardArrowUp';
import KeyboardArrowDown from '@mui/icons-material/KeyboardArrowDown';
import AddCircle from '@mui/icons-material/AddCircle';
import RemoveCircle from '@mui/icons-material/RemoveCircle';
import Edit from '@mui/icons-material/Edit';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { Link } from '@tanstack/react-router';
import { schemaApi } from '../lib/api/schema-api';
import type { SchemaField, SchemaVersion, UpdateSchemaRequest, ItemTypeSchema } from '../lib/types/schema';
import { ICON_OPTIONS, resolveIcon } from '../lib/icons/icon-registry';

const COLOR_OPTIONS = [
  { value: '#E67E22', label: 'Orange' },
  { value: '#9B59B6', label: 'Purple' },
  { value: '#E74C3C', label: 'Red' },
  { value: '#3498DB', label: 'Blue' },
  { value: '#1ABC9C', label: 'Teal' },
  { value: '#27AE60', label: 'Green' },
  { value: '#F39C12', label: 'Yellow' },
  { value: '#2C3E50', label: 'Dark' },
  { value: '#16A085', label: 'Dark Teal' },
  { value: '#D35400', label: 'Dark Orange' },
  { value: '#7F8C8D', label: 'Gray' },
  { value: '#C0392B', label: 'Dark Red' },
  { value: '#2980B9', label: 'Dark Blue' },
  { value: '#8E44AD', label: 'Dark Purple' },
  { value: '#27AE60', label: 'Forest Green' },
  { value: '#F1C40F', label: 'Bright Yellow' },
  { value: '#673AB7', label: 'Deep Purple' },
  { value: '#009688', label: 'Teal' },
  { value: '#795548', label: 'Brown' },
  { value: '#F44336', label: 'Red' },
  { value: '#FF5722', label: 'Deep Orange' },
  { value: '#607D8B', label: 'Blue Gray' },
  { value: '#E91E63', label: 'Pink' },
  { value: '#00BCD4', label: 'Cyan' },
];

const FIELD_TYPES = [
  { value: 'text', label: 'Text' },
  { value: 'textarea', label: 'Textarea' },
  { value: 'number', label: 'Number' },
  { value: 'select', label: 'Select' },
  { value: 'checkbox', label: 'Checkbox' },
  { value: 'enum', label: 'Enum' },
];

type EditableField = Omit<SchemaField, 'id' | 'schema_id' | 'created_at' | 'updated_at'>;

export function SchemaEditorPage({ type }: { type: string }) {
  const queryClient = useQueryClient();
  const [tab, setTab] = useState('fields');
  const [saveCount, setSaveCount] = useState(0);
  const [toast, setToast] = useState<{ open: boolean; message: string; severity: 'success' | 'info' }>({
    open: false,
    message: '',
    severity: 'success',
  });

  const { data, isLoading, error } = useQuery({
    queryKey: ['schemas', type],
    queryFn: () => schemaApi.get(type),
  });

  const updateMutation = useMutation({
    mutationFn: (payload: UpdateSchemaRequest) => schemaApi.update(type, payload),
    onSuccess: (response) => {
      queryClient.setQueryData(['schemas', type], { schema: response.schema, fields: response.schema.fields || [] });
      queryClient.invalidateQueries({ queryKey: ['schemas'], exact: true });
      queryClient.invalidateQueries({ queryKey: ['schemas', 'all'], exact: true });
      setToast({
        open: true,
        severity: response.updated ? 'success' : 'info',
        message: response.message,
      });
      if (response.updated) {
        setSaveCount((c) => c + 1);
      }
    },
  });

  if (isLoading) return <Typography color="text.secondary">Loading schema…</Typography>;
  if (error || !data) return <Alert severity="error">Schema not found</Alert>;

  const { schema, fields } = data;

  return (
    <Stack spacing={3}>
      <Stack direction="row" justifyContent="space-between" alignItems="flex-start">
        <Stack direction="row" spacing={2} alignItems="center">
          <Button component={Link} to="/schemas" startIcon={<ArrowBack />}>
            Back
          </Button>
          <Stack direction="row" spacing={1.5} alignItems="center">
            <Box
              sx={{
                width: 40,
                height: 40,
                borderRadius: 1,
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                bgcolor: `${schema.color}20`,
              }}
            >
              {(() => {
                const Icon = resolveIcon(schema.icon);
                return <Icon sx={{ color: schema.color }} />;
              })()}
            </Box>
            <Box>
              <Typography variant="h5">{schema.display_name}</Typography>
              <Typography variant="body2" color="text.secondary">
                Schema editor for {schema.plural_name}
              </Typography>
            </Box>
          </Stack>
        </Stack>
        <Button
          variant="outlined"
          startIcon={schema.is_active ? <VisibilityOff /> : <Visibility />}
          onClick={() => updateMutation.mutate({ is_active: !schema.is_active })}
          disabled={updateMutation.isPending}
        >
          {schema.is_active ? 'Deactivate' : 'Activate'}
        </Button>
      </Stack>

      <Tabs value={tab} onChange={(_, v) => setTab(v)}>
        <Tab label="Fields" value="fields" />
        <Tab label="Settings" value="settings" />
        <Tab label="Version History" value="versions" />
      </Tabs>

      {tab === 'fields' && (
        <SchemaBuilder
          key={`builder-${saveCount}`}
          fields={fields}
          onSave={(fieldsData) => updateMutation.mutate({ fields: fieldsData })}
          isSaving={updateMutation.isPending}
        />
      )}
      {tab === 'settings' && (
        <SchemaSettings
          key={`settings-${saveCount}`}
          schema={schema}
          fields={fields}
          onSave={(settings) => updateMutation.mutate(settings)}
          isSaving={updateMutation.isPending}
        />
      )}
      {tab === 'versions' && <SchemaVersionHistory schemaType={type} />}

      <Snackbar
        open={toast.open}
        autoHideDuration={3000}
        onClose={() => setToast((t) => ({ ...t, open: false }))}
        anchorOrigin={{ vertical: 'bottom', horizontal: 'center' }}
      >
        <Alert
          severity={toast.severity}
          onClose={() => setToast((t) => ({ ...t, open: false }))}
          variant="filled"
          sx={{ width: '100%' }}
        >
          {toast.message}
        </Alert>
      </Snackbar>
    </Stack>
  );
}

function SchemaBuilder({ fields, onSave, isSaving }: { fields: SchemaField[]; onSave: (fields: EditableField[]) => void; isSaving: boolean }) {
  const [list, setList] = useState<EditableField[]>(() => fields.map(toEditable));

  useEffect(() => {
    setList(fields.map(toEditable));
  }, [fields]);

  const add = () => setList((l) => [...l, { key: '', label: '', field_type: 'text', required: false, order: l.length, options: [], validation: [], display: {} }]);
  const remove = (i: number) => setList((l) => l.filter((_, idx) => idx !== i));
  const move = (i: number, dir: -1 | 1) => {
    setList((l) => {
      const next = [...l];
      const j = i + dir;
      if (j < 0 || j >= next.length) return l;
      [next[i], next[j]] = [next[j], next[i]];
      return next;
    });
  };
  const update = (i: number, patch: Partial<EditableField>) =>
    setList((l) => l.map((f, idx) => (idx === i ? { ...f, ...patch } : f)));

  return (
    <Card variant="outlined">
      <CardContent>
        <Stack direction="row" justifyContent="space-between" alignItems="center" sx={{ mb: 2 }}>
          <Box>
            <Typography variant="h6">Schema Fields</Typography>
            <Typography variant="body2" color="text.secondary">
              Define the fields that make up this item type
            </Typography>
          </Box>
          <Button variant="contained" startIcon={<Add />} onClick={add}>
            Add Field
          </Button>
        </Stack>

        {list.length === 0 ? (
          <Box sx={{ textAlign: 'center', py: 6, border: 2, borderStyle: 'dashed', borderRadius: 1 }}>
            <Typography color="text.secondary" sx={{ mb: 1 }}>
              No fields defined yet
            </Typography>
            <Button variant="outlined" startIcon={<Add />} onClick={add}>
              Add your first field
            </Button>
          </Box>
        ) : (
          <Stack spacing={2}>
            {list.map((field, i) => (
              <Card key={i} variant="outlined">
                <CardContent>
                  <Stack direction="row" spacing={1} alignItems="center" sx={{ mb: 1 }}>
                    <Typography variant="bodyMedium" fontWeight={500} noWrap sx={{ flex: 1, minWidth: 0 }}>
                      {field.label || 'Untitled field'}
                    </Typography>
                    <IconButton size="small" disabled={i === 0} onClick={() => move(i, -1)} aria-label="Move up">
                      <KeyboardArrowUp />
                    </IconButton>
                    <IconButton size="small" disabled={i === list.length - 1} onClick={() => move(i, 1)} aria-label="Move down">
                      <KeyboardArrowDown />
                    </IconButton>
                    <IconButton size="small" color="error" onClick={() => remove(i)} aria-label="Delete field">
                      <Delete />
                    </IconButton>
                  </Stack>
                  <Stack spacing={1}>
                    <Stack direction="row" spacing={1}>
                      <TextField
                        fullWidth
                        required
                        size="small"
                        label="Field key"
                        placeholder="e.g., name"
                        value={field.key}
                        onChange={(e) => update(i, { key: e.target.value })}
                      />
                      <TextField
                        fullWidth
                        required
                        size="small"
                        label="Display label"
                        value={field.label}
                        onChange={(e) => update(i, { label: e.target.value })}
                      />
                    </Stack>
                    <Stack direction="row" spacing={1} alignItems="center">
                      <TextField
                        select
                        size="small"
                        label="Type"
                        value={field.field_type}
                        onChange={(e) => update(i, { field_type: e.target.value as EditableField['field_type'] })}
                        sx={{ minWidth: 140 }}
                      >
                        {FIELD_TYPES.map((t) => (
                          <MenuItem key={t.value} value={t.value}>
                            {t.label}
                          </MenuItem>
                        ))}
                      </TextField>
                      <TextField
                        size="small"
                        label="Group"
                        value={field.group ?? ''}
                        onChange={(e) => update(i, { group: e.target.value })}
                      />
                      <FormControlLabel
                        control={
                          <Checkbox
                            checked={field.required}
                            onChange={(e) => update(i, { required: e.target.checked })}
                          />
                        }
                        label="Required"
                      />
                    </Stack>
                  </Stack>
                </CardContent>
              </Card>
            ))}
            <Button
              variant="contained"
              startIcon={<Save />}
              onClick={() => onSave(list.map((f, idx) => ({ ...f, order: idx })))}
              disabled={isSaving}
              sx={{ alignSelf: 'flex-end' }}
            >
              Save fields
            </Button>
          </Stack>
        )}
      </CardContent>
    </Card>
  );
}

function SchemaSettings({ schema, fields, onSave, isSaving }: { schema: ItemTypeSchema; fields: SchemaField[]; onSave: (s: UpdateSchemaRequest) => void; isSaving: boolean }) {
  const [displayName, setDisplayName] = useState(schema.display_name);
  const [pluralName, setPluralName] = useState(schema.plural_name);
  const [icon, setIcon] = useState(schema.icon);
  const [color, setColor] = useState(schema.color);
  const [uniqueFields, setUniqueFields] = useState<string[]>(schema.unique_fields || []);

  useEffect(() => {
    setDisplayName(schema.display_name);
    setPluralName(schema.plural_name);
    setIcon(schema.icon);
    setColor(schema.color);
    setUniqueFields(schema.unique_fields || []);
  }, [schema]);

  const toggleUnique = (k: string) =>
    setUniqueFields((u) => (u.includes(k) ? u.filter((x) => x !== k) : [...u, k]));

  return (
    <Card variant="outlined">
      <CardContent>
        <Typography variant="h6" sx={{ mb: 2 }}>
          Schema Settings
        </Typography>
        <Stack spacing={2} component="form" onSubmit={(e) => { e.preventDefault(); onSave({ display_name: displayName, plural_name: pluralName, icon, color, unique_fields: uniqueFields }); }}>
          <Stack direction="row" spacing={2}>
            <TextField fullWidth label="Display Name" value={displayName} onChange={(e) => setDisplayName(e.target.value)} />
            <TextField fullWidth label="Plural Name" value={pluralName} onChange={(e) => setPluralName(e.target.value)} />
          </Stack>
          <Stack direction="row" spacing={2}>
            <TextField select fullWidth label="Icon" value={icon} onChange={(e) => setIcon(e.target.value)}>
              {ICON_OPTIONS.map((o) => (
                <MenuItem key={o.name} value={o.name}>
                  {o.label}
                </MenuItem>
              ))}
            </TextField>
            <TextField select fullWidth label="Color" value={color} onChange={(e) => setColor(e.target.value)}>
              {COLOR_OPTIONS.map((o) => (
                <MenuItem key={o.value} value={o.value}>
                  <Stack direction="row" spacing={1} alignItems="center">
                    <Box sx={{ width: 16, height: 16, borderRadius: 0.5, bgcolor: o.value }} />
                    <span>{o.label}</span>
                  </Stack>
                </MenuItem>
              ))}
            </TextField>
          </Stack>
          <Stack direction="row" spacing={1.5} alignItems="center" sx={{ p: 2, bgcolor: 'action.hover', borderRadius: 1 }}>
            <Box
              sx={{
                width: 48,
                height: 48,
                borderRadius: 2,
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                bgcolor: `${color}20`,
              }}
            >
              {(() => {
                const PreviewIcon = resolveIcon(icon);
                return <PreviewIcon sx={{ color }} />;
              })()}
            </Box>
            <Box>
              <Typography fontWeight={500}>Preview</Typography>
              <Typography variant="body2" color="text.secondary">
                How your schema will appear in navigation
              </Typography>
            </Box>
          </Stack>
          <Box>
            <Typography variant="subtitle1">Uniqueness Constraint</Typography>
            <Typography variant="body2" color="text.secondary" sx={{ mb: 1 }}>
              Select fields that together define a unique item. Duplicates will be rejected.
            </Typography>
            <Stack direction="row" spacing={1} flexWrap="wrap" useFlexGap>
              {fields.map((f) => {
                const active = uniqueFields.includes(f.key);
                return (
                  <Box
                    key={f.key}
                    onClick={() => toggleUnique(f.key)}
                    sx={{
                      px: 1.5,
                      py: 0.5,
                      borderRadius: 1,
                      border: 1,
                      borderColor: active ? 'primary.main' : 'divider',
                      bgcolor: active ? 'primary.main' : 'transparent',
                      color: active ? 'primary.contrastText' : 'text.primary',
                      cursor: 'pointer',
                      display: 'flex',
                      alignItems: 'center',
                      gap: 0.5,
                    }}
                  >
                    <Typography variant="body2" fontWeight={500}>
                      {f.label}
                    </Typography>
                    <Typography variant="caption" sx={{ opacity: 0.7 }}>
                      ({f.key})
                    </Typography>
                  </Box>
                );
              })}
            </Stack>
          </Box>
          <Box>
            <Button type="submit" variant="contained" startIcon={<Save />} disabled={isSaving}>
              Save Settings
            </Button>
          </Box>
        </Stack>
      </CardContent>
    </Card>
  );
}

function SchemaVersionHistory({ schemaType }: { schemaType: string }) {
  const { data, isLoading } = useQuery({
    queryKey: ['schemas', schemaType],
    queryFn: () => schemaApi.get(schemaType),
  });

  if (isLoading) return <Typography color="onSurfaceVariant">Loading versions…</Typography>;
  const versions = (data?.schema.versions || []) as SchemaVersion[];

  return (
    <Card>
      <CardContent sx={{ p: 3 }}>
        <Stack direction="row" spacing={1} alignItems="center" sx={{ mb: 3 }}>
          <History sx={{ color: 'onSurfaceVariant' }} />
          <Typography variant="titleMedium">Version history</Typography>
        </Stack>
        {versions.length === 0 ? (
          <Typography color="onSurfaceVariant">No version history available</Typography>
        ) : (
          <Stack spacing={2}>
            {versions.map((version, i) => {
              const prev = i > 0 ? (Array.isArray(versions[i - 1].fields) ? versions[i - 1].fields : []) : [];
              const cur = Array.isArray(version.fields) ? version.fields : [];
              const diff = computeDiff(prev, cur);
              const totalChanges = diff.added.length + diff.removed.length + diff.modified.length;
              return (
                <Card
                  key={version.id}
                  variant="outlined"
                  sx={version.is_active ? { borderColor: 'primary', borderWidth: 1.5 } : undefined}
                >
                  <CardContent sx={{ p: 2.5 }}>
                    <Stack direction="row" justifyContent="space-between" alignItems="center" sx={{ mb: 1 }}>
                      <Stack direction="row" spacing={1.5} alignItems="center">
                        <Typography variant="titleMedium">Version {version.version}</Typography>
                        {version.is_active && (
                          <Chip size="small" label="Active" color="primary" variant="filled" sx={{ height: 22 }} />
                        )}
                      </Stack>
                      <Typography variant="bodySmall" color="onSurfaceVariant">
                        {new Date(version.created_at).toLocaleString()}
                      </Typography>
                    </Stack>

                    {i === 0 ? (
                      <Typography variant="bodySmall" color="onSurfaceVariant">
                        Initial schema definition
                      </Typography>
                    ) : totalChanges === 0 ? (
                      <Typography variant="bodySmall" color="onSurfaceVariant">
                        No field changes (metadata only)
                      </Typography>
                    ) : (
                      <Stack spacing={1.5} sx={{ mt: 1 }}>
                        {diff.added.length > 0 && (
                          <DiffRow
                            icon={<AddCircle sx={{ color: 'success.main', fontSize: 18 }} />}
                            label="Added"
                            fields={diff.added}
                            color="success"
                          />
                        )}
                        {diff.removed.length > 0 && (
                          <DiffRow
                            icon={<RemoveCircle sx={{ color: 'error.main', fontSize: 18 }} />}
                            label="Removed"
                            fields={diff.removed}
                            color="error"
                          />
                        )}
                        {diff.modified.length > 0 && (
                          <DiffRow
                            icon={<Edit sx={{ color: 'warning.main', fontSize: 18 }} />}
                            label="Modified"
                            fields={diff.modified}
                            color="warning"
                          />
                        )}
                      </Stack>
                    )}
                  </CardContent>
                </Card>
              );
            })}
          </Stack>
        )}
      </CardContent>
    </Card>
  );
}

function DiffRow({
  icon,
  label,
  fields,
  color,
}: {
  icon: React.ReactNode;
  label: string;
  fields: SchemaField[];
  color: 'success' | 'error' | 'warning';
}) {
  return (
    <Box>
      <Stack direction="row" spacing={0.75} alignItems="center" sx={{ mb: 0.5 }}>
        {icon}
        <Typography variant="labelMedium" color="onSurfaceVariant">
          {label} ({fields.length})
        </Typography>
      </Stack>
      <Stack direction="row" spacing={0.75} flexWrap="wrap" useFlexGap>
        {fields.map((f) => (
          <Chip
            key={f.key}
            size="small"
            label={f.label || f.key}
            color={color}
            variant="outlined"
            sx={{ height: 24 }}
          />
        ))}
      </Stack>
    </Box>
  );
}

function computeDiff(prev: SchemaField[], cur: SchemaField[]) {
  const prevMap = new Map(prev.map((f) => [f.key, f]));
  const curMap = new Map(cur.map((f) => [f.key, f]));
  const added: SchemaField[] = [];
  const removed: SchemaField[] = [];
  const modified: SchemaField[] = [];
  for (const [k, c] of curMap) {
    if (!prevMap.has(k)) added.push(c);
    else {
      const p = prevMap.get(k)!;
      if (p.field_type !== c.field_type || p.required !== c.required || p.label !== c.label) {
        modified.push(c);
      }
    }
  }
  for (const [k, p] of prevMap) {
    if (!curMap.has(k)) removed.push(p);
  }
  return { added, removed, modified };
}

function toEditable(f: SchemaField): EditableField {
  return {
    key: f.key,
    label: f.label,
    field_type: f.field_type,
    required: f.required,
    order: f.order,
    group: f.group,
    options: f.options,
    validation: f.validation,
    display: f.display,
  };
}
