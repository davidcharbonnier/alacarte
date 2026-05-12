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
import { Eye, Trash2, CheckCircle, XCircle, Package, Image, ChevronLeft, ChevronRight, ArrowUpDown, ArrowUp, ArrowDown } from 'lucide-react';
import * as Icons from 'lucide-react';

interface GenericItemTableProps {
  itemType: string;
}

const getFieldValue = (item: any, fieldKey: string): any => {
  if (fieldKey === 'image_url') return item.image_url;
  if (fieldKey === 'id') return item.id;
  if (fieldKey === 'name') return item.name ?? item.field_values?.name;
  return item.field_values?.[fieldKey];
};

const PAGE_SIZE = 20;

export function GenericItemTable({ itemType }: GenericItemTableProps) {
  const { schema, fields, isLoading: schemaLoading } = useSchema(itemType);
  const [searchTerm, setSearchTerm] = useState('');
  const [debouncedSearch, setDebouncedSearch] = useState('');
  const [page, setPage] = useState(1);
  const [hasImageFilter, setHasImageFilter] = useState<boolean | undefined>(undefined);
  const [sortField, setSortField] = useState<string>('name');
  const [sortDir, setSortDir] = useState<'asc' | 'desc'>('asc');

  // Debounce search input
  const handleSearchChange = (value: string) => {
    setSearchTerm(value);
    setPage(1);
    const timeout = setTimeout(() => setDebouncedSearch(value), 300);
    return () => clearTimeout(timeout);
  };

  const sortParam = sortDir === 'desc' ? `-${sortField}` : sortField;

  const { data: itemsData, isLoading: itemsLoading } = useQuery({
    queryKey: ['items', itemType, 'list', page, debouncedSearch, hasImageFilter, sortParam],
    queryFn: () =>
      dynamicItemApi.list(itemType, {
        page,
        page_size: PAGE_SIZE,
        search: debouncedSearch || undefined,
        has_image: hasImageFilter,
        sort: sortParam,
      }),
  });

  const items = itemsData?.items || [];
  const total = itemsData?.total || 0;
  const totalPages = itemsData?.total_pages || 1;
  const isLoading = schemaLoading || itemsLoading;

  const colors = schema ? {
    hex: schema.color,
  } : { hex: '#673AB7' };

  const uniqueFields = schema?.unique_fields || [];
  const tableColumns = (uniqueFields.length > 0
    ? fields.filter((f) => uniqueFields.includes(f.key))
        .sort((a, b) => {
          const aIndex = uniqueFields.indexOf(a.key);
          const bIndex = uniqueFields.indexOf(b.key);
          return aIndex - bIndex;
        })
    : fields.sort((a, b) => a.order - b.order)
  ).slice(0, 5);

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

  const handleSort = (fieldKey: string) => {
    if (sortField === fieldKey) {
      setSortDir(sortDir === 'asc' ? 'desc' : 'asc');
    } else {
      setSortField(fieldKey);
      setSortDir('asc');
    }
    setPage(1);
  };

  const SortIcon = ({ fieldKey }: { fieldKey: string }) => {
    if (sortField !== fieldKey) return <ArrowUpDown className="w-3 h-3 ml-1 opacity-40" />;
    return sortDir === 'asc'
      ? <ArrowUp className="w-3 h-3 ml-1" />
      : <ArrowDown className="w-3 h-3 ml-1" />;
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
      <div className="flex items-center gap-3">
        <Input
          placeholder={`Search ${schema.plural_name.toLowerCase()}...`}
          value={searchTerm}
          onChange={(e) => handleSearchChange(e.target.value)}
          className="max-w-md focus-visible:ring-offset-0"
          style={{
            '--tw-ring-color': colors.hex,
          } as React.CSSProperties}
        />
        <Button
          variant={hasImageFilter === true ? 'default' : 'outline'}
          size="sm"
          onClick={() => {
            setHasImageFilter(hasImageFilter === true ? undefined : true);
            setPage(1);
          }}
          className="gap-1"
        >
          <Image className="w-4 h-4" />
          Has Image
        </Button>
        <Button
          variant={hasImageFilter === false ? 'default' : 'outline'}
          size="sm"
          onClick={() => {
            setHasImageFilter(hasImageFilter === false ? undefined : false);
            setPage(1);
          }}
          className="gap-1"
        >
          <Package className="w-4 h-4" />
          No Image
        </Button>
      </div>

      <div className="rounded-md border" style={{ borderColor: `${colors.hex}20` }}>
        <Table>
          <TableHeader>
            <TableRow className="hover:bg-transparent">
              <TableHead
                className="font-semibold w-20 cursor-pointer"
                style={{ color: colors.hex }}
                onClick={() => handleSort('name')}
              >
                <span className="flex items-center">
                  Name
                  <SortIcon fieldKey="name" />
                </span>
              </TableHead>
              {tableColumns.map((field) => (
                <TableHead
                  key={field.key}
                  className="font-semibold cursor-pointer"
                  style={{ color: colors.hex }}
                  onClick={() => handleSort(field.key)}
                >
                  <span className="flex items-center">
                    {field.label}
                    <SortIcon fieldKey={field.key} />
                  </span>
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
            {items.length === 0 ? (
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
                    {(searchTerm || hasImageFilter !== undefined) && (
                      <p className="text-sm text-muted-foreground">
                        Try adjusting your filters
                      </p>
                    )}
                  </div>
                </TableCell>
              </TableRow>
            ) : (
              items.map((item: any, index: number) => {
                const IconComponent =
                  (Icons as any)[schema.icon] || Icons.HelpCircle;
                const itemName = getFieldValue(item, 'name') || `Item #${item.id}`;
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
                      <div className="flex items-center gap-3">
                        {item.image_url ? (
                          <div className="relative w-10 h-10 rounded-md overflow-hidden bg-gray-100 flex-shrink-0">
                            <img
                              src={item.image_url}
                              alt={itemName}
                              className="w-full h-full object-cover"
                            />
                          </div>
                        ) : (
                          <div
                            className="w-10 h-10 rounded-md flex items-center justify-center flex-shrink-0"
                            style={{ backgroundColor: `${colors.hex}10` }}
                          >
                            <Package
                              className="w-5 h-5"
                              style={{ color: `${colors.hex}40` }}
                            />
                          </div>
                        )}
                        <span className="font-medium">{itemName}</span>
                      </div>
                    </TableCell>
                    {tableColumns.map((field) => (
                      <TableCell key={field.key}>
                        {formatCellValue(field.key, getFieldValue(item, field.key))}
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
          Showing {items.length} of {total} {schema.plural_name.toLowerCase()}
        </span>
        <div className="flex items-center gap-2">
          <Button
            variant="outline"
            size="sm"
            onClick={() => setPage((p) => Math.max(1, p - 1))}
            disabled={page <= 1}
          >
            <ChevronLeft className="w-4 h-4" />
          </Button>
          <span className="text-muted-foreground">
            Page {page} of {totalPages}
          </span>
          <Button
            variant="outline"
            size="sm"
            onClick={() => setPage((p) => Math.min(totalPages, p + 1))}
            disabled={page >= totalPages}
          >
            <ChevronRight className="w-4 h-4" />
          </Button>
        </div>
      </div>
    </div>
  );
}
