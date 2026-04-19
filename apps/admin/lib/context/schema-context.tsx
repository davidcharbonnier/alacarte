'use client';

import { createContext, useContext, ReactNode } from 'react';
import { useQuery } from '@tanstack/react-query';
import { schemaApi, dynamicItemApi } from '@/lib/api/schema-api';
import type { ItemTypeSchema, SchemaField } from '@/lib/types/schema';

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

  const getSchema = (type: string): ItemTypeSchema | undefined => {
    return data?.find((s) => s.name === type);
  };

  const getFields = (type: string): SchemaField[] => {
    const schema = getSchema(type);
    return schema?.fields || [];
  };

  return (
    <SchemaContext.Provider
      value={{
        schemas: data,
        isLoading,
        error: error as Error | null,
        getSchema,
        getFields,
        refetchSchemas: refetch,
      }}
    >
      {children}
    </SchemaContext.Provider>
  );
}

export function useSchemaContext() {
  const context = useContext(SchemaContext);
  if (!context) {
    throw new Error('useSchemaContext must be used within SchemaProvider');
  }
  return context;
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

export { schemaApi, dynamicItemApi };
