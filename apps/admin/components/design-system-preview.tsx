import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { ItemTypeBadge } from '@/components/ui/item-type-badge';
import {
  itemTypeColors,
  brandColors,
  ratingColors,
  spacing,
  radius,
  iconSizes,
  fontSizes,
} from '@/lib/config/design-system';
import { ChefHat, Wine, Palette } from 'lucide-react';

/**
 * Design System Preview Component
 * Displays all colors, spacing, and design tokens for reference
 */
export function DesignSystemPreview() {
  return (
    <div className="space-y-6">
      {/* Item Type Colors */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Palette className="h-5 w-5" />
            Item Type Colors
          </CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          {Object.entries(itemTypeColors).map(([type, colors]) => (
            <div key={type} className="flex items-center gap-4">
              <div className="flex items-center gap-2 w-32">
                {type === 'cheese' && <ChefHat className="h-5 w-5" />}
                {(type === 'gin' || type === 'wine') && <Wine className="h-5 w-5" />}
                <span className="font-medium capitalize">{type}</span>
              </div>
              <div
                className="w-16 h-16 rounded-lg border-2"
                style={{ backgroundColor: colors.hex }}
              />
              <div className="flex flex-col gap-1">
                <code className="text-xs">{colors.hex}</code>
                <code className="text-xs text-muted-foreground">{colors.rgb}</code>
              </div>
              <div className="ml-auto">
                <ItemTypeBadge itemType={type} />
              </div>
            </div>
          ))}
        </CardContent>
      </Card>

      {/* Brand Colors */}
      <Card>
        <CardHeader>
          <CardTitle>Brand Colors</CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          {Object.entries(brandColors).map(([name, color]) => (
            <div key={name} className="flex items-center gap-4">
              <span className="font-medium capitalize w-32">{name}</span>
              <div
                className="w-16 h-16 rounded-lg border-2"
                style={{ backgroundColor: color }}
              />
              <code className="text-xs">{color}</code>
            </div>
          ))}
        </CardContent>
      </Card>

      {/* Rating Colors */}
      <Card>
        <CardHeader>
          <CardTitle>Rating Colors</CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          {Object.entries(ratingColors).map(([name, color]) => (
            <div key={name} className="flex items-center gap-4">
              <span className="font-medium capitalize w-32">{name}</span>
              <div
                className="w-16 h-16 rounded-lg border-2"
                style={{ backgroundColor: color }}
              />
              <code className="text-xs">{color}</code>
            </div>
          ))}
        </CardContent>
      </Card>

      {/* Spacing Scale */}
      <Card>
        <CardHeader>
          <CardTitle>Spacing Scale</CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          {Object.entries(spacing).map(([name, value]) => (
            <div key={name} className="flex items-center gap-4">
              <span className="font-medium w-16">{name}</span>
              <div
                className="bg-primary h-8 rounded"
                style={{ width: `${value}px` }}
              />
              <code className="text-xs">{value}px</code>
            </div>
          ))}
        </CardContent>
      </Card>

      {/* Border Radius */}
      <Card>
        <CardHeader>
          <CardTitle>Border Radius</CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          {Object.entries(radius).map(([name, value]) => (
            <div key={name} className="flex items-center gap-4">
              <span className="font-medium w-16">{name}</span>
              <div
                className="bg-primary w-16 h-16 border-2"
                style={{ borderRadius: `${value}px` }}
              />
              <code className="text-xs">{value}px</code>
            </div>
          ))}
        </CardContent>
      </Card>

      {/* Typography Scale */}
      <Card>
        <CardHeader>
          <CardTitle>Typography Scale</CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          {Object.entries(fontSizes).map(([name, value]) => (
            <div key={name} className="flex items-center gap-4">
              <span className="font-medium w-16">{name}</span>
              <span style={{ fontSize: `${value}px` }}>
                The quick brown fox jumps over the lazy dog
              </span>
              <code className="text-xs ml-auto">{value}px</code>
            </div>
          ))}
        </CardContent>
      </Card>
    </div>
  );
}
