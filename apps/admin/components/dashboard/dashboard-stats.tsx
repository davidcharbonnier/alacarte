'use client';

import { useQuery } from '@tanstack/react-query';
import { getAllItemTypes, getItemTypeConfig } from '@/lib/config/item-types';
import { getItemApi } from '@/lib/api/generic-item-api';
import { userApi } from '@/lib/api/users';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Users } from 'lucide-react';
import * as Icons from 'lucide-react';

export function DashboardStats() {
  const itemTypes = getAllItemTypes();

  return (
    <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
      {itemTypes.map((itemType: any) => (
        <ItemTypeStatCard key={itemType} itemType={itemType} />
      ))}
      
      <UserStatCard />
    </div>
  );
}

function ItemTypeStatCard({ itemType }: { itemType: string }) {
  const config = getItemTypeConfig(itemType);
  
  // Get icon component from config
  const IconComponent = (Icons as any)[config.icon] || Icons.HelpCircle;

  const { data: items, isLoading } = useQuery({
    queryKey: [itemType, 'list'],
    queryFn: () => getItemApi(itemType).getAll(),
  });

  return (
    <Card>
      <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
        <CardTitle className="text-sm font-medium">Total {config.labels.plural}</CardTitle>
        <IconComponent className="h-4 w-4 text-muted-foreground" />
      </CardHeader>
      <CardContent>
        {isLoading ? (
          <>
            <div className="text-2xl font-bold">-</div>
            <p className="text-xs text-muted-foreground">
              Loading...
            </p>
          </>
        ) : (
          <>
            <div className="text-2xl font-bold">{items?.length || 0}</div>
            <p className="text-xs text-muted-foreground">
              {items?.length === 1 ? config.labels.singular : config.labels.plural} in database
            </p>
          </>
        )}
      </CardContent>
    </Card>
  );
}

function UserStatCard() {
  const { data: users, isLoading } = useQuery({
    queryKey: ['users', 'list'],
    queryFn: () => userApi.getAll(),
  });

  return (
    <Card>
      <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
        <CardTitle className="text-sm font-medium">Total Users</CardTitle>
        <Users className="h-4 w-4 text-muted-foreground" />
      </CardHeader>
      <CardContent>
        {isLoading ? (
          <>
            <div className="text-2xl font-bold">-</div>
            <p className="text-xs text-muted-foreground">
              Loading...
            </p>
          </>
        ) : (
          <>
            <div className="text-2xl font-bold">{users?.length || 0}</div>
            <p className="text-xs text-muted-foreground">
              {users?.length === 1 ? 'User' : 'Users'} in database
            </p>
          </>
        )}
      </CardContent>
    </Card>
  );
}
