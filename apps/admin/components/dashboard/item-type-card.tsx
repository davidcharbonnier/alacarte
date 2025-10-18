'use client';

import Link from 'next/link';
import { Card, CardContent } from '@/components/ui/card';
import { getItemTypeColor } from '@/lib/config/design-system';
import * as Icons from 'lucide-react';
import { ArrowRight } from 'lucide-react';
import { cn } from '@/lib/utils';

interface ItemTypeCardProps {
  itemType: string;
  displayName: string;
  icon: string;
  totalItems: number;
  isLoading?: boolean;
}

/**
 * Item Type Card Component
 * 
 * Flutter-style card for item types with colored icon and stats.
 * Matches the design from the client app's home screen.
 */
export function ItemTypeCard({
  itemType,
  displayName,
  icon,
  totalItems,
  isLoading = false,
}: ItemTypeCardProps) {
  const colors = getItemTypeColor(itemType);
  const IconComponent = (Icons as any)[icon] || Icons.HelpCircle;

  return (
    <Link href={`/${itemType}`}>
      <Card className="hover:shadow-lg transition-shadow duration-200 cursor-pointer h-full">
        <CardContent className="p-6">
          <div className="flex items-center gap-4">
            {/* Icon with colored background */}
            <div
              className={cn(
                'flex items-center justify-center rounded-xl p-4',
                'transition-transform hover:scale-105'
              )}
              style={{
                backgroundColor: `${colors.hex}1A`, // 10% opacity
              }}
            >
              <IconComponent
                className="h-12 w-12"
                style={{ color: colors.hex }}
              />
            </div>

            {/* Content */}
            <div className="flex-1 min-w-0">
              <h3 className="text-xl font-bold text-foreground mb-2">
                {displayName}
              </h3>
              
              {isLoading ? (
                <p className="text-sm text-muted-foreground">
                  Loading...
                </p>
              ) : (
                <>
                  <p className="text-sm text-muted-foreground mb-1">
                    {totalItems} {totalItems === 1 ? 'item' : 'items'} available
                  </p>
                  <p
                    className="text-sm font-semibold"
                    style={{ color: colors.hex }}
                  >
                    View all {displayName.toLowerCase()}
                  </p>
                </>
              )}
            </div>

            {/* Arrow */}
            <ArrowRight className="h-5 w-5 text-muted-foreground opacity-50" />
          </div>
        </CardContent>
      </Card>
    </Link>
  );
}
