'use client';

import { use, useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { useRouter } from 'next/navigation';
import Link from 'next/link';
import { userApi } from '@/lib/api/users';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Alert, AlertDescription, AlertTitle } from '@/components/ui/alert';
import { Badge } from '@/components/ui/badge';
import { LoadingSpinner } from '@/components/shared/loading-spinner';
import { 
  ArrowLeft, 
  AlertTriangle, 
  Trash2, 
  Users, 
  MessageSquare,
  Share2,
  User as UserIcon
} from 'lucide-react';

export default function UserDeleteImpactPage({ params }: { params: Promise<{ id: string }> }) {
  const router = useRouter();
  const queryClient = useQueryClient();
  const [confirmText, setConfirmText] = useState('');

  // Unwrap params Promise (Next.js 15+)
  const { id } = use(params);

  const { data: user } = useQuery({
    queryKey: ['users', id],
    queryFn: () => userApi.getById(Number(id)),
  });

  const { data: impact, isLoading } = useQuery({
    queryKey: ['users', id, 'delete-impact'],
    queryFn: () => userApi.getDeleteImpact(Number(id)),
  });

  const deleteMutation = useMutation({
    mutationFn: () => userApi.delete(Number(id)),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['users'] });
      router.push('/users');
    },
  });

  if (isLoading) {
    return (
      <div className="flex items-center justify-center h-64">
        <LoadingSpinner />
      </div>
    );
  }

  if (!impact || !user) {
    return (
      <div className="text-center py-12">
        <p className="text-red-600">Failed to load delete impact data</p>
      </div>
    );
  }

  const canDelete = confirmText === user.display_name;

  return (
    <div>
      <div className="flex items-center space-x-4 mb-6">
        <Link href={`/users/${id}`}>
          <Button variant="ghost" size="sm">
            <ArrowLeft className="w-4 h-4 mr-2" />
            Back to User
          </Button>
        </Link>
      </div>

      <div className="max-w-3xl space-y-6">
        <Card className="border-red-200 bg-red-50">
          <CardHeader>
            <CardTitle className="flex items-center gap-2 text-red-900">
              <AlertTriangle className="w-5 h-5" />
              Delete User Account
            </CardTitle>
            <CardDescription className="text-red-800">
              This action will permanently delete all user data and cannot be undone
            </CardDescription>
          </CardHeader>
        </Card>

        {/* User Info */}
        <Card>
          <CardHeader>
            <CardTitle>User to be deleted</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="flex items-center space-x-4">
              {user.avatar ? (
                <img 
                  src={user.avatar} 
                  alt={user.display_name || user.full_name || 'User avatar'}
                  className="w-12 h-12 rounded-full object-cover"
                  referrerPolicy="no-referrer"
                  onError={(e) => {
                    e.currentTarget.style.display = 'none';
                    const fallback = e.currentTarget.nextElementSibling;
                    if (fallback) {
                      (fallback as HTMLElement).style.display = 'flex';
                    }
                  }}
                />
              ) : null}
              <div 
                className="w-12 h-12 rounded-full bg-gray-200 flex items-center justify-center"
                style={{ display: user.avatar ? 'none' : 'flex' }}
              >
                <UserIcon className="w-6 h-6 text-gray-500" />
              </div>
              <div>
                <div className="flex items-center gap-2">
                  <h3 className="text-lg font-semibold">{user.display_name}</h3>
                  {user.is_admin && (
                    <Badge variant="default" className="bg-purple-600">Admin</Badge>
                  )}
                </div>
                <p className="text-sm text-gray-600">{user.email}</p>
              </div>
            </div>
          </CardContent>
        </Card>

        {/* Warnings */}
        <Card className="border-orange-200">
          <CardHeader>
            <CardTitle className="text-orange-900">Warnings</CardTitle>
          </CardHeader>
          <CardContent className="space-y-2">
            {impact.warnings.map((warning, index) => (
              <Alert key={index} className="border-orange-200 bg-orange-50">
                <AlertTriangle className="h-4 w-4 text-orange-600" />
                <AlertDescription className="text-orange-900">
                  {warning}
                </AlertDescription>
              </Alert>
            ))}
          </CardContent>
        </Card>

        {/* Impact Statistics */}
        <Card>
          <CardHeader>
            <CardTitle>Deletion Impact</CardTitle>
            <CardDescription>
              Overview of what will be permanently deleted
            </CardDescription>
          </CardHeader>
          <CardContent>
            <div className="grid grid-cols-3 gap-4">
              <div className="text-center p-4 bg-gray-50 rounded-lg">
                <MessageSquare className="w-8 h-8 mx-auto text-gray-600 mb-2" />
                <p className="text-2xl font-bold text-gray-900">{impact.impact.ratings_count}</p>
                <p className="text-sm text-gray-600">Ratings</p>
              </div>
              <div className="text-center p-4 bg-gray-50 rounded-lg">
                <Users className="w-8 h-8 mx-auto text-gray-600 mb-2" />
                <p className="text-2xl font-bold text-gray-900">{impact.impact.users_affected}</p>
                <p className="text-sm text-gray-600">Users Affected</p>
              </div>
              <div className="text-center p-4 bg-gray-50 rounded-lg">
                <Share2 className="w-8 h-8 mx-auto text-gray-600 mb-2" />
                <p className="text-2xl font-bold text-gray-900">{impact.impact.sharings_count}</p>
                <p className="text-sm text-gray-600">Sharing Links</p>
              </div>
            </div>
          </CardContent>
        </Card>

        {/* Affected Users */}
        {impact.impact.affected_users && impact.impact.affected_users.length > 0 && (
          <Card>
            <CardHeader>
              <CardTitle>Users Who Will Lose Shared Ratings</CardTitle>
              <CardDescription>
                These users have ratings shared from this user and will lose access
              </CardDescription>
            </CardHeader>
            <CardContent>
              <div className="space-y-2">
                {impact.impact.affected_users.map((affectedUser) => (
                  <div
                    key={affectedUser.id}
                    className="flex items-center justify-between p-3 bg-gray-50 rounded-lg"
                  >
                    <span className="font-medium text-gray-900">
                      {affectedUser.display_name}
                    </span>
                    <Badge variant="outline">
                      {affectedUser.ratings_count} rating{affectedUser.ratings_count !== 1 ? 's' : ''}
                    </Badge>
                  </div>
                ))}
              </div>
            </CardContent>
          </Card>
        )}

        {/* Confirmation */}
        <Card className="border-red-200">
          <CardHeader>
            <CardTitle className="text-red-900">Confirm Deletion</CardTitle>
            <CardDescription>
              Type the user&apos;s display name <strong>{user.display_name}</strong> to confirm
            </CardDescription>
          </CardHeader>
          <CardContent className="space-y-4">
            <input
              type="text"
              value={confirmText}
              onChange={(e) => setConfirmText(e.target.value)}
              placeholder={`Type "${user.display_name}" to confirm`}
              className="w-full px-4 py-2 border rounded-md focus:outline-none focus:ring-2 focus:ring-red-500"
              disabled={deleteMutation.isPending}
            />

            {deleteMutation.isError && (
              <Alert variant="destructive">
                <AlertTriangle className="h-4 w-4" />
                <AlertTitle>Deletion Failed</AlertTitle>
                <AlertDescription>
                  {(deleteMutation.error as Error).message}
                </AlertDescription>
              </Alert>
            )}

            <div className="flex gap-4">
              <Link href={`/users/${id}`} className="flex-1">
                <Button
                  variant="outline"
                  className="w-full"
                  disabled={deleteMutation.isPending}
                >
                  Cancel
                </Button>
              </Link>
              <Button
                variant="destructive"
                onClick={() => deleteMutation.mutate()}
                disabled={!canDelete || deleteMutation.isPending}
                className="flex-1"
              >
                {deleteMutation.isPending ? (
                  <>
                    <LoadingSpinner size="sm" />
                    <span className="ml-2">Deleting...</span>
                  </>
                ) : (
                  <>
                    <Trash2 className="w-4 h-4 mr-2" />
                    Delete User Permanently
                  </>
                )}
              </Button>
            </div>
          </CardContent>
        </Card>
      </div>
    </div>
  );
}
