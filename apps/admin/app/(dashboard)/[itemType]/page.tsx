'use client';

import { use } from 'react';
import { useQuery } from '@tanstack/react-query';
import { notFound } from 'next/navigation';
import Link from 'next/link';
import { isValidItemType, getItemTypeConfig } from '@/lib/config/item-types';
import { getItemApi } from '@/lib/api/generic-item-api';
import type { BaseItem } from '@/lib/types/item-config';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { LoadingSpinner } from '@/components/shared/loading-spinner';
import { ErrorMessage } from '@/components/shared/error-message';
import { GenericItemTable } from '@/components/shared/generic-item-table';
import { Plus } from 'lucide-react';

export default function ItemListPage({ 
  params 
}: { 
  params: Promise<{ itemType: string }> 
}) {
  const { itemType } = use(params);

  // Validate item type exists in config
  if (!isValidItemType(itemType)) {
    notFound();
  }

  const config = getItemTypeConfig(itemType);

  const { data: items, isLoading, error } = useQuery({
    queryKey: [itemType, 'list'],
    queryFn: () => getItemApi<BaseItem>(itemType).getAll(),
  });

  return (
    <div>
      <div className="flex justify-between items-center mb-6">
        <div>
          <h1 className="text-3xl font-bold text-gray-900">{config.labels.plural} Management</h1>
          <p className="text-gray-600 mt-1">
            Manage {config.labels.plural.toLowerCase()} items and bulk import data
          </p>
        </div>
        <Link href={`/${itemType}/seed`}>
          <Button>
            <Plus className="w-4 h-4 mr-2" />
            Seed Data
          </Button>
        </Link>
      </div>

      <Card>
        <CardHeader>
          <CardTitle>All {config.labels.plural}</CardTitle>
          <CardDescription>
            View and manage all {config.labels.plural.toLowerCase()} in the database
          </CardDescription>
        </CardHeader>
        <CardContent>
          {isLoading && <LoadingSpinner text={`Loading ${config.labels.plural.toLowerCase()}...`} />}
          {error && <ErrorMessage error={error as Error} />}
          {items && <GenericItemTable itemType={itemType} items={items} />}
        </CardContent>
      </Card>
    </div>
  );
}
