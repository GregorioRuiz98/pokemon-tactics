import { defineConfig } from 'vite';

// Adapted from phaserjs/template-vite-ts. MIT notice in public/licenses.
export default defineConfig({
  base: './',
  server: { port: 5173, strictPort: true },
  preview: { port: 4173, strictPort: true },
  build: {
    rollupOptions: { output: { manualChunks: { phaser: ['phaser'] } } },
  },
});
