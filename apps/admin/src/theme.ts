import { createTheme, alpha } from '@mui/material/styles';
import type { Theme } from '@mui/material/styles';

// ponytail: register M3 type-scale variants on MUI's Typography so
// `variant="headlineSmall"` etc. type-checks. Without this, only the default
// h1..h6 + subtitle1/2 + body1/2 + button + caption + overline are accepted.
declare module '@mui/material/Typography' {
  interface TypographyPropsVariantOverrides {
    displayLarge: true;
    displayMedium: true;
    displaySmall: true;
    headlineLarge: true;
    headlineMedium: true;
    headlineSmall: true;
    titleLarge: true;
    titleMedium: true;
    titleSmall: true;
    bodyLarge: true;
    bodyMedium: true;
    bodySmall: true;
    labelLarge: true;
    labelMedium: true;
    labelSmall: true;
  }
}

declare module '@mui/material/styles' {
  interface Palette {
    tertiary: Palette['primary'];
    tertiaryContainer: Palette['primary'];
    onTertiary: Palette['primary'];
    onTertiaryContainer: Palette['primary'];
    warning: Palette['primary'];
    success: Palette['primary'];
    surface: Palette['primary'];
    onSurface: Palette['primary'];
    surfaceVariant: Palette['primary'];
    onSurfaceVariant: Palette['primary'];
    outline: Palette['primary'];
    outlineVariant: Palette['primary'];
    surfaceContainerLowest: Palette['primary'];
    surfaceContainerLow: Palette['primary'];
    surfaceContainer: Palette['primary'];
    surfaceContainerHigh: Palette['primary'];
    surfaceContainerHighest: Palette['primary'];
  }
  interface PaletteOptions {
    tertiary?: PaletteOptions['primary'];
    tertiaryContainer?: PaletteOptions['primary'];
    onTertiary?: PaletteOptions['primary'];
    onTertiaryContainer?: PaletteOptions['primary'];
    warning?: PaletteOptions['primary'];
    success?: PaletteOptions['primary'];
    surface?: PaletteOptions['primary'];
    onSurface?: PaletteOptions['primary'];
    surfaceVariant?: PaletteOptions['primary'];
    onSurfaceVariant?: PaletteOptions['primary'];
    outline?: PaletteOptions['primary'];
    outlineVariant?: PaletteOptions['primary'];
    surfaceContainerLowest?: PaletteOptions['primary'];
    surfaceContainerLow?: PaletteOptions['primary'];
    surfaceContainer?: PaletteOptions['primary'];
    surfaceContainerHigh?: PaletteOptions['primary'];
    surfaceContainerHighest?: PaletteOptions['primary'];
  }
}

// ponytail: M3 tonal palette derived from deepPurple seed, matches Flutter client's
// ColorScheme.fromSeed(Colors.deepPurple). M3 component defaults replace the
// old shadcn/Tailwind patterns (border-left stripes, hex-opacity tinted boxes).
export const theme: Theme = createTheme({
  cssVariables: {
    colorSchemeSelector: 'class',
  },
  colorSchemes: {
    light: {
      palette: {
        primary: { main: '#673AB7' },
        secondary: { main: '#625B71' },
        tertiary: { main: '#7D5260' },
        error: { main: '#B3261E' },
        warning: { main: '#FF9800' },
        success: { main: '#4CAF50' },
        background: { default: '#FEF7FF', paper: '#FFFFFF' },
        surface: { main: '#FEF7FF' },
        surfaceVariant: { main: '#E7E0EC' },
        outline: { main: '#79747E' },
        outlineVariant: { main: '#CAC4D0' },
        // M3 surface containers (extended via module augmentation below)
        surfaceContainerLowest: { main: '#FFFFFF' },
        surfaceContainerLow: { main: '#F7F2FA' },
        surfaceContainer: { main: '#F3EDF7' },
        surfaceContainerHigh: { main: '#ECE6F0' },
        surfaceContainerHighest: { main: '#E6E0E9' },
      },
    },
    dark: {
      palette: {
        primary: { main: '#D0BCFF' },
        secondary: { main: '#CCC2DC' },
        tertiary: { main: '#EFB8C8' },
        error: { main: '#F2B8B5' },
        warning: { main: '#FFB74D' },
        success: { main: '#81C784' },
        background: { default: '#141218', paper: '#1D1B20' },
        surface: { main: '#141218' },
        surfaceVariant: { main: '#49454F' },
        outline: { main: '#938F99' },
        outlineVariant: { main: '#49454F' },
        surfaceContainerLowest: { main: '#0F0D13' },
        surfaceContainerLow: { main: '#1D1B20' },
        surfaceContainer: { main: '#211F26' },
        surfaceContainerHigh: { main: '#2B2930' },
        surfaceContainerHighest: { main: '#36343B' },
      },
    },
  },
  shape: {
    borderRadius: 12,
  },
  typography: {
    fontFamily: 'Roboto, "Helvetica Neue", Arial, sans-serif',
    // M3 type scale
    h1: { fontSize: '3.5625rem', fontWeight: 400, lineHeight: '4rem', letterSpacing: '-0.015625em' },
    h2: { fontSize: '2.8125rem', fontWeight: 400, lineHeight: '3.25rem', letterSpacing: 0 },
    h3: { fontSize: '2.25rem', fontWeight: 400, lineHeight: '2.75rem' },
    h4: { fontSize: '2rem', fontWeight: 400, lineHeight: '2.5rem' },
    h5: { fontSize: '1.75rem', fontWeight: 400, lineHeight: '2.25rem' },
    h6: { fontSize: '1.375rem', fontWeight: 500, lineHeight: '1.75rem', letterSpacing: 0 },
    subtitle1: { fontSize: '1rem', fontWeight: 500, lineHeight: '1.5rem', letterSpacing: '0.009375em' },
    subtitle2: { fontSize: '0.875rem', fontWeight: 500, lineHeight: '1.25rem', letterSpacing: '0.00714em' },
    body1: { fontSize: '1rem', fontWeight: 400, lineHeight: '1.5rem', letterSpacing: '0.03125em' },
    body2: { fontSize: '0.875rem', fontWeight: 400, lineHeight: '1.25rem', letterSpacing: '0.01786em' },
    button: { fontSize: '0.875rem', fontWeight: 500, lineHeight: '1.25rem', letterSpacing: '0.00714em', textTransform: 'none' },
    caption: { fontSize: '0.75rem', fontWeight: 400, lineHeight: '1rem', letterSpacing: '0.03333em' },
  },
  components: {
    MuiCssBaseline: {
      styleOverrides: {
        body: {
          fontFeatureSettings: '"cv02","cv03","cv04","cv11"',
        },
      },
    },
    MuiButton: {
      defaultProps: { disableElevation: true },
      styleOverrides: {
        root: { borderRadius: 20, textTransform: 'none', fontWeight: 500 },
        sizeSmall: { borderRadius: 16 },
        sizeLarge: { borderRadius: 24, paddingTop: 10, paddingBottom: 10 },
      },
    },
    MuiIconButton: {
      styleOverrides: {
        root: { borderRadius: 16 },
      },
    },
    MuiCard: {
      defaultProps: { variant: 'elevation', elevation: 0 },
      styleOverrides: {
        root: { borderRadius: 16 },
      },
    },
    MuiPaper: {
      defaultProps: { elevation: 0 },
    },
    MuiAppBar: {
      defaultProps: { elevation: 0, color: 'inherit' },
      styleOverrides: {
        root: {
          backgroundImage: 'none',
          bgcolor: 'surfaceContainer',
          color: 'onSurface',
          borderBottom: 1,
          borderColor: 'outlineVariant',
        },
      },
    },
    MuiChip: {
      styleOverrides: {
        root: { borderRadius: 8 },
        label: { fontWeight: 500 },
      },
    },
    MuiTextField: {
      defaultProps: { variant: 'outlined' },
    },
    MuiOutlinedInput: {
      styleOverrides: {
        root: { borderRadius: 12 },
      },
    },
    MuiTab: {
      styleOverrides: {
        root: { textTransform: 'none', fontWeight: 500 },
      },
    },
    MuiDialog: {
      styleOverrides: {
        paper: { borderRadius: 24 },
      },
    },
    MuiFab: {
      defaultProps: { size: 'medium' },
      styleOverrides: {
        root: { borderRadius: 16, boxShadow: 'none' },
      },
    },
  },
});

// ponytail: grey fallback for schemas without a color; otherwise read schema.color at render.
// The accent color is used for a small "scrim" overlay or status indicator — never as a
// page background, which would fight M3's tonal surface system.
export const FALLBACK_ACCENT = '#79747E';

export function getAccentColor(hex?: string | null): string {
  return hex || FALLBACK_ACCENT;
}

export function getAccentWithAlpha(hex: string, alphaValue: number): string {
  return alpha(hex, alphaValue);
}
