# [001] Versi web BonaStudio (pustaka dari examples)

**Tanggal:** 2026-11-01
**Status:** in-progress

## Masalah
Buat versi web dari aplikasi desktop BonaStudio (`D:\_FRELENCE\hadi\App`) di folder `D:\_FRELENCE\hadi\web`. Pustaka tool berasal dari `App/examples`. Gunakan teknologi web terbaik & tercepat, utamakan user experience. Rancangan lengkap: `rancangan.md`.

## Rencana Perubahan
- [ ] `rancangan.md` — arsitektur, teknologi, pemetaan fitur desktop → web, UX, fase
- [ ] `package.json`, `vite.config.js`, `vercel.json`, `.gitignore` — proyek Vite + PWA
- [ ] `scripts/sync-from-app.mjs` — salin modul murni App (parameters, transform, heightmap, raster-to-svg, svg-layers, font-name, mesh-transform, image-trace, scad-assets) → `src/shared/` sebagai ESM; salin `examples/` → `library/`; ubah glue vtracer ke ESM
- [ ] `scripts/build-library.mjs` — buat `public/library/index.json` (nama, kategori, deskripsi, parameter ter-parse, daftar file)
- [ ] `scripts/fetch-assets.mjs` — unduh & verifikasi OpenSCAD WASM (sama seperti App) dan font Liberation (OFL) ke `public/`
- [ ] `src/platform/` — implementasi `window.formforge` untuk browser: penyimpanan IndexedDB, impor file/folder/URL, ekspor unduhan/File System Access, font, icon pack
- [ ] `src/workers/render.worker.js` — OpenSCAD WASM di Web Worker (modul WASM dikompilasi sekali, worker baru per render, bisa dibatalkan)
- [ ] `src/workers/trace.worker.js` — vtracer WASM di Web Worker
- [ ] `index.html`, `src/renderer.js`, `src/styles.css` — UI dari App, disesuaikan untuk web (galeri pustaka, berbagi tautan, unduhan, responsif, PWA)
- [ ] Verifikasi: build, render semua contoh, ekspor STL/3MF, uji di browser

## Perubahan yang Sudah Dibuat

## Catatan
