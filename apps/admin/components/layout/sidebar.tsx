'use client';

import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { cn } from '@/lib/utils';
import { Home, Users, Shield } from 'lucide-react';
import * as Icons from 'lucide-react';
import { useSchemaContext } from '@/lib/context/schema-context';

// Static navigation items (non-item-types)
const staticItems = [
  { name: 'Dashboard', href: '/', iconName: 'Home', type: 'static' },
];

const bottomItems = [
  { name: 'Users', href: '/users', iconName: 'Users', type: 'static' },
  { name: 'Schemas', href: '/admin/schemas', iconName: 'Shield', type: 'static' },
];

export function Sidebar() {
  const pathname = usePathname();
  const { schemas } = useSchemaContext();

  // Get dynamic item type navigation items from schemas
  const itemTypeItems = schemas.map((schema) => {
    return {
      name: schema.plural_name,
      href: `/${schema.name}`,
      iconName: schema.icon,
      type: 'itemType',
      itemType: schema.name,
      color: schema.color,
    };
  });

  // Helper to get icon component from name
  const getIcon = (iconName: string) => {
    const IconComponent = (Icons as any)[iconName] || Icons.HelpCircle;
    return IconComponent;
  };

  const renderNavItem = (item: any) => {
    const Icon = getIcon(item.iconName);
    const isActive = pathname === item.href ||
      (item.href !== '/' && pathname?.startsWith(item.href));

    return (
      <Link
        key={item.name}
        href={item.href}
        className={cn(
          'flex items-center px-4 py-2.5 text-sm font-medium rounded-lg transition-all duration-200',
          'group relative',
          isActive
            ? 'bg-sidebar-accent text-sidebar-accent-foreground shadow-sm'
            : 'text-sidebar-foreground hover:bg-sidebar-accent/50 hover:text-sidebar-accent-foreground'
        )}
      >
        {/* Icon with colored background for item types */}
        {item.type === 'itemType' && item.color ? (
          <div
            className={cn(
              'flex items-center justify-center w-8 h-8 rounded-lg mr-3',
              'transition-transform group-hover:scale-110',
              isActive && 'scale-110'
            )}
            style={{
              backgroundColor: isActive ? `${item.color}25` : `${item.color}15`,
            }}
          >
            <Icon
              className="w-5 h-5"
              style={{ color: item.color }}
            />
          </div>
        ) : (
          <Icon className={cn(
            'w-5 h-5 mr-3',
            'transition-transform group-hover:scale-110',
            isActive && 'scale-110'
          )} />
        )}

        {item.name}

        {/* Active indicator */}
        {isActive && item.type === 'itemType' && item.color && (
          <div
            className="absolute left-0 top-1/2 -translate-y-1/2 w-1 h-8 rounded-r-full"
            style={{ backgroundColor: item.color }}
          />
        )}
      </Link>
    );
  };

  return (
    <div className="flex flex-col w-64 bg-sidebar border-r border-sidebar-border">
      {/* Header */}
      <div className="flex items-center justify-center h-16 px-4 border-b border-sidebar-border bg-sidebar">
        <Shield className="w-6 h-6 mr-2 text-primary" />
        <span className="text-lg font-semibold">À la carte Admin</span>
      </div>

      {/* Navigation */}
      <nav className="flex-1 px-3 py-4 space-y-1 overflow-y-auto">
        {/* Dashboard */}
        <div className="space-y-1">
          {staticItems.map(renderNavItem)}
        </div>

        {/* Item Types Section */}
        <div className="pt-4 pb-2">
          <div className="px-4 text-xs font-semibold text-sidebar-foreground/60 uppercase tracking-wider mb-2">
            Item Types
          </div>
          <div className="space-y-1">
            {itemTypeItems.map(renderNavItem)}
          </div>
        </div>

        {/* Bottom Items */}
        <div className="pt-4 border-t border-sidebar-border mt-4">
          {bottomItems.map(renderNavItem)}
        </div>
      </nav>
    </div>
  );
}
