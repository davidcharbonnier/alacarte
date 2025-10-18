import { cn } from '@/lib/utils';
import { getItemTypeColor, getItemTypeClasses } from '@/lib/config/design-system';

interface ItemTypeBadgeProps {
  itemType: string;
  className?: string;
  size?: 'sm' | 'md' | 'lg';
}

/**
 * Badge component for displaying item types with their distinctive colors
 * Matches the Flutter app's visual style
 */
export function ItemTypeBadge({ itemType, className, size = 'md' }: ItemTypeBadgeProps) {
  const colors = getItemTypeColor(itemType);
  
  const sizeClasses = {
    sm: 'px-2 py-0.5 text-xs',
    md: 'px-2.5 py-1 text-sm',
    lg: 'px-3 py-1.5 text-base',
  };

  return (
    <span
      className={cn(
        'inline-flex items-center rounded-md font-medium capitalize',
        sizeClasses[size],
        className
      )}
      style={{
        color: colors.hex,
        backgroundColor: `${colors.hex}10`, // 10% opacity
      }}
    >
      {itemType}
    </span>
  );
}
