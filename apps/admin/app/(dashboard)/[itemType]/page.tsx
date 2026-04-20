'use client';

import { use } from 'react';
import { notFound } from 'next/navigation';
import Link from 'next/link';
import { useSchema } from '@/lib/context/schema-context';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { LoadingSpinner } from '@/components/shared/loading-spinner';
import { ErrorMessage } from '@/components/shared/error-message';
import { GenericItemTable } from '@/components/shared/generic-item-table';
import { Plus } from 'lucide-react';
import * as Icons from 'lucide-react';

export default function ItemListPage({
  params,
}: {
  params: Promise<{ itemType: string }>;
}) {
  const { itemType } = use(params);
  const { schema, isLoading, error } = useSchema(itemType);

  if (isLoading) {
    return <LoadingSpinner text="Loading schema..." />;
  }

  if (error) {
    return <ErrorMessage error={error} />;
  }

  if (!schema) {
    notFound();
  }

  const colors = { hex: schema.color };
  const IconComponent = (Icons as any)[schema.icon] || Icons.HelpCircle;

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-start">
        <div>
          <div className="flex items-center gap-3 mb-2">
            <div
              className="flex items-center justify-center w-12 h-12 rounded-xl"
              style={{ backgroundColor: `${colors.hex}20` }}
            >
              <IconComponent
                className="w-6 h-6"
                style={{ color: colors.hex }}
              />
            </div>
            <h1 className="text-3xl font-bold">{schema.plural_name}</h1>
          </div>
          <p className="text-muted-foreground mt-2">
            Manage {schema.plural_name.toLowerCase()} items and bulk import data
          </p>
        </div>

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
          <CardTitle>All {schema.plural_name}</CardTitle>
          <CardDescription>
            View and manage all {schema.plural_name.toLowerCase()} in the database
          </CardDescription>
        </CardHeader>
        <CardContent>
          <GenericItemTable itemType={itemType} />
        </CardContent>
      </Card>
    </div>
  );
}
