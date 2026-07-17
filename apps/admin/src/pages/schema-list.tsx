import { useState } from 'react';
import {
  Alert,
  Box,
  Button,
  Card,
  CardContent,
  Chip,
  Dialog,
  DialogActions,
  DialogContent,
  DialogTitle,
  IconButton,
  MenuItem,
  Stack,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  TextField,
  Typography,
} from '@mui/material';
import Add from '@mui/icons-material/Add';
import Edit from '@mui/icons-material/Edit';
import Delete from '@mui/icons-material/Delete';
import Shield from '@mui/icons-material/Shield';
import Visibility from '@mui/icons-material/Visibility';
import VisibilityOff from '@mui/icons-material/VisibilityOff';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { Link } from '@tanstack/react-router';
import { schemaApi } from '../lib/api/schema-api';
import type { ItemTypeSchema } from '../lib/types/schema';
import { ICON_OPTIONS, resolveIcon } from '../lib/icons/icon-registry';

const COLOR_OPTIONS = [
  '#E67E22', '#9B59B6', '#E74C3C', '#3498DB', '#1ABC9C', '#27AE60',
  '#F39C12', '#2C3E50', '#16A085', '#D35400', '#7F8C8D', '#C0392B',
  '#2980B9', '#8E44AD', '#673AB7', '#009688', '#795548', '#F44336',
  '#FF5722', '#607D8B', '#E91E63', '#00BCD4', '#FFEB3B', '#9C27B0',
];

export function SchemaListPage() {
  const queryClient = useQueryClient();
  const [isCreateOpen, setIsCreateOpen] = useState(false);
  const [deleteTarget, setDeleteTarget] = useState<ItemTypeSchema | null>(null);

  const { data: schemas = [], isLoading, error } = useQuery({
    queryKey: ['schemas', 'all'],
    queryFn: async () => {
      try {
        return (await schemaApi.list(true)) ?? [];
      } catch {
        return [];
      }
    },
  });

  const createMutation = useMutation({
    mutationFn: (data: { name: string; display_name: string; plural_name: string; icon: string; color: string }) =>
      schemaApi.create({ ...data, is_active: true, fields: [] }),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['schemas'], exact: true });
      queryClient.invalidateQueries({ queryKey: ['schemas', 'all'], exact: true });
      setIsCreateOpen(false);
    },
  });

  const deleteMutation = useMutation({
    mutationFn: (type: string) => schemaApi.delete(type),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['schemas'], exact: true });
      queryClient.invalidateQueries({ queryKey: ['schemas', 'all'], exact: true });
      setDeleteTarget(null);
    },
  });

  const toggleMutation = useMutation({
    mutationFn: ({ type, isActive }: { type: string; isActive: boolean }) =>
      schemaApi.update(type, { is_active: isActive }),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['schemas'], exact: true });
      queryClient.invalidateQueries({ queryKey: ['schemas', 'all'], exact: true });
    },
  });

  return (
    <Stack spacing={3}>
      <Stack direction="row" justifyContent="space-between" alignItems="center" flexWrap="wrap" useFlexGap>
        <Box>
          <Typography variant="headlineSmall" component="h1" sx={{ mb: 0.5 }}>
            Schemas
          </Typography>
          <Typography variant="bodyMedium" color="onSurfaceVariant">
            {schemas.length} schema{schemas.length !== 1 ? 's' : ''} defined
          </Typography>
        </Box>
        <Button variant="contained" startIcon={<Add />} onClick={() => setIsCreateOpen(true)}>
          Create schema
        </Button>
      </Stack>

      <Card>
        <CardContent sx={{ p: 0 }}>
          {isLoading && (
            <Box sx={{ p: 4, textAlign: 'center' }}>
              <Typography color="onSurfaceVariant">Loading schemas…</Typography>
            </Box>
          )}
          {error && (
            <Box sx={{ p: 3 }}>
              <Alert severity="error">{(error as Error).message}</Alert>
            </Box>
          )}
          {schemas.length === 0 && !isLoading ? (
            <Box sx={{ textAlign: 'center', py: 8 }}>
              <Shield sx={{ fontSize: 48, color: 'onSurfaceVariant', mb: 1 }} />
              <Typography color="onSurfaceVariant">No schemas found</Typography>
            </Box>
          ) : (
            <TableContainer>
              <Table sx={{ tableLayout: 'fixed' }}>
                <colgroup>
                  <col style={{ width: '32%' }} />
                  <col style={{ width: '24%' }} />
                  <col style={{ width: '12%' }} />
                  <col style={{ width: '16%' }} />
                  <col style={{ width: '16%' }} />
                </colgroup>
                <TableHead>
                  <TableRow>
                    <TableCell sx={headerCellSx}>Name</TableCell>
                    <TableCell sx={headerCellSx}>Display</TableCell>
                    <TableCell sx={headerCellSx}>Fields</TableCell>
                    <TableCell sx={headerCellSx}>Status</TableCell>
                    <TableCell sx={{ ...headerCellSx, textAlign: 'right' }}>Actions</TableCell>
                  </TableRow>
                </TableHead>
                <TableBody>
                  {schemas.map((schema) => {
                    const Icon = resolveIcon(schema.icon);
                    return (
                      <TableRow key={schema.id} hover>
                        <TableCell sx={{ py: 1.5, verticalAlign: 'middle' }}>
                          <Stack direction="row" spacing={1.5} alignItems="center">
                            <Box
                              sx={{
                                width: 36,
                                height: 36,
                                borderRadius: '10px',
                                bgcolor: 'surfaceContainerHighest',
                                color: schema.color,
                                display: 'flex',
                                alignItems: 'center',
                                justifyContent: 'center',
                                flexShrink: 0,
                              }}
                            >
                              <Icon sx={{ fontSize: 18 }} />
                            </Box>
                            <Typography variant="bodyMedium" fontWeight={500} noWrap>
                              {schema.name}
                            </Typography>
                          </Stack>
                        </TableCell>
                        <TableCell sx={{ py: 1.5, verticalAlign: 'middle' }}>
                          <Typography variant="bodyMedium" color="onSurfaceVariant" noWrap>
                            {schema.display_name}
                          </Typography>
                        </TableCell>
                        <TableCell sx={{ py: 1.5, verticalAlign: 'middle' }}>
                          <Chip
                            size="small"
                            label={schema.fields?.length || 0}
                            variant="outlined"
                            sx={{ height: 24 }}
                          />
                        </TableCell>
                        <TableCell sx={{ py: 1.5, verticalAlign: 'middle' }}>
                          <Chip
                            size="small"
                            label={schema.is_active ? 'Active' : 'Inactive'}
                            icon={schema.is_active ? <Visibility sx={{ fontSize: 16 }} /> : <VisibilityOff sx={{ fontSize: 16 }} />}
                            color={schema.is_active ? 'success' : 'default'}
                            variant={schema.is_active ? 'filled' : 'outlined'}
                            onClick={() =>
                              toggleMutation.mutate({ type: schema.name, isActive: !schema.is_active })
                            }
                            sx={{ cursor: 'pointer' }}
                          />
                        </TableCell>
                        <TableCell sx={{ py: 1.5, verticalAlign: 'middle' }}>
                          <Stack direction="row" spacing={0.5} justifyContent="flex-end">
                            <IconButton
                              component={Link}
                              to={`/schemas/${schema.name}`}
                              size="small"
                              aria-label={`Edit ${schema.name}`}
                            >
                              <Edit fontSize="small" />
                            </IconButton>
                            <IconButton
                              color="error"
                              onClick={() => setDeleteTarget(schema)}
                              size="small"
                              aria-label={`Delete ${schema.name}`}
                            >
                              <Delete fontSize="small" />
                            </IconButton>
                          </Stack>
                        </TableCell>
                      </TableRow>
                    );
                  })}
                </TableBody>
              </Table>
            </TableContainer>
          )}
        </CardContent>
      </Card>

      <Dialog open={isCreateOpen} onClose={() => setIsCreateOpen(false)} maxWidth="sm" fullWidth>
        <DialogTitle>Create schema</DialogTitle>
        <DialogContent>
          <CreateSchemaForm
            onSubmit={(data) => createMutation.mutate(data)}
            isLoading={createMutation.isPending}
          />
        </DialogContent>
      </Dialog>

      <Dialog open={!!deleteTarget} onClose={() => setDeleteTarget(null)}>
        <DialogTitle>Delete schema?</DialogTitle>
        <DialogContent>
          <Typography>
            Delete &quot;{deleteTarget?.display_name}&quot; and all its items? This cannot be undone.
          </Typography>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setDeleteTarget(null)}>Cancel</Button>
          <Button
            color="error"
            variant="contained"
            disabled={deleteMutation.isPending}
            onClick={() => deleteTarget && deleteMutation.mutate(deleteTarget.name)}
          >
            Delete
          </Button>
        </DialogActions>
      </Dialog>
    </Stack>
  );
}

const headerCellSx = {
  fontWeight: 500,
  color: 'onSurfaceVariant',
  fontSize: '0.75rem',
  letterSpacing: '0.05em',
  textTransform: 'uppercase' as const,
  borderBottom: 1,
  borderColor: 'outlineVariant',
  py: 1.5,
  bgcolor: 'surfaceContainerLow',
};

function CreateSchemaForm({
  onSubmit,
  isLoading,
}: {
  onSubmit: (data: { name: string; display_name: string; plural_name: string; icon: string; color: string }) => void;
  isLoading: boolean;
}) {
  const [name, setName] = useState('');
  const [displayName, setDisplayName] = useState('');
  const [pluralName, setPluralName] = useState('');
  const [icon, setIcon] = useState(ICON_OPTIONS[0].name);
  const [color, setColor] = useState(COLOR_OPTIONS[0]);

  return (
    <Stack
      spacing={2.5}
      sx={{ pt: 1 }}
      component="form"
      onSubmit={(e) => {
        e.preventDefault();
        onSubmit({ name, display_name: displayName, plural_name: pluralName, icon, color });
      }}
    >
      <Stack direction="row" spacing={2}>
        <TextField
          fullWidth
          required
          label="Name"
          placeholder="cheese"
          value={name}
          onChange={(e) => setName(e.target.value)}
          helperText="lowercase-kebab, unique"
        />
        <TextField select fullWidth label="Icon" value={icon} onChange={(e) => setIcon(e.target.value)}>
          {ICON_OPTIONS.map((opt) => (
            <MenuItem key={opt.name} value={opt.name}>
              {opt.label}
            </MenuItem>
          ))}
        </TextField>
      </Stack>
      <Stack direction="row" spacing={2}>
        <TextField fullWidth required label="Display name" value={displayName} onChange={(e) => setDisplayName(e.target.value)} />
        <TextField fullWidth required label="Plural name" value={pluralName} onChange={(e) => setPluralName(e.target.value)} />
      </Stack>
      <Box>
        <Typography variant="labelMedium" color="onSurfaceVariant" sx={{ mb: 1, display: 'block' }}>
          Color
        </Typography>
        <Stack direction="row" spacing={1} flexWrap="wrap" useFlexGap>
          {COLOR_OPTIONS.map((c) => (
            <Box
              key={c}
              onClick={() => setColor(c)}
              sx={{
                width: 36,
                height: 36,
                borderRadius: '12px',
                bgcolor: c,
                cursor: 'pointer',
                border: 2,
                borderColor: color === c ? 'onSurface' : 'transparent',
                transition: 'transform 0.15s',
                '&:hover': { transform: 'scale(1.1)' },
              }}
            />
          ))}
        </Stack>
      </Box>
      <DialogActions sx={{ px: 0 }}>
        <Button type="submit" variant="contained" disabled={isLoading}>
          Create
        </Button>
      </DialogActions>
    </Stack>
  );
}
