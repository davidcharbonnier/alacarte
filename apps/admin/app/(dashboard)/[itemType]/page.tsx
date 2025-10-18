'use client';

import { use } from 'react';
import { useQuery } from '@tanstack/react-query';
import { notFound } from 'next/navigation';
import Link from 'next/link';
import { isValidItemType, getItemTypeConfig } from '@/lib/config/item-types';
import { getItemApi } from '@/lib/api/generic-item-api';
import { getItemTypeColor } from '@/lib/config/design-system';
import type { BaseItem } from '@/lib/types/item-config';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { LoadingSpinner } from '@/components/shared/loading-spinner';
import { ErrorMessage } from '@/components/shared/error-message';
import { GenericItemTable } from '@/components/shared/generic-item-table';
import { Plus } from 'lucide-react';
import * as Icons from 'lucide-react';

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
  const colors = getItemTypeColor(itemType);
  const IconComponent = (Icons as any)[config.icon] || Icons.HelpCircle;

  const { data: items, isLoading, error } = useQuery({
    queryKey: [itemType, 'list'],
    queryFn: () => getItemApi<BaseItem>(itemType).getAll(),
  });

  return (
    <div className="space-y-6">
      {/* Colored Header */}
      <div className="flex justify-between items-start">
        <div>
          <div className="flex items-center gap-3 mb-2">
            {/* Colored Icon */}
            <div
              className="flex items-center justify-center w-12 h-12 rounded-xl"
              style={{ backgroundColor: `${colors.hex}20` }}
            >
              <IconComponent
                className="w-6 h-6"
                style={{ color: colors.hex }}
              />
            </div>
            <h1 className="text-3xl font-bold">{config.labels.plural}</h1>
          </div>
          <p className="text-muted-foreground mt-2">
            Manage {config.labels.plural.toLowerCase()} items and bulk import data
          </p>
        </div>
        
        {/* Colored Seed Button */}
        <Link href={`/${itemType}/seed`}>
          <Button
            style={{
              backgroundColor: colors.hex,
              color: 'white',
            }}
            className="hover:opacity-90 transition-opacity"
          >
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
