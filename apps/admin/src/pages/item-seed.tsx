import { Alert, Box, CircularProgress } from '@mui/material';
import { useSchema } from '../lib/context/schema-context';
import { GenericSeedForm } from '../components/shared/generic-seed-form';

export function ItemSeedPage({ itemType }: { itemType: string }) {
  const { schema, isLoading } = useSchema(itemType);

  if (isLoading) {
    return (
      <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'center', minHeight: 400 }}>
        <CircularProgress />
      </Box>
    );
  }
  if (!schema) return <Alert severity="warning">Schema not found for type: {itemType}</Alert>;

  return <GenericSeedForm itemType={itemType} />;
}
