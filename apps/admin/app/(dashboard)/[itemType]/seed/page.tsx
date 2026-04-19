'use client';

import { use } from 'react';
import { notFound } from 'next/navigation';
import { useSchema } from '@/lib/context/schema-context';
import { GenericSeedForm } from '@/components/shared/generic-seed-form';
import { LoadingSpinner } from '@/components/shared/loading-spinner';

export default function ItemSeedPage({
  params,
}: {
  params: Promise<{ itemType: string }>;
}) {
  const { itemType } = use(params);

  const { schema, isLoading } = useSchema(itemType);

  if (isLoading) {
    return <LoadingSpinner text="Loading schema..." />;
  }

  if (!schema) {
    notFound();
  }

  return <GenericSeedForm itemType={itemType} />;
}
