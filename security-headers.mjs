// One definition of the security headers (rancangan.md §7), used by the Vite dev/preview servers.
// vercel.json repeats them for production; test/vercel.test.mjs fails when the two drift apart.
// Trusted Types enforcement (require-trusted-types-for) is added in M3, once renderer.js no longer
// assigns innerHTML.
// Google Fonts files are fetched by link (src/platform/fonts.js), checked by SRI. Only the file host is
// allowed, not fonts.googleapis.com: the app never loads Google's CSS.
export const GOOGLE_FONT_ORIGIN = 'https://fonts.gstatic.com';

export function contentSecurityPolicy({ assetOrigin = '', dev = false } = {}) {
  const connect = ["'self'", GOOGLE_FONT_ORIGIN, assetOrigin, dev && 'ws:'].filter(Boolean).join(' ');
  return [
    "default-src 'self'",
    "script-src 'self' 'wasm-unsafe-eval'",
    "worker-src 'self'",
    `connect-src ${connect}`,
    "style-src 'self' 'unsafe-inline'",
    "img-src 'self' data: blob:",
    "font-src 'self'",
    "object-src 'none'",
    "base-uri 'none'",
    "form-action 'none'",
    "frame-ancestors 'none'"
  ].join('; ');
}

export function securityHeaders(options = {}) {
  return {
    'Content-Security-Policy': contentSecurityPolicy(options),
    'Cross-Origin-Opener-Policy': 'same-origin',
    'Cross-Origin-Embedder-Policy': 'require-corp',
    'X-Content-Type-Options': 'nosniff',
    'Referrer-Policy': 'no-referrer',
    'Permissions-Policy': 'camera=(), microphone=(), geolocation=(), payment=(), usb=()'
  };
}
