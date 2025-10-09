'use client';

import { use, useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { useRouter } from 'next/navigation';
import Link from 'next/link';
import { userApi } from '@/lib/api/users';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Alert, AlertDescription, AlertTitle } from '@/components/ui/alert';
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog';
import { LoadingSpinner } from '@/components/shared/loading-spinner';
import { 
  ArrowLeft, 
  Shield, 
  ShieldOff, 
  Trash2, 
  User as UserIcon, 
  Mail, 
  Calendar,
  AlertTriangle,
  CheckCircle,
  Eye
} from 'lucide-react';
import { formatDistanceToNow } from 'date-fns';

export default function UserDetailPage({ params }: { params: Promise<{ id: string }> }) {
  const router = useRouter();
  const queryClient = useQueryClient();
  const [showPromoteDialog, setShowPromoteDialog] = useState(false);
  const [showDemoteDialog, setShowDemoteDialog] = useState(false);

  // Unwrap params Promise (Next.js 15+)
  const { id } = use(params);

  const { data: user, isLoading } = useQuery({
    queryKey: ['users', id],
    queryFn: () => userApi.getById(Number(id)),
  });

  const promoteMutation = useMutation({
    mutationFn: () => userApi.promote(Number(id)),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['users'] });
      setShowPromoteDialog(false);
    },
  });

  const demoteMutation = useMutation({
    mutationFn: () => userApi.demote(Number(id)),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['users'] });
      setShowDemoteDialog(false);
    },
  });

  if (isLoading) {
    return (
      <div className="flex items-center justify-center h-64">
        <LoadingSpinner />
      </div>
    );
  }

  if (!user) {
    return (
      <div className="text-center py-12">
        <p className="text-red-600">User not found</p>
      </div>
    );
  }

  return (
    <div>
      <div className="flex items-center space-x-4 mb-6">
        <Link href="/users">
          <Button variant="ghost" size="sm">
            <ArrowLeft className="w-4 h-4 mr-2" />
            Back to Users
          </Button>
        </Link>
      </div>

      <div className="grid gap-6 md:grid-cols-2">
        {/* User Information Card */}
        <Card>
          <CardHeader>
            <div className="flex items-center justify-between">
              <CardTitle>User Information</CardTitle>
              {user.is_admin && (
                <Badge variant="default" className="bg-purple-600">
                  <Shield className="w-3 h-3 mr-1" />
                  Admin
                </Badge>
              )}
            </div>
          </CardHeader>
          <CardContent className="space-y-6">
            <div className="flex items-center space-x-4">
              {user.avatar ? (
                <img 
                  src={user.avatar} 
                  alt={user.display_name || user.full_name || 'User avatar'}
                  className="w-16 h-16 rounded-full object-cover"
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
                className="w-16 h-16 rounded-full bg-gray-200 flex items-center justify-center"
                style={{ display: user.avatar ? 'none' : 'flex' }}
              >
                <UserIcon className="w-8 h-8 text-gray-500" />
              </div>
              <div>
                <h2 className="text-xl font-semibold">{user.display_name}</h2>
                <p className="text-gray-600">{user.full_name}</p>
              </div>
            </div>

            <div className="space-y-3 text-sm">
              <div className="flex items-center gap-3">
                <Mail className="w-4 h-4 text-gray-500" />
                <span className="font-medium text-gray-700">Email:</span>
                <span className="text-gray-900">{user.email}</span>
              </div>

              <div className="flex items-center gap-3">
                <UserIcon className="w-4 h-4 text-gray-500" />
                <span className="font-medium text-gray-700">Google ID:</span>
                <span className="text-gray-600 text-xs font-mono">{user.google_id}</span>
              </div>

              <div className="flex items-center gap-3">
                <Eye className="w-4 h-4 text-gray-500" />
                <span className="font-medium text-gray-700">Discoverable:</span>
                <span className="text-gray-900">{user.discoverable ? 'Yes' : 'No'}</span>
              </div>

              <div className="flex items-center gap-3">
                <Calendar className="w-4 h-4 text-gray-500" />
                <span className="font-medium text-gray-700">Joined:</span>
                <span className="text-gray-900">{new Date(user.created_at).toLocaleDateString()}</span>
              </div>

              <div className="flex items-center gap-3">
                <Calendar className="w-4 h-4 text-gray-500" />
                <span className="font-medium text-gray-700">Last Login:</span>
                <span className="text-gray-900">
                  {formatDistanceToNow(new Date(user.last_login_at), { addSuffix: true })}
                </span>
              </div>
            </div>
          </CardContent>
        </Card>

        {/* Admin Actions Card */}
        <Card>
          <CardHeader>
            <CardTitle>Admin Actions</CardTitle>
            <CardDescription>Manage user permissions and account</CardDescription>
          </CardHeader>
          <CardContent className="space-y-4">
            {/* Promote/Demote Section */}
            <div className="space-y-3">
              <h3 className="font-medium text-sm text-gray-700">Admin Privileges</h3>
              {user.is_admin ? (
                <Button
                  variant="outline"
                  className="w-full"
                  onClick={() => setShowDemoteDialog(true)}
                >
                  <ShieldOff className="w-4 h-4 mr-2" />
                  Revoke Admin Privileges
                </Button>
              ) : (
                <Button
                  variant="default"
                  className="w-full bg-purple-600 hover:bg-purple-700"
                  onClick={() => setShowPromoteDialog(true)}
                >
                  <Shield className="w-4 h-4 mr-2" />
                  Grant Admin Privileges
                </Button>
              )}
            </div>

            <div className="border-t pt-4">
              <h3 className="font-medium text-sm text-gray-700 mb-3">Danger Zone</h3>
              <Link href={`/users/${user.id}/delete`}>
                <Button variant="destructive" className="w-full">
                  <Trash2 className="w-4 h-4 mr-2" />
                  Delete User Account
                </Button>
              </Link>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Promote Dialog */}
      <Dialog open={showPromoteDialog} onOpenChange={setShowPromoteDialog}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle className="flex items-center gap-2">
              <Shield className="w-5 h-5 text-purple-600" />
              Grant Admin Privileges
            </DialogTitle>
            <DialogDescription>
              You are about to promote this user to admin.
            </DialogDescription>
          </DialogHeader>

          <Alert className="border-purple-200 bg-purple-50">
            <AlertTriangle className="h-4 w-4 text-purple-600" />
            <AlertTitle className="text-purple-900">Important: Admin Access</AlertTitle>
            <AlertDescription className="text-purple-800 space-y-2">
              <p className="font-medium">Admins will have full access to:</p>
              <ul className="list-disc list-inside space-y-1 text-sm">
                <li>View all users and their emails</li>
                <li>Manage all items (cheese, gin, etc.)</li>
                <li>Delete items and users</li>
                <li>Bulk import data</li>
                <li>Promote/demote other users</li>
              </ul>
              <p className="text-sm font-medium mt-3">
                Only grant admin access to trusted individuals.
              </p>
            </AlertDescription>
          </Alert>

          <div className="bg-gray-50 p-4 rounded-lg">
            <p className="text-sm text-gray-700">
              <strong>User:</strong> {user.display_name} ({user.email})
            </p>
          </div>

          {promoteMutation.isError && (
            <Alert variant="destructive">
              <AlertTriangle className="h-4 w-4" />
              <AlertTitle>Promotion Failed</AlertTitle>
              <AlertDescription>
                {(promoteMutation.error as any)?.response?.data?.error || 
                 (promoteMutation.error as Error)?.message || 
                 'Failed to promote user'}
              </AlertDescription>
            </Alert>
          )}

          <DialogFooter>
            <Button
              variant="outline"
              onClick={() => setShowPromoteDialog(false)}
              disabled={promoteMutation.isPending}
            >
              Cancel
            </Button>
            <Button
              onClick={() => promoteMutation.mutate()}
              disabled={promoteMutation.isPending}
              className="bg-purple-600 hover:bg-purple-700"
            >
              {promoteMutation.isPending ? (
                <>
                  <LoadingSpinner size="sm" />
                  <span className="ml-2">Promoting...</span>
                </>
              ) : (
                <>
                  <Shield className="w-4 h-4 mr-2" />
                  Confirm Promotion
                </>
              )}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Demote Dialog */}
      <Dialog open={showDemoteDialog} onOpenChange={setShowDemoteDialog}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle className="flex items-center gap-2">
              <ShieldOff className="w-5 h-5 text-orange-600" />
              Revoke Admin Privileges
            </DialogTitle>
            <DialogDescription>
              You are about to demote this user from admin.
            </DialogDescription>
          </DialogHeader>

          <Alert className="border-orange-200 bg-orange-50">
            <AlertTriangle className="h-4 w-4 text-orange-600" />
            <AlertTitle className="text-orange-900">Admin Access Will Be Revoked</AlertTitle>
            <AlertDescription className="text-orange-800 space-y-2">
              <p className="font-medium">The user will lose access to:</p>
              <ul className="list-disc list-inside space-y-1 text-sm">
                <li>Admin panel and all admin features</li>
                <li>User management capabilities</li>
                <li>Item management and deletion</li>
                <li>Data import and bulk operations</li>
              </ul>
              <p className="text-sm font-medium mt-3">
                They will remain a regular user with their own ratings.
              </p>
            </AlertDescription>
          </Alert>

          <div className="bg-gray-50 p-4 rounded-lg">
            <p className="text-sm text-gray-700">
              <strong>User:</strong> {user.display_name} ({user.email})
            </p>
          </div>

          {demoteMutation.isError && (
            <Alert variant="destructive">
              <AlertTriangle className="h-4 w-4" />
              <AlertTitle>Demotion Failed</AlertTitle>
              <AlertDescription>
                {(demoteMutation.error as Error).message}
                {(demoteMutation.error as Error).message.includes('initial admin') && (
                  <p className="mt-2 font-medium">
                    Note: The initial admin (configured in INITIAL_ADMIN_EMAIL) cannot be demoted.
                  </p>
                )}
              </AlertDescription>
            </Alert>
          )}

          <DialogFooter>
            <Button
              variant="outline"
              onClick={() => setShowDemoteDialog(false)}
              disabled={demoteMutation.isPending}
            >
              Cancel
            </Button>
            <Button
              onClick={() => demoteMutation.mutate()}
              disabled={demoteMutation.isPending}
              variant="destructive"
            >
              {demoteMutation.isPending ? (
                <>
                  <LoadingSpinner size="sm" />
                  <span className="ml-2">Revoking...</span>
                </>
              ) : (
                <>
                  <ShieldOff className="w-4 h-4 mr-2" />
                  Confirm Demotion
                </>
              )}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}
