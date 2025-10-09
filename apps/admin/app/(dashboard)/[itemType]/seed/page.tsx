'use client';

import { use } from 'react';
import { notFound } from 'next/navigation';
import { isValidItemType } from '@/lib/config/item-types';
import { GenericSeedForm } from '@/components/shared/generic-seed-form';

export default function ItemSeedPage({ 
  params 
}: { 
  params: Promise<{ itemType: string }> 
}) {
  const { itemType } = use(params);

  // Validate item type
  if (!isValidItemType(itemType)) {
    notFound();
  }

  return <GenericSeedForm itemType={itemType} />;
}
