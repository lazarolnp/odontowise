import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import tailwindcss from '@tailwindcss/vite';
import { fileURLToPath } from 'node:url';
export default defineConfig({ plugins: [react(), tailwindcss()], resolve:{alias:[{find:/^lucide-react$/,replacement:fileURLToPath(new URL('./icons.js',import.meta.url))}]} });
