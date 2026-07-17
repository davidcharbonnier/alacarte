import { useState } from 'react';
import {
  Box,
  Button,
  Card,
  CardContent,
  Chip,
  Dialog,
  DialogContent,
  IconButton,
  Stack,
  Typography,
} from '@mui/material';
import ArrowBack from '@mui/icons-material/ArrowBack';
import Delete from '@mui/icons-material/Delete';
import CheckCircle from '@mui/icons-material/CheckCircle';
import Cancel from '@mui/icons-material/Cancel';
import Inventory2 from '@mui/icons-material/Inventory2';
import OpenInFull from '@mui/icons-material/OpenInFull';
import Close from '@mui/icons-material/Close';
import { Link } from '@tanstack/react-router';
import { useSchema } from '../../lib/context/schema-context';
import { resolveIcon } from '../../lib/icons/icon-registry';
import { getAccentColor } from '../../theme';
import type { SchemaField } from '../../lib/types/schema';

function getFieldValue(item: any, fieldKey: string): any {
  return item.field_values?.[fieldKey];
}

function formatFieldValue(field: SchemaField, value: any) {
  if (value === null || value === undefined || value === '') {
    if (field.field_type === 'checkbox') return 'No';
    return 'Not specified';
  }
  if (field.field_type === 'checkbox') return value ? 'Yes' : 'No';
  if (field.field_type === 'select' || field.field_type === 'enum') {
    const option = field.options?.find((o) => o.value === value);
    return option?.label || value;
  }
  return value.toString();
}

export function GenericItemDetail({ itemType, item }: { itemType: string; item: any }) {
  const { schema, fields } = useSchema(itemType);
  const [zoomOpen, setZoomOpen] = useState(false);

  if (!schema) return <Typography color="text.secondary">Schema not found for type: {itemType}</Typography>;

  const accent = getAccentColor(schema.color);
  const Icon = resolveIcon(schema.icon);

  const sortedFields = [...fields].sort((a, b) => a.order - b.order);
  const mainFields = sortedFields.filter(
    (f) => f.field_type !== 'textarea' && f.field_type !== 'checkbox',
  );
  const descriptionField = sortedFields.find((f) => f.field_type === 'textarea');
  const checkboxFields = sortedFields.filter((f) => f.field_type === 'checkbox');
  const itemName = getFieldValue(item, 'name') || `Item #${item.id}`;

  return (
    <Stack spacing={3}>
      {/* M3 page header */}
      <Stack direction="row" justifyContent="space-between" alignItems="flex-start" flexWrap="wrap" useFlexGap>
        <Box>
          <Button component={Link} to={`/items/${itemType}`} startIcon={<ArrowBack />} sx={{ mb: 1.5, ml: -1 }}>
            Back
          </Button>
          <Stack direction="row" spacing={1.5} alignItems="center">
            <Box
              sx={{
                width: 56,
                height: 56,
                borderRadius: '16px',
                bgcolor: 'primaryContainer',
                color: 'onPrimaryContainer',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
              }}
            >
              <Icon sx={{ fontSize: 28, color: accent }} />
            </Box>
            <Box>
              <Typography variant="headlineSmall" component="h1">
                {itemName}
              </Typography>
              <Typography variant="bodyMedium" color="onSurfaceVariant">
                {schema.display_name} detail
              </Typography>
            </Box>
          </Stack>
        </Box>
        <Button
          variant="outlined"
          color="error"
          component={Link}
          to={`/items/${itemType}/${item.id}/delete`}
          startIcon={<Delete />}
        >
          Delete
        </Button>
      </Stack>

      <Box sx={{ display: 'grid', gridTemplateColumns: { xs: '1fr', md: 'repeat(2, 1fr)' }, gap: 3 }}>
        <Card>
          <CardContent sx={{ p: 3 }}>
            <Typography variant="titleMedium" sx={{ mb: 2 }}>
              Basic information
            </Typography>
            <Stack spacing={2.5}>
              {[...mainFields, ...checkboxFields].map((field) => {
                const v = getFieldValue(item, field.key);
                if (field.field_type === 'checkbox') {
                  return (
                    <Stack key={field.key} direction="row" justifyContent="space-between" alignItems="center">
                      <Typography variant="bodyMedium" color="onSurfaceVariant">
                        {field.label}
                      </Typography>
                      <Chip
                        size="small"
                        icon={v ? <CheckCircle /> : <Cancel />}
                        label={v ? 'Yes' : 'No'}
                        color={v ? 'success' : 'default'}
                        variant={v ? 'filled' : 'outlined'}
                      />
                    </Stack>
                  );
                }
                return (
                  <Box key={field.key}>
                    <Typography variant="bodySmall" color="onSurfaceVariant" sx={{ mb: 0.5 }}>
                      {field.label}
                    </Typography>
                    <Typography variant="bodyLarge">{formatFieldValue(field, v)}</Typography>
                  </Box>
                );
              })}
            </Stack>
          </CardContent>
        </Card>

        {descriptionField && (
          <Card>
            <CardContent sx={{ p: 3 }}>
              <Typography variant="titleMedium" sx={{ mb: 2 }}>
                {descriptionField.label}
              </Typography>
              <Typography variant="bodyMedium">
                {getFieldValue(item, descriptionField.key) || (
                  <Typography component="span" color="onSurfaceVariant" fontStyle="italic">
                    No description available
                  </Typography>
                )}
              </Typography>
            </CardContent>
          </Card>
        )}

        <Box sx={{ gridColumn: { md: '1 / -1' } }}>
          <Card>
            <CardContent sx={{ p: 3 }}>
              <Typography variant="titleMedium" sx={{ mb: 2 }}>
                Image
              </Typography>
              {item.image_url ? (
                <Box
                  sx={{
                    position: 'relative',
                    borderRadius: '12px',
                    overflow: 'hidden',
                    cursor: 'pointer',
                    maxWidth: 480,
                    bgcolor: 'surfaceContainerLow',
                  }}
                  onClick={() => setZoomOpen(true)}
                >
                  <Box component="img" src={item.image_url} alt={itemName} sx={{ width: '100%', display: 'block' }} />
                  <Box
                    sx={{
                      position: 'absolute',
                      inset: 0,
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'center',
                      bgcolor: 'rgba(0,0,0,0.4)',
                      opacity: 0,
                      transition: 'opacity 0.2s',
                      '&:hover': { opacity: 1 },
                    }}
                  >
                    <OpenInFull sx={{ color: 'white' }} />
                  </Box>
                </Box>
              ) : (
                <Box
                  sx={{
                    height: 200,
                    display: 'flex',
                    flexDirection: 'column',
                    alignItems: 'center',
                    justifyContent: 'center',
                    bgcolor: 'surfaceContainerLow',
                    borderRadius: '12px',
                  }}
                >
                  <Inventory2 sx={{ color: 'onSurfaceVariant', fontSize: 48 }} />
                  <Typography variant="bodySmall" color="onSurfaceVariant" sx={{ mt: 1 }}>
                    No image
                  </Typography>
                </Box>
              )}
            </CardContent>
          </Card>
        </Box>

        <Box sx={{ gridColumn: { md: '1 / -1' } }}>
          <Card>
            <CardContent sx={{ p: 3 }}>
              <Typography variant="titleMedium" sx={{ mb: 2 }}>
                Metadata
              </Typography>
              <Stack spacing={1.5}>
                <MetadataRow label="ID" value={String(item.id)} />
                <MetadataRow label="Created" value={new Date(item.created_at).toLocaleString()} />
                <MetadataRow label="Updated" value={new Date(item.updated_at).toLocaleString()} />
              </Stack>
            </CardContent>
          </Card>
        </Box>
      </Box>

      <Dialog open={zoomOpen} onClose={() => setZoomOpen(false)} maxWidth="lg" fullWidth>
        <IconButton
          onClick={() => setZoomOpen(false)}
          sx={{ position: 'absolute', right: 8, top: 8, color: 'white', bgcolor: 'rgba(0,0,0,0.4)' }}
        >
          <Close />
        </IconButton>
        <DialogContent sx={{ bgcolor: 'black', p: 0 }}>
          <Box component="img" src={item.image_url} alt={itemName} sx={{ width: '100%', display: 'block' }} />
        </DialogContent>
      </Dialog>
    </Stack>
  );
}

function MetadataRow({ label, value }: { label: string; value: string }) {
  return (
    <Stack direction="row" justifyContent="space-between" alignItems="center">
      <Typography variant="bodyMedium" color="onSurfaceVariant">
        {label}
      </Typography>
      <Typography variant="bodyMedium" fontWeight={500}>
        {value}
      </Typography>
    </Stack>
  );
}
