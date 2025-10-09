'use client';

import { Suspense } from 'react';
import { useSearchParams } from 'next/navigation';
import { signIn } from 'next-auth/react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Alert, AlertDescription, AlertTitle } from '@/components/ui/alert';
import { ShieldAlert } from 'lucide-react';

function LoginForm() {
  const searchParams = useSearchParams();
  const error = searchParams.get('error');

  const handleGoogleSignIn = () => {
    signIn('google', { callbackUrl: '/' });
  };

  // Map NextAuth error codes to user-friendly messages
  const getErrorMessage = (errorCode: string | null) => {
    switch (errorCode) {
      case 'Configuration':
        return {
          title: 'Configuration Error',
          description: 'There is a problem with the server configuration. Please contact the administrator.',
        };
      case 'AccessDenied':
        return {
          title: 'Access Denied',
          description: 'Your account does not have administrator privileges. Please contact the administrator if you believe this is an error.',
        };
      case 'Verification':
        return {
          title: 'Verification Failed',
          description: 'The sign-in verification failed. Please try again.',
        };
      case 'ServiceUnavailable':
        return {
          title: 'Service Unavailable',
          description: 'Unable to connect to the authentication service. Please try again later or contact the administrator if the problem persists.',
        };
      case 'AuthenticationFailed':
        return {
          title: 'Authentication Failed',
          description: 'An unexpected error occurred during sign-in. Please try again or contact the administrator.',
        };
      default:
        if (errorCode) {
          return {
            title: 'Authentication Error',
            description: 'An error occurred during sign-in. Please try again.',
          };
        }
        return null;
    }
  };

  const errorInfo = getErrorMessage(error);

  return (
    <div className="space-y-4">
      {errorInfo && (
        <Alert variant="destructive">
          <ShieldAlert className="h-4 w-4" />
          <AlertTitle>{errorInfo.title}</AlertTitle>
          <AlertDescription>{errorInfo.description}</AlertDescription>
        </Alert>
      )}
      
      <Card>
        <CardHeader className="space-y-1">
          <CardTitle className="text-2xl text-center">A la carte Admin</CardTitle>
          <CardDescription className="text-center">
            Sign in with your Google account to continue
          </CardDescription>
        </CardHeader>
        <CardContent>
          <Button
            onClick={handleGoogleSignIn}
            className="w-full"
            size="lg"
          >
            Sign in with Google
          </Button>
        </CardContent>
      </Card>
    </div>
  );
}

export default function LoginPage() {
  return (
    <Suspense fallback={
      <Card>
        <CardHeader className="space-y-1">
          <CardTitle className="text-2xl text-center">A la carte Admin</CardTitle>
          <CardDescription className="text-center">
            Sign in with your Google account to continue
          </CardDescription>
        </CardHeader>
        <CardContent>
          <Button className="w-full" size="lg" disabled>
            Loading...
          </Button>
        </CardContent>
      </Card>
    }>
      <LoginForm />
    </Suspense>
  );
}
