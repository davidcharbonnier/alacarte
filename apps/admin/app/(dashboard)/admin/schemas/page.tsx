'use client';

import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import Link from 'next/link';
import { schemaApi } from '@/lib/api/schema-api';
import type { ItemTypeSchema } from '@/lib/types/schema';
import { Button } from '@/components/ui/button';
import { Card, CardContent } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { LoadingSpinner } from '@/components/shared/loading-spinner';
import { ErrorMessage } from '@/components/shared/error-message';
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from '@/components/ui/table';
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from '@/components/ui/dialog';
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Plus, Pencil, Trash2, Shield, Eye, EyeOff } from 'lucide-react';
import { useState } from 'react';
import * as Icons from 'lucide-react';
import { useForm } from 'react-hook-form';

type CreateSchemaFormData = {
  name: string;
  display_name: string;
  plural_name: string;
  icon: string;
  color: string;
};

const ICON_OPTIONS = [
  { value: 'Pizza', label: 'Pizza (Cheese)' },
  { value: 'Wine', label: 'Wine' },
  { value: 'Coffee', label: 'Coffee' },
  { value: 'Flame', label: 'Flame (Hot Sauce)' },
  { value: 'Beer', label: 'Beer' },
  { value: 'Apple', label: 'Apple' },
  { value: 'Cake', label: 'Cake' },
  { value: 'Cookie', label: 'Cookie' },
  { value: 'Cup', label: 'Cup (Tea)' },
  { value: 'Fish', label: 'Fish' },
  { value: 'Salad', label: 'Salad' },
  { value: 'IceCream', label: 'Ice Cream' },
];

const COLOR_OPTIONS = [
  { value: '#E67E22', label: 'Orange' },
  { value: '#9B59B6', label: 'Purple' },
  { value: '#E74C3C', label: 'Red' },
  { value: '#3498DB', label: 'Blue' },
  { value: '#1ABC9C', label: 'Teal' },
  { value: '#27AE60', label: 'Green' },
  { value: '#F39C12', label: 'Yellow' },
  { value: '#2C3E50', label: 'Dark' },
];

export default function SchemaListPage() {
  const queryClient = useQueryClient();
  const [isCreateOpen, setIsCreateOpen] = useState(false);
  const [deleteTarget, setDeleteTarget] = useState<ItemTypeSchema | null>(null);

  const { data: schemas = [], isLoading, error } = useQuery({
    queryKey: ['schemas', 'all'],
    queryFn: async () => {
      try {
        const result = await schemaApi.list(true);
        return result ?? [];
      } catch {
        return [];
      }
    },
  });

  const createMutation = useMutation({
    mutationFn: (data: CreateSchemaFormData) =>
      schemaApi.create({
        ...data,
        is_active: true,
        fields: [],
      }),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['schemas'] });
      setIsCreateOpen(false);
    },
  });

  const deleteMutation = useMutation({
    mutationFn: (type: string) => schemaApi.delete(type),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['schemas'] });
      setDeleteTarget(null);
    },
  });

  const toggleActiveMutation = useMutation({
    mutationFn: ({ type, isActive }: { type: string; isActive: boolean }) =>
      schemaApi.update(type, { is_active: isActive }),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['schemas'] });
    },
  });

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between mb-6">
        <div className="flex items-center gap-3">
          <div className="flex items-center justify-center w-12 h-12 rounded-xl bg-primary/10">
            <Shield className="w-6 h-6 text-primary" />
          </div>
          <div>
            <h1 className="text-3xl font-bold text-gray-900">Schema Management</h1>
            <p className="text-gray-600 mt-1">
              {schemas.length} schema{schemas.length !== 1 ? 's' : ''} defined
            </p>
          </div>
        </div>

        <Dialog open={isCreateOpen} onOpenChange={setIsCreateOpen}>
          <DialogTrigger asChild>
            <Button>
              <Plus className="w-4 h-4 mr-2" />
              Create Schema
            </Button>
          </DialogTrigger>
          <DialogContent className="sm:max-w-[480px]">
            <DialogHeader>
              <DialogTitle>Create New Schema</DialogTitle>
              <DialogDescription>
                Define a new item type schema with custom fields
              </DialogDescription>
            </DialogHeader>
            <CreateSchemaForm
              onSubmit={(data) => createMutation.mutate(data)}
              isLoading={createMutation.isPending}
            />
          </DialogContent>
        </Dialog>
      </div>

      <Card>
        <CardContent className="p-0">
          {isLoading && <LoadingSpinner text="Loading schemas..." />}
          {error && <ErrorMessage error={error as Error} />}
          {schemas.length === 0 ? (
            <div className="text-center py-12">
              <div className="flex flex-col items-center gap-2">
                <div className="w-12 h-12 rounded-full flex items-center justify-center bg-muted mb-2">
                  <Shield className="w-6 h-6 text-muted-foreground" />
                </div>
                <p className="text-muted-foreground font-medium">
                  No schemas found
                </p>
                <p className="text-sm text-muted-foreground">
                  Create your first schema to get started
                </p>
              </div>
            </div>
          ) : (
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead className="w-12">Icon</TableHead>
                  <TableHead>Name</TableHead>
                  <TableHead>Display Name</TableHead>
                  <TableHead>Fields</TableHead>
                  <TableHead>Status</TableHead>
                  <TableHead className="text-right">Actions</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {schemas.map((schema) => {
                  const IconComponent =
                    (Icons as any)[schema.icon] || Icons.HelpCircle;
                  return (
                    <TableRow key={schema.id}>
                      <TableCell>
                        <div
                          className="flex items-center justify-center w-10 h-10 rounded-lg"
                          style={{
                            backgroundColor: `${schema.color}20`,
                          }}
                        >
                          <IconComponent
                            className="w-5 h-5"
                            style={{ color: schema.color }}
                          />
                        </div>
                      </TableCell>
                      <TableCell className="font-medium">
                        {schema.name}
                      </TableCell>
                      <TableCell>{schema.display_name}</TableCell>
                      <TableCell>
                        <Badge variant="secondary">
                          {schema.fields?.length || 0} fields
                        </Badge>
                      </TableCell>
                      <TableCell>
                        {schema.is_active ? (
                          <Badge
                            className="bg-green-100 text-green-800 hover:bg-green-100"
                            onClick={() =>
                              toggleActiveMutation.mutate({
                                type: schema.name,
                                isActive: false,
                              })
                            }
                          >
                            <Eye className="w-3 h-3 mr-1" />
                            Active
                          </Badge>
                        ) : (
                          <Badge
                            variant="outline"
                            className="text-muted-foreground cursor-pointer hover:bg-muted"
                            onClick={() =>
                              toggleActiveMutation.mutate({
                                type: schema.name,
                                isActive: true,
                              })
                            }
                          >
                            <EyeOff className="w-3 h-3 mr-1" />
                            Inactive
                          </Badge>
                        )}
                      </TableCell>
                      <TableCell className="text-right space-x-2">
                        <Link href={`/admin/schemas/${schema.name}`}>
                          <Button variant="ghost" size="sm">
                            <Pencil className="w-4 h-4 mr-1" />
                            Edit
                          </Button>
                        </Link>
                        <Button
                          variant="ghost"
                          size="sm"
                          className="text-destructive hover:text-destructive hover:bg-destructive/10"
                          onClick={() => setDeleteTarget(schema)}
                        >
                          <Trash2 className="w-4 h-4 mr-1" />
                          Delete
                        </Button>
                      </TableCell>
                    </TableRow>
                  );
                })}
              </TableBody>
            </Table>
          )}
        </CardContent>
      </Card>

      <Dialog open={!!deleteTarget} onOpenChange={() => setDeleteTarget(null)}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Delete Schema</DialogTitle>
            <DialogDescription>
              Are you sure you want to delete the schema &quot;{deleteTarget?.display_name}&quot;?
              This action cannot be undone and will delete all associated items.
            </DialogDescription>
          </DialogHeader>
          <DialogFooter>
            <Button variant="outline" onClick={() => setDeleteTarget(null)}>
              Cancel
            </Button>
            <Button
              variant="destructive"
              onClick={() =>
                deleteTarget && deleteMutation.mutate(deleteTarget.name)
              }
              disabled={deleteMutation.isPending}
            >
              {deleteMutation.isPending ? 'Deleting...' : 'Delete'}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}

function CreateSchemaForm({
  onSubmit,
  isLoading,
}: {
  onSubmit: (data: CreateSchemaFormData) => void;
  isLoading: boolean;
}) {
  const { register, handleSubmit, setValue, watch } = useForm<CreateSchemaFormData>({
    defaultValues: {
      name: '',
      display_name: '',
      plural_name: '',
      icon: 'Pizza',
      color: '#E67E22',
    },
  });

  const selectedIcon = watch('icon');
  const selectedColor = watch('color');

  return (
    <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
      <div className="grid grid-cols-2 gap-4">
        <div className="space-y-2">
          <Label htmlFor="name">Schema Name</Label>
          <Input
            id="name"
            placeholder="e.g., cheese, wine"
            {...register('name', { required: true })}
          />
          <p className="text-xs text-muted-foreground">
            Unique identifier (lowercase, no spaces)
          </p>
        </div>
        <div className="space-y-2">
          <Label htmlFor="icon">Icon</Label>
          <Select
            value={selectedIcon}
            onValueChange={(value) => setValue('icon', value)}
          >
            <SelectTrigger>
              <SelectValue />
            </SelectTrigger>
            <SelectContent>
              {ICON_OPTIONS.map((opt) => (
                <SelectItem key={opt.value} value={opt.value}>
                  {opt.label}
                </SelectItem>
              ))}
            </SelectContent>
          </Select>
        </div>
      </div>

      <div className="grid grid-cols-2 gap-4">
        <div className="space-y-2">
          <Label htmlFor="display_name">Display Name</Label>
          <Input
            id="display_name"
            placeholder="e.g., Cheese"
            {...register('display_name', { required: true })}
          />
        </div>
        <div className="space-y-2">
          <Label htmlFor="plural_name">Plural Name</Label>
          <Input
            id="plural_name"
            placeholder="e.g., Cheeses"
            {...register('plural_name', { required: true })}
          />
        </div>
      </div>

      <div className="space-y-2">
        <Label htmlFor="color">Color</Label>
        <Select
          value={selectedColor}
          onValueChange={(value) => setValue('color', value)}
        >
          <SelectTrigger>
            <SelectValue />
          </SelectTrigger>
          <SelectContent>
            {COLOR_OPTIONS.map((opt) => (
              <SelectItem key={opt.value} value={opt.value}>
                <div className="flex items-center gap-2">
                  <div
                    className="w-4 h-4 rounded"
                    style={{ backgroundColor: opt.value }}
                  />
                  {opt.label}
                </div>
              </SelectItem>
            ))}
          </SelectContent>
        </Select>
      </div>

      <div className="flex items-center gap-4 p-4 bg-muted rounded-lg">
        <div
          className="flex items-center justify-center w-12 h-12 rounded-xl"
          style={{
            backgroundColor: `${selectedColor}20`,
          }}
        >
          {(() => {
            const IconComponent =
              (Icons as any)[selectedIcon] || Icons.HelpCircle;
            return (
              <IconComponent
                className="w-6 h-6"
                style={{ color: selectedColor }}
              />
            );
          })()}
        </div>
        <div>
          <p className="font-medium">Preview</p>
          <p className="text-sm text-muted-foreground">
            How your schema will appear in navigation
          </p>
        </div>
      </div>

      <DialogFooter>
        <Button type="submit" disabled={isLoading}>
          {isLoading ? 'Creating...' : 'Create Schema'}
        </Button>
      </DialogFooter>
    </form>
  );
}
