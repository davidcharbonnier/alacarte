import { createFileRoute } from '@tanstack/react-router';
import { UserListPage } from '../pages/user-list';

export const Route = createFileRoute('/_dashboard/users/')({
  component: UserListPage,
});
