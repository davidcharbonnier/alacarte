'use client';

import { use } from 'react';
import { useQuery } from '@tanstack/react-query';
import { notFound } from 'next/navigation';
import { useSchema, dynamicItemApi } from '@/lib/context/schema-context';
import { LoadingSpinner } from '@/components/shared/loading-spinner';
import { ErrorMessage } from '@/components/shared/error-message';
import { GenericItemDetail } from '@/components/shared/generic-item-detail';

export default function ItemDetailPage({
  params,
}: {
  params: Promise<{ itemType: string; id: string }>;
}) {
  const { itemType, id } = use(params);
  const itemId = parseInt(id);

  const { schema, isLoading: schemaLoading } = useSchema(itemType);

  const { data: item, isLoading, error } = useQuery({
    queryKey: [itemType, 'detail', itemId],
    queryFn: () => dynamicItemApi.get(itemType, itemId),
    enabled: !!schema,
  });

  if (schemaLoading) {
    return (
      <div className="flex items-center justify-center min-h-screen">
        <LoadingSpinner text="Loading schema..." />
      </div>
    );
  }

  if (!schema) {
    notFound();
  }

  if (isLoading) {
    return (
      <div className="flex items-center justify-center min-h-screen">
        <LoadingSpinner text="Loading details..." />
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

  if (!item) {
    return (
      <div className="p-6">
        <ErrorMessage error="Item not found" />
      </div>
    );
  }

  return <GenericItemDetail itemType={itemType} item={item} />;
}
