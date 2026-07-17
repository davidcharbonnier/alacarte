import { createContext, useContext, type ReactNode } from 'react';
import { useQuery } from '@tanstack/react-query';
import { schemaApi } from '../api/schema-api';
import type { ItemTypeSchema, SchemaField } from '../types/schema';

interface SchemaContextValue {
  schemas: ItemTypeSchema[];
  isLoading: boolean;
  error: Error | null;
  getSchema: (type: string) => ItemTypeSchema | undefined;
  getFields: (type: string) => SchemaField[];
  refetchSchemas: () => void;
}

const SchemaContext = createContext<SchemaContextValue | null>(null);

export function SchemaProvider({ children }: { children: ReactNode }) {
  const { data = [], isLoading, error, refetch } = useQuery({
    queryKey: ['schemas'],
    queryFn: async () => {
      try {
        const result = await schemaApi.list();
        return result ?? [];
      } catch {
        return [];
      }
    },
    staleTime: 5 * 60 * 1000,
  });

  const value: SchemaContextValue = {
    schemas: data,
    isLoading,
    error: error as Error | null,
    getSchema: (type: string) => data?.find((s) => s.name === type),
    getFields: (type: string) => data?.find((s) => s.name === type)?.fields || [],
    refetchSchemas: refetch,
  };

  return <SchemaContext.Provider value={value}>{children}</SchemaContext.Provider>;
}

export function useSchemaContext() {
  const ctx = useContext(SchemaContext);
  if (!ctx) throw new Error('useSchemaContext must be used within SchemaProvider');
  return ctx;
}

export function useSchema(itemType: string) {
  const { getSchema, getFields, isLoading, error } = useSchemaContext();
  return {
    schema: getSchema(itemType),
    fields: getFields(itemType),
    isLoading,
    error,
  };
}
