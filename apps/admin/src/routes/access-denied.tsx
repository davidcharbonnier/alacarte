import { createFileRoute } from '@tanstack/react-router';
import { AccessDeniedPage } from '../pages/access-denied';

export const Route = createFileRoute('/access-denied')({
  component: AccessDeniedPage,
});
