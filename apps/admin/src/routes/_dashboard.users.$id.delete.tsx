import { createFileRoute } from '@tanstack/react-router';
import { UserDeletePage } from '../pages/user-delete';

export const Route = createFileRoute('/_dashboard/users/$id/delete')({
  component: () => {
    const { id } = Route.useParams();
    return <UserDeletePage id={id} />;
  },
});
