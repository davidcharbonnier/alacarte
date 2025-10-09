'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { useMutation, useQueryClient } from '@tanstack/react-query';
import Link from 'next/link';
import { getItemTypeConfig } from '@/lib/config/item-types';
import { getItemApi } from '@/lib/api/generic-item-api';
import type { BaseItem } from '@/lib/types/item-config';
import type { DeleteImpact } from '@/lib/types/api';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Alert, AlertDescription, AlertTitle } from '@/components/ui/alert';
import { LoadingSpinner } from '@/components/shared/loading-spinner';
import { ArrowLeft, AlertTriangle, Trash2 } from 'lucide-react';

interface GenericDeleteImpactProps<T extends BaseItem> {
  itemType: string;
  item: T;
  impact: DeleteImpact;
}

export function GenericDeleteImpact<T extends BaseItem>({ 
  itemType, 
  item,
  impact 
}: GenericDeleteImpactProps<T>) {
  const config = getItemTypeConfig(itemType);
  const router = useRouter();
  const queryClient = useQueryClient();
  const [isDeleting, setIsDeleting] = useState(false);

  const deleteMutation = useMutation({
    mutationFn: () => getItemApi(itemType).delete(item.id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: [itemType, 'list'] });
      router.push(`/${itemType}`);
    },
  });

  const handleDelete = () => {
    if (window.confirm(`Are you absolutely sure? This will permanently delete this ${config.labels.singular.toLowerCase()} and all associated data. This action cannot be undone.`)) {
      setIsDeleting(true);
      deleteMutation.mutate();
    }
  };

  return (
    <div>
      <div className="flex items-center space-x-4 mb-6">
        <Link href={`/${itemType}/${item.id}`}>
          <Button variant="ghost" size="sm">
            <ArrowLeft className="w-4 h-4 mr-2" />
            Back to Details
          </Button>
        </Link>
        <h1 className="text-3xl font-bold text-gray-900">
          Delete {config.labels.singular}: {item.name}
        </h1>
      </div>

      <Alert variant="destructive" className="mb-6">
        <AlertTriangle className="h-4 w-4" />
        <AlertTitle>Warning: This action is permanent</AlertTitle>
        <AlertDescription>
          Deleting this {config.labels.singular.toLowerCase()} will cascade and remove all associated data. This cannot be undone.
        </AlertDescription>
      </Alert>

      <Card className="mb-6">
        <CardHeader>
          <CardTitle>Impact Assessment</CardTitle>
          <CardDescription>Review what will be affected by this deletion</CardDescription>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mb-6">
            <div className="p-4 bg-red-50 rounded-lg border border-red-200">
              <div className="text-sm font-medium text-red-600">Ratings to Delete</div>
              <div className="text-3xl font-bold text-red-700 mt-2">
                {impact.impact.ratings_count}
              </div>
            </div>
            <div className="p-4 bg-orange-50 rounded-lg border border-orange-200">
              <div className="text-sm font-medium text-orange-600">Users Affected</div>
              <div className="text-3xl font-bold text-orange-700 mt-2">
                {impact.impact.users_affected}
              </div>
            </div>
            <div className="p-4 bg-yellow-50 rounded-lg border border-yellow-200">
              <div className="text-sm font-medium text-yellow-600">Sharings Removed</div>
              <div className="text-3xl font-bold text-yellow-700 mt-2">
                {impact.impact.sharings_count}
              </div>
            </div>
          </div>

          {impact.warnings.length > 0 && (
            <div className="space-y-2 mb-6">
              <h3 className="font-semibold text-gray-900">Important Warnings:</h3>
              <ul className="list-disc list-inside space-y-1">
                {impact.warnings.map((warning: any, index: number) => (
                  <li key={index} className="text-sm text-gray-700">
                    {warning}
                  </li>
                ))}
              </ul>
            </div>
          )}

          {impact.impact.affected_users.length > 0 && (
            <div>
              <h3 className="font-semibold text-gray-900 mb-3">Affected Users:</h3>
              <div className="space-y-2">
                {impact.impact.affected_users.map((user: any) => (
                  <div
                    key={user.id}
                    className="flex justify-between items-center p-3 bg-gray-50 rounded border"
                  >
                    <span className="font-medium">{user.display_name}</span>
                    <span className="text-sm text-gray-600">
                      {user.ratings_count} rating{user.ratings_count !== 1 ? 's' : ''} will be lost
                    </span>
                  </div>
                ))}
              </div>
            </div>
          )}
        </CardContent>
      </Card>

      <div className="flex justify-end space-x-4">
        <Link href={`/${itemType}/${item.id}`}>
          <Button variant="outline">Cancel</Button>
        </Link>
        <Button
          variant="destructive"
          onClick={handleDelete}
          disabled={isDeleting || !impact.can_delete}
        >
          {isDeleting ? (
            <>
              <LoadingSpinner size="sm" />
              <span className="ml-2">Deleting...</span>
            </>
          ) : (
            <>
              <Trash2 className="w-4 h-4 mr-2" />
              Confirm Delete
            </>
          )}
        </Button>
      </div>
    </div>
  );
}
