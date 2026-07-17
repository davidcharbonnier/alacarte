import { createFileRoute } from '@tanstack/react-router';
import { ItemListPage } from '../pages/item-list';

export const Route = createFileRoute('/_dashboard/items/$itemType/')({
  component: () => {
    const { itemType } = Route.useParams();
    return <ItemListPage itemType={itemType} />;
  },
});
