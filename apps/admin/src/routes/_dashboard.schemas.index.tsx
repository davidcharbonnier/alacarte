import { createFileRoute } from '@tanstack/react-router';
import { SchemaListPage } from '../pages/schema-list';

export const Route = createFileRoute('/_dashboard/schemas/')({
  component: SchemaListPage,
});
