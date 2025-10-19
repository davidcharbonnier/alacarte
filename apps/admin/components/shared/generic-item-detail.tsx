'use client';

import { useState } from 'react';
import Link from 'next/link';
import { getItemTypeConfig } from '@/lib/config/item-types';
import { getItemTypeColor } from '@/lib/config/design-system';
import type { BaseItem } from '@/lib/types/item-config';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Dialog, DialogContent, DialogTrigger, DialogTitle } from '@/components/ui/dialog';
import { ArrowLeft, Trash2, CheckCircle, XCircle, Package, Expand } from 'lucide-react';
import * as Icons from 'lucide-react';

interface GenericItemDetailProps<T extends BaseItem> {
  itemType: string;
  item: T;
}

export function GenericItemDetail<T extends BaseItem>({ 
  itemType, 
  item 
}: GenericItemDetailProps<T>) {
  const config = getItemTypeConfig(itemType);
  const colors = getItemTypeColor(itemType);
  const IconComponent = (Icons as any)[config.icon] || Icons.HelpCircle;
  const [imageZoomOpen, setImageZoomOpen] = useState(false);

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
    <div className="space-y-6">
      {/* Colored Header */}
      <div className="flex justify-between items-start">
        <div>
          <Link href={`/${itemType}`}>
            <Button 
              variant="ghost" 
              size="sm"
              className="mb-4 hover:bg-transparent"
              style={{ color: colors.hex }}
            >
              <ArrowLeft className="w-4 h-4 mr-2" />
              Back to {config.labels.plural}
            </Button>
          </Link>
          
          <div className="flex items-center gap-3">
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
            <h1 className="text-3xl font-bold">{item.name}</h1>
          </div>
        </div>
        
        <Link href={`/${itemType}/${item.id}/delete`}>
          <Button variant="destructive">
            <Trash2 className="w-4 h-4 mr-2" />
            Delete {config.labels.singular}
          </Button>
        </Link>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Basic Information Card with colored border */}
        <Card 
          className="border-l-4"
          style={{ borderLeftColor: colors.hex }}
        >
          <CardHeader>
            <CardTitle style={{ color: colors.hex }}>Basic Information</CardTitle>
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
          <Card 
            className="border-l-4"
            style={{ borderLeftColor: colors.hex }}
          >
            <CardHeader>
              <CardTitle style={{ color: colors.hex }}>{descriptionField.label}</CardTitle>
              <CardDescription>Additional information</CardDescription>
            </CardHeader>
            <CardContent>
              <p className="text-foreground leading-relaxed">
                {item[descriptionField.key] || (
                  <span className="text-muted-foreground italic">No description available</span>
                )}
              </p>
            </CardContent>
          </Card>
        )}

        {/* Image Card */}
        <Card 
          className="border-l-4"
          style={{ borderLeftColor: colors.hex }}
        >
          <CardHeader>
            <CardTitle style={{ color: colors.hex }}>Image</CardTitle>
            <CardDescription>Product photo</CardDescription>
          </CardHeader>
          <CardContent>
            {item.image_url ? (
              <Dialog open={imageZoomOpen} onOpenChange={setImageZoomOpen}>
                <DialogTrigger asChild>
                  <div className="relative w-full rounded-lg overflow-hidden bg-gray-100 cursor-pointer group">
                    <img
                      src={item.image_url}
                      alt={item.name}
                      className="w-full h-auto object-contain transition-opacity group-hover:opacity-90"
                    />
                    {/* Zoom overlay hint */}
                    <div className="absolute inset-0 bg-black/0 group-hover:bg-black/10 transition-colors flex items-center justify-center">
                      <div className="opacity-0 group-hover:opacity-100 transition-opacity">
                        <div 
                          className="rounded-full p-3"
                          style={{ backgroundColor: colors.hex }}
                        >
                          <Expand className="w-6 h-6 text-white" />
                        </div>
                      </div>
                    </div>
                  </div>
                </DialogTrigger>
                <DialogContent className="max-w-4xl w-[90vw] p-0 bg-black [&>button]:bg-white/90 [&>button]:hover:bg-white [&>button]:text-gray-800" showCloseButton={true}>
                  <DialogTitle className="sr-only">{item.name} - Full Size Image</DialogTitle>
                  <div className="relative w-full">
                    <img
                      src={item.image_url}
                      alt={item.name}
                      className="w-full h-auto object-contain max-h-[85vh]"
                    />
                  </div>
                </DialogContent>
              </Dialog>
            ) : (
              <div 
                className="w-full h-48 rounded-lg flex items-center justify-center"
                style={{ backgroundColor: `${colors.hex}10` }}
              >
                <div className="text-center">
                  <Package 
                    className="w-12 h-12 mx-auto mb-2"
                    style={{ color: `${colors.hex}40` }}
                  />
                  <p className="text-sm text-muted-foreground">No image</p>
                </div>
              </div>
            )}
          </CardContent>
        </Card>
      </div>

      <Card className="mt-6">
        <CardHeader>
          <CardTitle style={{ color: colors.hex }}>Metadata</CardTitle>
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
