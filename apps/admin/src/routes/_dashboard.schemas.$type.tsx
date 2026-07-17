import { createFileRoute } from '@tanstack/react-router';
import { SchemaEditorPage } from '../pages/schema-editor';

export const Route = createFileRoute('/_dashboard/schemas/$type')({
  component: () => {
    const { type } = Route.useParams();
    return <SchemaEditorPage type={type} />;
  },
});
