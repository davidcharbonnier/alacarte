'use client';

import { useState } from 'react';
import Link from 'next/link';
import { getItemTypeConfig } from '@/lib/config/item-types';
import { getItemTypeColor } from '@/lib/config/design-system';
import type { BaseItem } from '@/lib/types/item-config';
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
import { Eye, Trash2, CheckCircle, XCircle } from 'lucide-react';

interface GenericItemTableProps<T extends BaseItem> {
  itemType: string;
  items: T[];
}

export function GenericItemTable<T extends BaseItem>({ 
  itemType, 
  items 
}: GenericItemTableProps<T>) {
  const config = getItemTypeConfig(itemType);
  const colors = getItemTypeColor(itemType);
  const [searchTerm, setSearchTerm] = useState('');

  // Generic filtering based on searchable fields from config
  const filteredItems = items.filter((item: any) => {
    if (!searchTerm) return true;
    
    const searchLower = searchTerm.toLowerCase();
    return config.table.searchableFields.some((field: any) => {
      const value = item[field];
      return value && String(value).toLowerCase().includes(searchLower);
    });
  });

  // Get field label from config
  const getFieldLabel = (fieldKey: string): string => {
    const field = config.fields.find((f: any) => f.key === fieldKey);
    return field?.label || fieldKey;
  };

  // Get field type from config
  const getFieldType = (fieldKey: string): string => {
    const field = config.fields.find((f: any) => f.key === fieldKey);
    return field?.type || 'text';
  };

  // Format cell value based on field type
  const formatCellValue = (fieldKey: string, value: any) => {
    if (value === null || value === undefined || value === '') {
      const fieldType = getFieldType(fieldKey);
      
      // For checkbox in table, show gray X
      if (fieldType === 'checkbox') {
        return (
          <span className="flex items-center text-gray-400">
            <XCircle className="w-4 h-4" />
          </span>
        );
      }
      
      // For other fields in table, show em dash
      return <span className="text-gray-400">—</span>;
    }

    const fieldType = getFieldType(fieldKey);

    // Handle boolean/checkbox fields with icons
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

    // Default: return as string
    return value.toString();
  };

  return (
    <div className="space-y-4">
      {/* Search Input with colored focus ring */}
      <Input
        placeholder={`Search ${config.labels.plural.toLowerCase()}...`}
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
              {config.table.columns.map((column: any) => (
                <TableHead 
                  key={column}
                  className="font-semibold"
                  style={{ color: colors.hex }}
                >
                  {getFieldLabel(column)}
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
                  colSpan={config.table.columns.length + 1} 
                  className="text-center py-12"
                >
                  <div className="flex flex-col items-center gap-2">
                    <div 
                      className="w-12 h-12 rounded-full flex items-center justify-center mb-2"
                      style={{ backgroundColor: `${colors.hex}10` }}
                    >
                      <span className="text-2xl" style={{ color: colors.hex }}>∅</span>
                    </div>
                    <p className="text-muted-foreground font-medium">
                      No {config.labels.plural.toLowerCase()} found
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
              filteredItems.map((item: any, index: number) => (
                <TableRow 
                  key={item.id}
                  className="transition-colors"
                  style={{
                    backgroundColor: index % 2 === 0 ? 'transparent' : `${colors.hex}03`,
                  }}
                  onMouseEnter={(e) => {
                    e.currentTarget.style.backgroundColor = `${colors.hex}08`;
                  }}
                  onMouseLeave={(e) => {
                    e.currentTarget.style.backgroundColor = index % 2 === 0 ? 'transparent' : `${colors.hex}03`;
                  }}
                >
                  {config.table.columns.map((column: any, colIndex: number) => (
                    <TableCell 
                      key={column} 
                      className={column === 'name' ? 'font-medium' : ''}
                    >
                      {formatCellValue(column, item[column])}
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
              ))
            )}
          </TableBody>
        </Table>
      </div>

      <div className="flex items-center justify-between text-sm">
        <span className="text-muted-foreground">
          Showing {filteredItems.length} of {items.length} {config.labels.plural.toLowerCase()}
        </span>
        {filteredItems.length > 0 && (
          <span 
            className="font-medium"
            style={{ color: colors.hex }}
          >
            {filteredItems.length} result{filteredItems.length !== 1 ? 's' : ''}
          </span>
        )}
      </div>
    </div>
  );
}
