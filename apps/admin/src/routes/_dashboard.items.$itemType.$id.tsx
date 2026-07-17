import { createFileRoute } from '@tanstack/react-router';
import { ItemDetailPage } from '../pages/item-detail';

export const Route = createFileRoute('/_dashboard/items/$itemType/$id')({
  component: () => {
    const { itemType, id } = Route.useParams();
    return <ItemDetailPage itemType={itemType} id={id} />;
  },
});
