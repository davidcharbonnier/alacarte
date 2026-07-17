import { Alert, Box, CircularProgress } from '@mui/material';
import { useQuery } from '@tanstack/react-query';
import { useSchema } from '../lib/context/schema-context';
import { dynamicItemApi } from '../lib/api/schema-api';
import { GenericDeleteImpact } from '../components/shared/generic-delete-impact';

export function ItemDeletePage({ itemType, id }: { itemType: string; id: string }) {
  const itemId = parseInt(id, 10);
  const { schema, isLoading: schemaLoading } = useSchema(itemType);

  const { data: item } = useQuery({
    queryKey: [itemType, 'detail', itemId],
    queryFn: () => dynamicItemApi.get(itemType, itemId),
    enabled: !!schema,
  });

  const { data: impact, isLoading, error } = useQuery({
    queryKey: [itemType, 'delete-impact', itemId],
    queryFn: () => dynamicItemApi.getDeleteImpact(itemType, itemId),
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
  if (!impact || !item) return <Alert severity="warning">Unable to load delete impact</Alert>;

  return <GenericDeleteImpact itemType={itemType} item={item} impact={impact} />;
}
