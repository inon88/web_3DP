# [005] Siap deploy di Vercel gratis (tanpa GitHub) + perbaikan error dev

**Tanggal:** 2026-11-01
**Status:** done

## Masalah
1. `npm run dev` gagal: "Failed to load url /openscad/openscad.js … file is in /public … should not be imported from source code". Worker mengimpor glue OpenSCAD dari `public/`.
2. Aplikasi akan dijalankan di Vercel paket gratis (Hobby). `web/` belum boleh masuk GitHub → deploy lewat Vercel CLI dari folder lokal.

## Rencana Perubahan
- [x] `scripts/fetch-assets.mjs` — glue ke `src/vendor`, WASM & font ke path berversi
- [x] `src/workers/render.worker.js` — impor glue yang dibundel
- [x] `src/platform/assets.js`, `fonts.js`, `engine.js` — path aset dari manifest
- [x] `vercel.json`, `.vercelignore`, `security-headers.mjs`
- [x] `rancangan.md` — §13 langkah deploy & batas paket gratis
- [x] Verifikasi dev + build + preview di Chrome

## Perubahan yang Sudah Dibuat
- [x] `scripts/fetch-assets.mjs` — glue diverifikasi SHA-256 lalu ditulis ke `src/vendor/openscad/openscad.js` dengan satu baris dinetralkan (`new URL("openscad.wasm", import.meta.url)` → `"openscad.wasm"`; tidak dipakai karena app memberi `instantiateWasm`, dan mencegah Vite menyalin WASM 11 MB dua kali); WASM → `public/openscad/2026.10.11/`, font → `public/fonts/liberation-2.1.5/` (dipindah dari folder lama, tanpa unduh ulang); file lama dihapus; manifest kini `{ wasm, fontDir, integrity }`; bisa jalan tanpa `..` bila salinan lokal ada
- [x] `src/workers/render.worker.js` — `import createOpenSCAD from '../vendor/openscad/openscad.js'` (worker 64 kB termasuk glue)
- [x] `src/platform/assets.js` — `WASM_PATH`, `FONT_DIR` dari manifest; SRI dari `manifest.integrity`
- [x] `src/platform/engine.js`, `src/platform/fonts.js` — pakai path berversi
- [x] `security-headers.mjs` — satu definisi header; `vite.config.js` memakainya
- [x] `vercel.json` — build Vite, header keamanan + HSTS, cache immutable untuk aset ber-hash/berversi, `/library` revalidate
- [x] `.vercelignore` — tidak mengunggah `node_modules`, `dist`, `spike`, `imple`, `test`, `*.md`
- [x] `test/vercel.test.mjs` — header `vercel.json` = `security-headers.mjs`; semua aset di manifest ada di `public/`
- [x] `rancangan.md` — §13

## Catatan
- `npm run dev` (Chrome): render berhasil, konsol bersih, `crossOriginIsolated = true`.
- `vite preview` build produksi: header sama persis dengan `vercel.json`, WASM `application/wasm`, render berhasil; aset dimuat dari `/openscad/2026.10.11/` dan `/fonts/liberation-2.1.5/`.
- `npm test`: 8/8 lulus. `dist/` ±16 MB, WASM hanya satu salinan.
- Server dev milik pengguna (`vite` di `[::1]:5173`) dibiarkan berjalan; Vite me-restart sendiri saat config berubah. Server uji milik sendiri sudah dihentikan.
- Belum di-deploy: login & deploy Vercel dilakukan pengguna (`npx vercel login`, `npx vercel`, `npx vercel --prod`).
- Mode CDN eksternal (`VITE_ASSET_BASE` ke jsDelivr GitHub) tidak dipakai selama `web/` tidak di GitHub; Vercel sendiri sudah CDN.
