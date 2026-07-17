import { Alert, Box, Button, Card, CardContent, Fab, InputAdornment, Stack, TextField, Typography } from '@mui/material';
import Add from '@mui/icons-material/Add';
import Search from '@mui/icons-material/Search';
import { Link } from '@tanstack/react-router';
import { useSchema } from '../lib/context/schema-context';
import { resolveIcon } from '../lib/icons/icon-registry';
import { getAccentColor } from '../theme';
import { GenericItemTable } from '../components/shared/generic-item-table';

export function ItemListPage({ itemType }: { itemType: string }) {
  const { schema, isLoading, error } = useSchema(itemType);

  if (isLoading) return <Typography color="onSurfaceVariant">Loading schema…</Typography>;
  if (error) return <Alert severity="error">Failed to load schema: {error.message}</Alert>;
  if (!schema) return <Alert severity="warning">Schema not found for type: {itemType}</Alert>;

  const accent = getAccentColor(schema.color);
  const Icon = resolveIcon(schema.icon);

  return (
    <Box sx={{ pb: 10 }}>
      <Stack spacing={4}>
        {/* M3 page header */}
        <Box>
          <Stack direction="row" spacing={2} alignItems="center" sx={{ mb: 1 }}>
            <Box
              sx={{
                width: 48,
                height: 48,
                borderRadius: '16px',
                bgcolor: 'primaryContainer',
                color: 'onPrimaryContainer',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
              }}
            >
              <Icon sx={{ fontSize: 24, color: accent }} />
            </Box>
            <Box>
              <Typography variant="headlineSmall" component="h1">
                {schema.plural_name}
              </Typography>
              <Typography variant="bodyMedium" color="onSurfaceVariant">
                Manage {schema.plural_name.toLowerCase()} items and bulk import data
              </Typography>
            </Box>
          </Stack>
        </Box>

        {/* M3 FilledTonal button for secondary action */}
        <Stack direction="row" justifyContent="flex-end" spacing={1.5}>
          <Button
            variant="outlined"
            component={Link}
            to={`/items/${itemType}/seed`}
            startIcon={<Add />}
          >
            Seed data
          </Button>
        </Stack>

        <Card>
          <CardContent sx={{ p: 3 }}>
            <GenericItemTable itemType={itemType} />
          </CardContent>
        </Card>
      </Stack>

      {/* M3 FAB (small) — primary action */}
      <Fab
        color="primary"
        aria-label="Add item"
        component={Link}
        to={`/items/${itemType}/seed`}
        sx={{ position: 'fixed', bottom: 24, right: 24 }}
      >
        <Add />
      </Fab>
    </Box>
  );
}
