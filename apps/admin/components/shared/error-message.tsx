import { Alert, AlertDescription } from '@/components/ui/alert';
import { AlertCircle } from 'lucide-react';

interface ErrorMessageProps {
  error: Error | string;
  title?: string;
}

export function ErrorMessage({ error, title = 'Error' }: ErrorMessageProps) {
  const message = typeof error === 'string' ? error : error.message;

  return (
    <Alert variant="destructive">
      <AlertCircle className="h-4 w-4" />
      <AlertDescription>
        <strong>{title}:</strong> {message}
      </AlertDescription>
    </Alert>
  );
}
