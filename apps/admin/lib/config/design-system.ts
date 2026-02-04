/**
 * Design System
 * 
 * Centralized design tokens matching the Flutter client app for visual consistency.
 * All colors, spacing, and sizing values should reference these constants.
 */

/**
 * Item Type Colors
 * 
 * Each item type has a distinctive color for visual identification.
 * These match the Flutter app's item type cards.
 */
export const itemTypeColors = {
  cheese: {
    hex: '#673AB7',        // Deep Purple (Flutter Colors.deepPurple)
    rgb: 'rgb(103, 58, 183)',
    hsl: 'hsl(262, 52%, 47%)',
    className: 'text-[#673AB7] bg-[#673AB7]/10',
  },
  gin: {
    hex: '#009688',        // Teal (Flutter Colors.teal)
    rgb: 'rgb(0, 150, 136)',
    hsl: 'hsl(174, 100%, 29%)',
    className: 'text-[#009688] bg-[#009688]/10',
  },
  wine: {
    hex: '#8E24AA',        // Deep Purple variant
    rgb: 'rgb(142, 36, 170)',
    hsl: 'hsl(288, 65%, 40%)',
    className: 'text-[#8E24AA] bg-[#8E24AA]/10',
  },
  coffee: {
    hex: '#795548',        // Brown (Flutter Colors.brown)
    rgb: 'rgb(121, 85, 72)',
    hsl: 'hsl(16, 25%, 38%)',
    className: 'text-[#795548] bg-[#795548]/10',
  },
  'chili-sauce': {
    hex: '#F44336',        // Red (distinctive chili color)
    rgb: 'rgb(244, 67, 54)',
    hsl: 'hsl(4, 91%, 58%)',
    className: 'text-[#F44336] bg-[#F44336]/10',
  },
} as const;

/**
 * Brand Colors
 * 
 * Primary brand colors used throughout the application.
 */
export const brandColors = {
  primary: '#673AB7',      // Deep Purple (matches Flutter primaryColor)
  secondary: '#9C27B0',    // Purple (matches Flutter secondaryColor)
  error: '#F44336',        // Red (matches Flutter errorColor)
  success: '#4CAF50',      // Green (matches Flutter successColor)
  warning: '#FF9800',      // Orange (matches Flutter warningColor)
} as const;

/**
 * Rating Colors
 * 
 * Colors for different rating types to provide clear visual identity.
 */
export const ratingColors = {
  personal: '#673AB7',     // Deep Purple - personal ratings
  recommendation: '#4CAF50', // Green - friend recommendations
  community: '#FF9800',    // Orange - community/public ratings
} as const;

/**
 * Spacing Scale
 * 
 * Consistent spacing values matching Flutter's AppConstants.
 * Values in pixels (converted from Flutter's logical pixels).
 */
export const spacing = {
  xs: 4,    // spacingXS
  s: 8,     // spacingS
  m: 16,    // spacingM
  l: 24,    // spacingL
  xl: 32,   // spacingXL
  xxl: 48,  // spacingXXL
} as const;

/**
 * Border Radius Scale
 * 
 * Consistent border radius values matching Flutter's AppConstants.
 */
export const radius = {
  xs: 2,    // radiusXS
  s: 4,     // radiusS
  m: 8,     // radiusM
  l: 12,    // radiusL
  xl: 16,   // radiusXL
} as const;

/**
 * Icon Sizes
 * 
 * Standard icon sizes matching Flutter's AppConstants.
 */
export const iconSizes = {
  xs: 12,   // iconXS
  s: 16,    // iconS
  m: 24,    // iconM
  l: 32,    // iconL
  xl: 48,   // iconXL
} as const;

/**
 * Font Sizes
 * 
 * Typography scale matching Flutter's AppConstants.
 */
export const fontSizes = {
  xs: 10,   // fontXS
  s: 12,    // fontS
  m: 14,    // fontM
  l: 16,    // fontL
  xl: 20,   // fontXL
  xxl: 24,  // fontXXL
} as const;

/**
 * Layout Constants
 * 
 * Maximum widths and standard dimensions.
 */
export const layout = {
  maxContentWidth: 600,  // Matches Flutter maxContentWidth
  sidebarWidth: 256,     // Standard sidebar width
} as const;

/**
 * Animation Durations
 * 
 * Standard animation timing in milliseconds.
 */
export const animations = {
  fast: 200,    // animationFast
  normal: 300,  // animationNormal
  slow: 500,    // animationSlow
} as const;

/**
 * Helper function to get item type color configuration
 */
export function getItemTypeColor(itemType: string) {
  const colors = itemTypeColors[itemType as keyof typeof itemTypeColors];
  if (!colors) {
    // Fallback to primary color for unknown item types
    return {
      hex: brandColors.primary,
      rgb: 'rgb(103, 58, 183)',
      hsl: 'hsl(262, 52%, 47%)',
      className: 'text-[#673AB7] bg-[#673AB7]/10',
    };
  }
  return colors;
}

/**
 * Helper function to get Tailwind utility classes for item type styling
 */
export function getItemTypeClasses(itemType: string): string {
  return getItemTypeColor(itemType).className;
}

/**
 * Type exports for TypeScript
 */
export type ItemType = keyof typeof itemTypeColors;
export type Spacing = keyof typeof spacing;
export type Radius = keyof typeof radius;
export type IconSize = keyof typeof iconSizes;
export type FontSize = keyof typeof fontSizes;
