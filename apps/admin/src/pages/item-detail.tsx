import { Alert, Box, CircularProgress, Stack, Typography } from '@mui/material';
import { useQuery } from '@tanstack/react-query';
import { useSchema } from '../lib/context/schema-context';
import { dynamicItemApi } from '../lib/api/schema-api';
import { GenericItemDetail } from '../components/shared/generic-item-detail';

export function ItemDetailPage({ itemType, id }: { itemType: string; id: string }) {
  const itemId = parseInt(id, 10);
  const { schema, isLoading: schemaLoading } = useSchema(itemType);

  const { data: item, isLoading, error } = useQuery({
    queryKey: [itemType, 'detail', itemId],
    queryFn: () => dynamicItemApi.get(itemType, itemId),
    enabled: !!schema,
  });

  if (schemaLoading || isLoading) {
    return (
      <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'center', minHeight: 400 }}>
        <CircularProgress />
      </Box>
    );
  }
  if (!schema) return <Alert severity="warning">Schema not found for type: {itemType}</Alert>;
  if (error) return <Alert severity="error">{(error as Error).message}</Alert>;
  if (!item) return <Alert severity="warning">Item not found</Alert>;

  return <GenericItemDetail itemType={itemType} item={item} />;
}
