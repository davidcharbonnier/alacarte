'use client';

import { use } from 'react';
import { useQuery } from '@tanstack/react-query';
import { notFound } from 'next/navigation';
import { isValidItemType } from '@/lib/config/item-types';
import { getItemApi } from '@/lib/api/generic-item-api';
import type { BaseItem } from '@/lib/types/item-config';
import { LoadingSpinner } from '@/components/shared/loading-spinner';
import { ErrorMessage } from '@/components/shared/error-message';
import { GenericDeleteImpact } from '@/components/shared/generic-delete-impact';

export default function ItemDeletePage({ 
  params 
}: { 
  params: Promise<{ itemType: string; id: string }> 
}) {
  const { itemType, id } = use(params);
  const itemId = parseInt(id);

  // Validate item type
  if (!isValidItemType(itemType)) {
    notFound();
  }

  const { data: item } = useQuery({
    queryKey: [itemType, 'detail', itemId],
    queryFn: () => getItemApi<BaseItem>(itemType).getById(itemId),
  });

  const { data: impact, isLoading, error } = useQuery({
    queryKey: [itemType, 'delete-impact', itemId],
    queryFn: () => getItemApi(itemType).getDeleteImpact(itemId),
  });

  if (isLoading) {
    return (
      <div className="flex items-center justify-center min-h-screen">
        <LoadingSpinner text="Analyzing delete impact..." />
      </div>
    );
  }

  if (error) {
    return (
      <div className="p-6">
        <ErrorMessage error={error as Error} />
      </div>
    );
  }

  if (!impact || !item) {
    return (
      <div className="p-6">
        <ErrorMessage error="Unable to load delete impact" />
      </div>
    );
  }

  return <GenericDeleteImpact itemType={itemType} item={item} impact={impact} />;
}
