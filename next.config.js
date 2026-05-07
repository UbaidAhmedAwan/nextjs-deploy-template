/** @type {import('next').NextConfig} */
const nextConfig = {
  // standalone output bundles only the files needed for production into .next/standalone,
  // which keeps the runtime container image small (~150MB instead of pulling all node_modules).
  output: 'standalone',
  reactStrictMode: true,
  poweredByHeader: false,
};

module.exports = nextConfig;
