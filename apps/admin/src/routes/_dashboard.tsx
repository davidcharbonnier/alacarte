import { createFileRoute } from '@tanstack/react-router';
import { AppLayout } from '../components/layout/app-layout';
import { requireAuth } from '../lib/auth/auth-guard';

export const Route = createFileRoute('/_dashboard')({
  beforeLoad: requireAuth,
  component: AppLayout,
});
