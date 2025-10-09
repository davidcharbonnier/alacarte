'use client';

import { useQuery } from '@tanstack/react-query';
import Link from 'next/link';
import { userApi } from '@/lib/api/users';
import { Button } from '@/components/ui/button';
import { Card, CardContent } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { LoadingSpinner } from '@/components/shared/loading-spinner';
import { Shield, User as UserIcon, Calendar, Mail } from 'lucide-react';
import { formatDistanceToNow } from 'date-fns';

export default function UsersPage() {
  const { data: users, isLoading, error } = useQuery({
    queryKey: ['users', 'list'],
    queryFn: userApi.getAll,
  });

  if (isLoading) {
    return (
      <div className="flex items-center justify-center h-64">
        <LoadingSpinner />
      </div>
    );
  }

  if (error) {
    return (
      <div className="text-center py-12">
        <p className="text-red-600">Failed to load users: {(error as Error).message}</p>
      </div>
    );
  }

  const adminCount = users?.filter(u => u.is_admin).length || 0;
  const regularCount = (users?.length || 0) - adminCount;

  return (
    <div>
      <div className="flex items-center justify-between mb-6">
        <div>
          <h1 className="text-3xl font-bold text-gray-900">User Management</h1>
          <p className="text-gray-600 mt-1">
            {users?.length || 0} total users ({adminCount} admins, {regularCount} regular users)
          </p>
        </div>
      </div>

      <div className="grid gap-4">
        {users && users.length > 0 ? (
          users.map((user) => (
            <Card key={user.id} className="hover:shadow-lg transition-shadow">
              <CardContent className="p-6">
                <div className="flex items-start justify-between">
                  <div className="flex items-start space-x-4">
                    {user.avatar ? (
                      <img 
                        src={user.avatar} 
                        alt={user.display_name || user.full_name || 'User avatar'}
                        className="w-12 h-12 rounded-full object-cover"
                        referrerPolicy="no-referrer"
                        onError={(e) => {
                          // Hide image on error and show fallback
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
                    
                    <div className="flex-1">
                      <div className="flex items-center gap-2 mb-1">
                        <h3 className="text-lg font-semibold text-gray-900">
                          {user.display_name || user.full_name}
                        </h3>
                        {user.is_admin && (
                          <Badge variant="default" className="bg-purple-600">
                            <Shield className="w-3 h-3 mr-1" />
                            Admin
                          </Badge>
                        )}
                      </div>
                      
                      <div className="space-y-1 text-sm text-gray-600">
                        <div className="flex items-center gap-2">
                          <Mail className="w-4 h-4" />
                          {user.email}
                        </div>
                        <div className="flex items-center gap-2">
                          <Calendar className="w-4 h-4" />
                          Last login: {formatDistanceToNow(new Date(user.last_login_at), { addSuffix: true })}
                        </div>
                        <div className="flex items-center gap-2">
                          <UserIcon className="w-4 h-4" />
                          Joined: {new Date(user.created_at).toLocaleDateString()}
                        </div>
                      </div>
                    </div>
                  </div>

                  <div className="flex items-center gap-2">
                    <Link href={`/users/${user.id}`}>
                      <Button variant="outline" size="sm">
                        View Details
                      </Button>
                    </Link>
                  </div>
                </div>
              </CardContent>
            </Card>
          ))
        ) : (
          <Card>
            <CardContent className="py-12 text-center">
              <UserIcon className="w-12 h-12 mx-auto text-gray-400 mb-4" />
              <p className="text-gray-600">No users found</p>
            </CardContent>
          </Card>
        )}
      </div>
    </div>
  );
}
