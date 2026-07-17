import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import { TanStackRouterVite } from '@tanstack/router-plugin/vite';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const root = __dirname;

export default defineConfig({
  root,
  plugins: [
    // ponytail: file-based route tree under src/routes/. Generates routeTree.gen.ts
    // and watches for new route files. Codegen output is gitignored (it regenerates on dev).
    TanStackRouterVite({
      routesDirectory: path.join(root, 'src/routes'),
      generatedRouteTree: path.join(root, 'src/routeTree.gen.ts'),
    }),
    react(),
  ],
  resolve: {
    alias: {
      '@': path.resolve(root, './src'),
    },
  },
  server: {
    port: 3000,
    host: true,
    // ponytail: GSI (@react-oauth/google) needs the popup it opens to be in
    // the same browsing-context group as the opener, otherwise window.postMessage
    // from the popup is blocked. Default COOP ("same-origin") silences this with
    // "Cross-Origin-Opener-Policy policy would block the window.postMessage call".
    headers: {
      'Cross-Origin-Opener-Policy': 'same-origin-allow-popups',
    },
  },
  preview: {
    headers: {
      'Cross-Origin-Opener-Policy': 'same-origin-allow-popups',
    },
  },
  build: {
    outDir: 'dist',
    sourcemap: false,
  },
});
