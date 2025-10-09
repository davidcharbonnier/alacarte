'use client';

import { useState } from 'react';
import Link from 'next/link';
import { getItemTypeConfig } from '@/lib/config/item-types';
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
import { Eye, Trash2 } from 'lucide-react';

interface GenericItemTableProps<T extends BaseItem> {
  itemType: string;
  items: T[];
}

export function GenericItemTable<T extends BaseItem>({ 
  itemType, 
  items 
}: GenericItemTableProps<T>) {
  const config = getItemTypeConfig(itemType);
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

  return (
    <div className="space-y-4">
      <Input
        placeholder={`Search ${config.labels.plural.toLowerCase()}...`}
        value={searchTerm}
        onChange={(e) => setSearchTerm(e.target.value)}
        className="max-w-md"
      />

      <div className="rounded-md border">
        <Table>
          <TableHeader>
            <TableRow>
              {config.table.columns.map((column: any) => (
                <TableHead key={column}>{getFieldLabel(column)}</TableHead>
              ))}
              <TableHead className="text-right">Actions</TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {filteredItems.length === 0 ? (
              <TableRow>
                <TableCell colSpan={config.table.columns.length + 1} className="text-center text-gray-500">
                  No {config.labels.plural.toLowerCase()} found
                </TableCell>
              </TableRow>
            ) : (
              filteredItems.map((item: any) => (
                <TableRow key={item.id}>
                  {config.table.columns.map((column: any) => (
                    <TableCell key={column} className={column === 'name' ? 'font-medium' : ''}>
                      {item[column] || '-'}
                    </TableCell>
                  ))}
                  <TableCell className="text-right space-x-2">
                    <Link href={`/${itemType}/${item.id}`}>
                      <Button variant="ghost" size="sm">
                        <Eye className="w-4 h-4 mr-1" />
                        View
                      </Button>
                    </Link>
                    <Link href={`/${itemType}/${item.id}/delete`}>
                      <Button variant="ghost" size="sm" className="text-red-600 hover:text-red-700">
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

      <div className="text-sm text-gray-600">
        Showing {filteredItems.length} of {items.length} {config.labels.plural.toLowerCase()}
      </div>
    </div>
  );
}
