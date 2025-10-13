'use client';

import Link from 'next/link';
import { getItemTypeConfig } from '@/lib/config/item-types';
import type { BaseItem } from '@/lib/types/item-config';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { ArrowLeft, Trash2, CheckCircle, XCircle } from 'lucide-react';

interface GenericItemDetailProps<T extends BaseItem> {
  itemType: string;
  item: T;
}

export function GenericItemDetail<T extends BaseItem>({ 
  itemType, 
  item 
}: GenericItemDetailProps<T>) {
  const config = getItemTypeConfig(itemType);

  // Split fields into main fields and description
  const mainFields = config.fields.filter((f: any) => f.type !== 'textarea');
  const descriptionField = config.fields.find((f: any) => f.type === 'textarea');

  // Format field value based on type
  const formatFieldValue = (field: any, value: any) => {
    if (value === null || value === undefined || value === '') {
      // For checkbox/boolean, show "No" explicitly
      if (field.type === 'checkbox') {
        return (
          <span className="flex items-center text-gray-400">
            <XCircle className="w-5 h-5 mr-2" />
            No
          </span>
        );
      }
      // For other fields, show muted "Not specified"
      return <span className="text-gray-400 italic">Not specified</span>;
    }

    // Handle boolean/checkbox fields with icons
    if (field.type === 'checkbox') {
      return value ? (
        <span className="flex items-center text-green-600">
          <CheckCircle className="w-5 h-5 mr-2" />
          Yes
        </span>
      ) : (
        <span className="flex items-center text-gray-400">
          <XCircle className="w-5 h-5 mr-2" />
          No
        </span>
      );
    }

    // Handle number fields
    if (field.type === 'number') {
      return value.toString();
    }

    // Default: return as string
    return value.toString();
  };

  return (
    <div>
      <div className="flex justify-between items-center mb-6">
        <div className="flex items-center space-x-4">
          <Link href={`/${itemType}`}>
            <Button variant="ghost" size="sm">
              <ArrowLeft className="w-4 h-4 mr-2" />
              Back to List
            </Button>
          </Link>
          <h1 className="text-3xl font-bold text-gray-900">{item.name}</h1>
        </div>
        <Link href={`/${itemType}/${item.id}/delete`}>
          <Button variant="destructive">
            <Trash2 className="w-4 h-4 mr-2" />
            Delete {config.labels.singular}
          </Button>
        </Link>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <Card>
          <CardHeader>
            <CardTitle>Basic Information</CardTitle>
            <CardDescription>Details about this {config.labels.singular.toLowerCase()}</CardDescription>
          </CardHeader>
          <CardContent className="space-y-4">
            {mainFields.map((field: any) => (
              <div key={field.key}>
                <label className="text-sm font-medium text-gray-500">
                  {field.label}
                </label>
                <p className="text-lg">
                  {formatFieldValue(field, item[field.key])}
                </p>
              </div>
            ))}
          </CardContent>
        </Card>

        {descriptionField && (
          <Card>
            <CardHeader>
              <CardTitle>{descriptionField.label}</CardTitle>
              <CardDescription>Additional information</CardDescription>
            </CardHeader>
            <CardContent>
              <p className="text-gray-700">
                {item[descriptionField.key] || 'No description available'}
              </p>
            </CardContent>
          </Card>
        )}
      </div>

      <Card className="mt-6">
        <CardHeader>
          <CardTitle>Metadata</CardTitle>
          <CardDescription>System information</CardDescription>
        </CardHeader>
        <CardContent className="space-y-2">
          <div className="flex justify-between">
            <span className="text-sm text-gray-500">ID:</span>
            <span className="text-sm font-medium">{item.id}</span>
          </div>
          <div className="flex justify-between">
            <span className="text-sm text-gray-500">Created:</span>
            <span className="text-sm font-medium">
              {new Date(item.created_at).toLocaleString()}
            </span>
          </div>
          <div className="flex justify-between">
            <span className="text-sm text-gray-500">Updated:</span>
            <span className="text-sm font-medium">
              {new Date(item.updated_at).toLocaleString()}
            </span>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
