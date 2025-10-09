'use client';

import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { cn } from '@/lib/utils';
import { Home, ChefHat, Wine, Users, Shield } from 'lucide-react';
import * as Icons from 'lucide-react';

// Navigation items with icon names (will be mapped to actual icons)
const navigationItems = [
  { name: 'Dashboard', href: '/', iconName: 'Home' },
  { name: 'Cheese', href: '/cheese', iconName: 'ChefHat' },
  { name: 'Gin', href: '/gin', iconName: 'Wine' },
  { name: 'Users', href: '/users', iconName: 'Users' },
];

export function Sidebar() {
  const pathname = usePathname();

  // Helper to get icon component from name
  const getIcon = (iconName: string) => {
    const IconComponent = (Icons as any)[iconName] || Icons.HelpCircle;
    return IconComponent;
  };

  return (
    <div className="flex flex-col w-64 bg-gray-900 text-white">
      <div className="flex items-center justify-center h-16 px-4 bg-gray-950">
        <Shield className="w-6 h-6 mr-2" />
        <span className="text-lg font-semibold">A la carte Admin</span>
      </div>
      <nav className="flex-1 px-4 py-4 space-y-2">
        {navigationItems.map((item) => {
          const Icon = getIcon(item.iconName);
          const isActive = pathname === item.href || 
            (item.href !== '/' && pathname?.startsWith(item.href));
          
          return (
            <Link
              key={item.name}
              href={item.href}
              className={cn(
                'flex items-center px-4 py-2 text-sm font-medium rounded-md transition-colors',
                isActive
                  ? 'bg-gray-800 text-white'
                  : 'text-gray-300 hover:bg-gray-800 hover:text-white'
              )}
            >
              <Icon className="w-5 h-5 mr-3" />
              {item.name}
            </Link>
          );
        })}
      </nav>
    </div>
  );
}
