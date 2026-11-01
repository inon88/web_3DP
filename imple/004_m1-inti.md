# [004] M1 — inti versi web

**Tanggal:** 2026-11-01
**Status:** done

## Masalah
Bangun inti BonaStudio Web sesuai `rancangan.md` §9 M1: proyek Vite, sinkron modul dari App, worker render, viewport + parameter (UI App dipakai ulang), cache render (S3), debounce adaptif (S5), pratinjau kualitas ekspor bila cepat (S8), undo/redo, ekspor STL/3MF. Permintaan tambahan di tengah jalan: gunakan CDN jika memungkinkan.

## Rencana Perubahan
- [x] `package.json`, `vite.config.js`, `.gitignore` — proyek Vite 8 + three + fflate
- [x] `scripts/sync-from-app.mjs` — modul murni App → `src/shared/*.js` (ESM)
- [x] `scripts/fetch-assets.mjs` — WASM + font Liberation dengan hash dipatok
- [x] `scripts/build-library.mjs` — pustaka dari `../examples`
- [x] `src/platform/*` — `window.formforge` versi browser
- [x] `src/workers/render.worker.js` — OpenSCAD WASM, `--backend=manifold`
- [x] `src/renderer.js` — adaptasi web, undo/redo, S5, info kualitas/cache
- [x] `index.html`, `src/main.js`, `src/web.css`
- [x] Verifikasi di Chrome (build produksi + header keamanan)

## Perubahan yang Sudah Dibuat
- [x] `package.json` — vite 8.3.5, three 0.179.1 (sama dengan App), fflate 0.8.3, buffer 6.0.3 (hanya dimuat saat ekspor); skrip `build` (mandiri) & `build:full` (butuh `..`)
- [x] `vite.config.js` — header CSP/COOP/COEP/nosniff/Referrer/Permissions untuk dev & preview; origin CDN masuk `connect-src`; chunk `three` terpisah
- [x] `scripts/sync-from-app.mjs` — konversi CJS→ESM otomatis (8 modul), normalisasi CRLF, shim `zlib`/`Buffer`/`crypto`, gagal keras bila ada `require` tersisa; UI hanya disalin bila belum ada (`--ui` untuk menimpa)
- [x] `scripts/fetch-assets.mjs` — salin WASM dari `../vendor` (SHA-256 dipatok), unduh Liberation 2.1.5 (SHA-256 dipatok, untar tanpa dependensi), tulis `src/platform/asset-manifest.json` (SRI)
- [x] `scripts/build-library.mjs` — 17 tool → `public/library/<id>/` + `index.json` (parameter ter-parse, daftar file, `revision` hash untuk kunci cache)
- [x] `src/platform/settings.js` — localStorage, validasi sama dengan desktop, default web: jeda 250 ms, tema sistem
- [x] `src/platform/fonts.js` — 12 font Liberation + alias (Arial→Liberation Sans, Times→Serif, Courier→Mono, dll.)
- [x] `src/platform/library.js` — indeks & file tool (cache per revisi)
- [x] `src/platform/render-job.js` — port validasi `prepareRenderJob`/`validateNestedTree`; nama font diganti ke font bawaan (termasuk elemen nested)
- [x] `src/platform/engine.js` — compileStreaming sekali + progres unduhan, worker per render, batal per kanal, timeout, cache LRU 64 MB (S3), policy Trusted Types untuk URL worker
- [x] `src/platform/assets.js` — `VITE_ASSET_BASE` (CDN opsional) + `fetch(..., { integrity })`
- [x] `src/platform/export.js` — `showSaveFilePicker` (Chrome/Edge) atau unduhan biasa
- [x] `src/platform/web-api.js` — `window.formforge` (21 fungsi; yang belum didukung memberi pesan jelas), S8, ekspor dengan transform + 3MF parts, per plate → satu ZIP
- [x] `src/platform/zlib-shim.js` — `inflateRawSync`/`deflateRawSync` via fflate
- [x] `src/workers/render.worker.js` — port `scad-render-worker.cjs`, `--backend=manifold` dipatok
- [x] `src/web/history.js` — undo/redo dengan penggabungan perubahan cepat (600 ms)
- [x] `src/renderer.js` — impor ESM, alias font, undo/redo (Ctrl+Z, Ctrl+Shift+Z/Ctrl+Y; reset & preset bisa di-undo), S5 (jeda 150 ms bila render < 400 ms), info "export quality / model's resolution / From cache", status unduhan mesin, teks khusus web, pengaturan folder ekspor & icon folder disembunyikan
- [x] `index.html` — CSP meta dihapus (pakai header), entry `/src/main.js`, tombol fitur M3 diberi `web-unavailable`
- [x] `src/main.js`, `src/web.css`, `public/assets/app-icon.svg`
- [x] `test/` — 6 tes (modul tersinkron, zip via shim, scad-assets, undo/redo, alias font): semua lulus
- [x] `rancangan.md` — §12 catatan M1 (keputusan CDN, kinerja nyata, S6 ditunda)

## Catatan
- Verifikasi Chrome (`vite preview`, header keamanan aktif, `crossOriginIsolated = true`, konsol bersih): 17/17 tool merender (Decorative letter lewat UI), render pertama 0,14–2,0 s, ulang dari cache 0–2 ms; undo/redo kembali ke ukuran benar dari cache; ekspor STL (ukuran file = 84 + 50 × segitiga), 3MF (ZIP valid), per plate (ZIP), transform (rotasi 90° Z menukar X/Y). Ekspor diuji dengan `showSaveFilePicker` tiruan di halaman — tidak ada file yang benar-benar disimpan.
- Belum diuji: jalur unduhan biasa (Firefox/Safari), mode CDN nyata (butuh repo publik + tag), ponsel.
- Memanggil `formforge.render` dengan nilai default mentah gagal untuk `c-decorativelatter` (warna nested kosong); UI menormalkan nilai lebih dulu, sama seperti desktop.
- Kebanyakan tool menetapkan `$fn` sendiri, jadi S8 jarang aktif di pustaka saat ini.
- `public/openscad`, `public/fonts`, `public/library` ikut di-commit agar deploy mandiri (tanpa `..`) bisa membangun dengan `npm run build`.
