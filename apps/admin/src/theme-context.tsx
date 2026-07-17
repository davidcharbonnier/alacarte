import { createContext, useCallback, useContext, useMemo, useState, type ReactNode } from 'react';
import { ThemeProvider as MuiThemeProvider, CssBaseline } from '@mui/material';
import { useColorScheme } from '@mui/material/styles';
import { theme } from './theme';

type Mode = 'light' | 'dark';

interface ThemeCtx {
  mode: Mode;
  toggle: () => void;
  setMode: (m: Mode) => void;
}

const ThemeCtx = createContext<ThemeCtx | null>(null);

function readInitialMode(): Mode {
  if (typeof document === 'undefined') return 'light';
  return document.documentElement.classList.contains('dark') ? 'dark' : 'light';
}

// ponytail: useColorScheme() must run inside MuiThemeProvider (it's a hook
// that reads from CssVarsProvider context). Outer component only sets up the
// provider; inner component consumes the hook and exposes the toggle.
export function ThemeModeProvider({ children }: { children: ReactNode }) {
  const initialMode = readInitialMode();

  return (
    <MuiThemeProvider theme={theme} defaultMode={initialMode}>
      <CssBaseline />
      <ThemeController>{children}</ThemeController>
    </MuiThemeProvider>
  );
}

function ThemeController({ children }: { children: ReactNode }) {
  const { mode, setMode: muiSetMode } = useColorScheme();
  const [localMode, setLocalMode] = useState<Mode>(() => readInitialMode());

  const apply = useCallback(
    (next: Mode) => {
      setLocalMode(next);
      muiSetMode(next);
      if (typeof document !== 'undefined') {
        document.documentElement.classList.toggle('dark', next === 'dark');
        document.documentElement.classList.toggle('light', next === 'light');
        try {
          localStorage.setItem('theme', next);
        } catch {
          // ignore
        }
      }
    },
    [muiSetMode],
  );

  const ctx = useMemo<ThemeCtx>(
    () => ({
      // muiSetMode may not have applied yet; fall back to localMode.
      mode: (mode as Mode) || localMode,
      toggle: () => apply((mode as Mode) === 'dark' ? 'light' : 'dark'),
      setMode: apply,
    }),
    [mode, localMode, apply],
  );

  return <ThemeCtx.Provider value={ctx}>{children}</ThemeCtx.Provider>;
}

export function useThemeMode() {
  const v = useContext(ThemeCtx);
  if (!v) throw new Error('useThemeMode must be used within ThemeModeProvider');
  return v;
}
