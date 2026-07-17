import { createFileRoute } from '@tanstack/react-router';
import { ItemSeedPage } from '../pages/item-seed';

export const Route = createFileRoute('/_dashboard/items/$itemType/seed')({
  component: () => {
    const { itemType } = Route.useParams();
    return <ItemSeedPage itemType={itemType} />;
  },
});
