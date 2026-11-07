import { defineConfig, loadEnv } from 'vite';
import { readFileSync } from 'node:fs';
import { securityHeaders } from './security-headers.mjs';
import { serviceWorker } from './scripts/service-worker.mjs';

const pkg = JSON.parse(readFileSync(new URL('./package.json', import.meta.url), 'utf8'));

export default defineConfig(({ mode }) => {
  const env = loadEnv(mode, process.cwd(), 'VITE_');
  const assetOrigin = env.VITE_ASSET_BASE && /^https:\/\//.test(env.VITE_ASSET_BASE) ? new URL(env.VITE_ASSET_BASE).origin : '';
  return {
    define: { __APP_VERSION__: JSON.stringify(pkg.version) },
    plugins: [serviceWorker()],
    server: { headers: securityHeaders({ assetOrigin, dev: true }) },
    preview: { headers: securityHeaders({ assetOrigin }) },
    worker: { format: 'es' },
    build: {
      target: 'es2022',
      // three.js alone is ~560 kB (≈140 kB gzip); it is split out on purpose.
      chunkSizeWarningLimit: 600,
      rollupOptions: { output: { manualChunks: id => (id.includes('node_modules/three') ? 'three' : undefined) } }
    }
  };
});
