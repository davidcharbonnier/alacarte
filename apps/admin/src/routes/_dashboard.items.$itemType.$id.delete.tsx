import { createFileRoute } from '@tanstack/react-router';
import { ItemDeletePage } from '../pages/item-delete';

export const Route = createFileRoute('/_dashboard/items/$itemType/$id/delete')({
  component: () => {
    const { itemType, id } = Route.useParams();
    return <ItemDeletePage itemType={itemType} id={id} />;
  },
});
