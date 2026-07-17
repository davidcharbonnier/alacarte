import { createFileRoute } from '@tanstack/react-router';
import { UserDetailPage } from '../pages/user-detail';

export const Route = createFileRoute('/_dashboard/users/$id')({
  component: () => {
    const { id } = Route.useParams();
    return <UserDetailPage id={id} />;
  },
});
