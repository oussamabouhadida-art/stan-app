import path from 'node:path';
import type { NextConfig } from 'next';

const nextConfig: NextConfig = {
  reactStrictMode: true,
  transpilePackages: ['@stan/ui'],
  // Pin the file-tracing root to the monorepo root (avoids picking up a stray
  // lockfile elsewhere on the machine).
  outputFileTracingRoot: path.join(import.meta.dirname, '../../'),
};

export default nextConfig;
