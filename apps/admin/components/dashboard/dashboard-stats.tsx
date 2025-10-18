'use client';

import Link from 'next/link';
import { useQuery } from '@tanstack/react-query';
import { getAllItemTypes, getItemTypeConfig } from '@/lib/config/item-types';
import { getItemApi } from '@/lib/api/generic-item-api';
import { userApi } from '@/lib/api/users';
import { ItemTypeCard } from './item-type-card';
import { Card, CardContent } from '@/components/ui/card';
import { Users, ArrowRight } from 'lucide-react';
import { spacing } from '@/lib/config/design-system';

export function DashboardStats() {
  const itemTypes = getAllItemTypes();

  return (
    <div className="space-y-6">
      {/* Item Type Cards - Flutter style */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
        {itemTypes.map((itemType: any) => (
          <ItemTypeStatCard key={itemType} itemType={itemType} />
        ))}
      </div>
      
      {/* User Stats Card - Compact style */}
      <UserStatCard />
    </div>
  );
}

function ItemTypeStatCard({ itemType }: { itemType: string }) {
  const config = getItemTypeConfig(itemType);

  const { data: items, isLoading } = useQuery({
    queryKey: [itemType, 'list'],
    queryFn: () => getItemApi(itemType).getAll(),
  });

  return (
    <ItemTypeCard
      itemType={itemType}
      displayName={config.labels.plural}
      icon={config.icon}
      totalItems={items?.length || 0}
      isLoading={isLoading}
    />
  );
}

function UserStatCard() {
  const { data: users, isLoading } = useQuery({
    queryKey: ['users', 'list'],
    queryFn: () => userApi.getAll(),
  });

  return (
    <Link href="/users">
      <Card className="bg-muted/30 hover:shadow-lg transition-shadow duration-200 cursor-pointer">
        <CardContent className="p-6">
          <div className="flex items-center gap-4">
            <div className="flex items-center justify-center rounded-xl p-4 bg-muted">
              <Users className="h-8 w-8 text-muted-foreground" />
            </div>
            
            <div className="flex-1">
              <h3 className="text-lg font-semibold text-foreground mb-1">Users</h3>
              {isLoading ? (
                <p className="text-sm text-muted-foreground">Loading...</p>
              ) : (
                <>
                  <p className="text-sm text-muted-foreground mb-1">
                    {users?.length || 0} {users?.length === 1 ? 'user' : 'users'} in database
                  </p>
                  <p className="text-sm font-semibold text-primary">
                    View all users
                  </p>
                </>
              )}
            </div>
            
            <ArrowRight className="h-5 w-5 text-muted-foreground opacity-50" />
          </div>
        </CardContent>
      </Card>
    </Link>
  );
}
