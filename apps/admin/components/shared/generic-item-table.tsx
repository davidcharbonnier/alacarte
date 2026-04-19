'use client';

import { useState } from 'react';
import Link from 'next/link';
import { useQuery } from '@tanstack/react-query';
import { useSchema, dynamicItemApi } from '@/lib/context/schema-context';
import type { SchemaField } from '@/lib/types/schema';
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from '@/components/ui/table';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Eye, Trash2, CheckCircle, XCircle, Package } from 'lucide-react';
import * as Icons from 'lucide-react';

interface GenericItemTableProps {
  itemType: string;
}

export function GenericItemTable({ itemType }: GenericItemTableProps) {
  const { schema, fields, isLoading: schemaLoading } = useSchema(itemType);
  const [searchTerm, setSearchTerm] = useState('');

  const { data: itemsData, isLoading: itemsLoading } = useQuery({
    queryKey: ['items', itemType, 'list'],
    queryFn: () => dynamicItemApi.list(itemType),
  });

  const items = itemsData?.items || [];
  const isLoading = schemaLoading || itemsLoading;

  const colors = schema ? {
    hex: schema.color,
  } : { hex: '#673AB7' };

  const tableColumns = fields
    .filter((f) => f.display?.showInTable !== false)
    .sort((a, b) => a.order - b.order)
    .slice(0, 5);

  const searchableFields = fields.filter(
    (f) => f.field_type === 'text' || f.field_type === 'textarea'
  );

  const filteredItems = items.filter((item: any) => {
    if (!searchTerm) return true;

    const searchLower = searchTerm.toLowerCase();
    return searchableFields.some((field) => {
      const value = item[field.key];
      return value && String(value).toLowerCase().includes(searchLower);
    });
  });

  const getFieldLabel = (fieldKey: string): string => {
    const field = fields.find((f) => f.key === fieldKey);
    return field?.label || fieldKey;
  };

  const getFieldType = (fieldKey: string): string => {
    const field = fields.find((f) => f.key === fieldKey);
    return field?.field_type || 'text';
  };

  const formatCellValue = (fieldKey: string, value: any) => {
    if (value === null || value === undefined || value === '') {
      const fieldType = getFieldType(fieldKey);

      if (fieldType === 'checkbox') {
        return (
          <span className="flex items-center text-gray-400">
            <XCircle className="w-4 h-4" />
          </span>
        );
      }

      return <span className="text-gray-400">—</span>;
    }

    const fieldType = getFieldType(fieldKey);

    if (fieldType === 'checkbox') {
      return value ? (
        <span className="flex items-center text-green-600">
          <CheckCircle className="w-4 h-4" />
        </span>
      ) : (
        <span className="flex items-center text-gray-400">
          <XCircle className="w-4 h-4" />
        </span>
      );
    }

    if (fieldType === 'select' || fieldType === 'enum') {
      const field = fields.find((f) => f.key === fieldKey);
      const option = field?.options?.find((o) => o.value === value);
      return option?.label || value;
    }

    return value.toString();
  };

  if (isLoading) {
    return (
      <div className="flex items-center justify-center py-12">
        <div className="animate-pulse text-muted-foreground">
          Loading {schema?.display_name || itemType}...
        </div>
      </div>
    );
  }

  if (!schema) {
    return (
      <div className="text-center py-12 text-muted-foreground">
        Schema not found for type: {itemType}
      </div>
    );
  }

  return (
    <div className="space-y-4">
      <Input
        placeholder={`Search ${schema.plural_name.toLowerCase()}...`}
        value={searchTerm}
        onChange={(e) => setSearchTerm(e.target.value)}
        className="max-w-md focus-visible:ring-offset-0"
        style={{
          '--tw-ring-color': colors.hex,
        } as React.CSSProperties}
      />

      <div className="rounded-md border" style={{ borderColor: `${colors.hex}20` }}>
        <Table>
          <TableHeader>
            <TableRow className="hover:bg-transparent">
              <TableHead
                className="font-semibold w-20"
                style={{ color: colors.hex }}
              >
                Image
              </TableHead>
              {tableColumns.map((field) => (
                <TableHead
                  key={field.key}
                  className="font-semibold"
                  style={{ color: colors.hex }}
                >
                  {field.label}
                </TableHead>
              ))}
              <TableHead
                className="text-right font-semibold"
                style={{ color: colors.hex }}
              >
                Actions
              </TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {filteredItems.length === 0 ? (
              <TableRow className="hover:bg-transparent">
                <TableCell
                  colSpan={tableColumns.length + 2}
                  className="text-center py-12"
                >
                  <div className="flex flex-col items-center gap-2">
                    <div
                      className="w-12 h-12 rounded-full flex items-center justify-center mb-2"
                      style={{ backgroundColor: `${colors.hex}10` }}
                    >
                      <span className="text-2xl" style={{ color: colors.hex }}>
                        ∅
                      </span>
                    </div>
                    <p className="text-muted-foreground font-medium">
                      No {schema.plural_name.toLowerCase()} found
                    </p>
                    {searchTerm && (
                      <p className="text-sm text-muted-foreground">
                        Try adjusting your search term
                      </p>
                    )}
                  </div>
                </TableCell>
              </TableRow>
            ) : (
              filteredItems.map((item: any, index: number) => {
                const IconComponent =
                  (Icons as any)[schema.icon] || Icons.HelpCircle;
                return (
                  <TableRow
                    key={item.id}
                    className="transition-colors"
                    style={{
                      backgroundColor:
                        index % 2 === 0 ? 'transparent' : `${colors.hex}03`,
                    }}
                    onMouseEnter={(e) => {
                      e.currentTarget.style.backgroundColor = `${colors.hex}08`;
                    }}
                    onMouseLeave={(e) => {
                      e.currentTarget.style.backgroundColor =
                        index % 2 === 0 ? 'transparent' : `${colors.hex}03`;
                    }}
                  >
                    <TableCell>
                      {item.image_url ? (
                        <div className="relative w-12 h-12 rounded-md overflow-hidden bg-gray-100">
                          <img
                            src={item.image_url}
                            alt={item.name}
                            className="w-full h-full object-cover"
                          />
                        </div>
                      ) : (
                        <div
                          className="w-12 h-12 rounded-md flex items-center justify-center"
                          style={{ backgroundColor: `${colors.hex}10` }}
                        >
                          <Package
                            className="w-6 h-6"
                            style={{ color: `${colors.hex}40` }}
                          />
                        </div>
                      )}
                    </TableCell>
                    {tableColumns.map((field) => (
                      <TableCell
                        key={field.key}
                        className={
                          field.display?.primary ? 'font-medium' : ''
                        }
                      >
                        {formatCellValue(field.key, item[field.key])}
                      </TableCell>
                    ))}
                    <TableCell className="text-right space-x-2">
                      <Link href={`/${itemType}/${item.id}`}>
                        <Button
                          variant="ghost"
                          size="sm"
                          className="hover:bg-transparent"
                          style={{ color: colors.hex }}
                        >
                          <Eye className="w-4 h-4 mr-1" />
                          View
                        </Button>
                      </Link>
                      <Link href={`/${itemType}/${item.id}/delete`}>
                        <Button
                          variant="ghost"
                          size="sm"
                          className="text-destructive hover:text-destructive hover:bg-destructive/10"
                        >
                          <Trash2 className="w-4 h-4 mr-1" />
                          Delete
                        </Button>
                      </Link>
                    </TableCell>
                  </TableRow>
                );
              })
            )}
          </TableBody>
        </Table>
      </div>

      <div className="flex items-center justify-between text-sm">
        <span className="text-muted-foreground">
          Showing {filteredItems.length} of {items.length}{' '}
          {schema.plural_name.toLowerCase()}
        </span>
        {filteredItems.length > 0 && (
          <span className="font-medium" style={{ color: colors.hex }}>
            {filteredItems.length} result{filteredItems.length !== 1 ? 's' : ''}
          </span>
        )}
      </div>
    </div>
  );
}
