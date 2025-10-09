import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  output: "standalone",
  
  // Security: Remove X-Powered-By header to hide Next.js
  poweredByHeader: false,
};

export default nextConfig;
