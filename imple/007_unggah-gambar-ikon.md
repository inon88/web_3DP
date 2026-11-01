# [007] Unggah gambar/ikon, trace, relief, icon pack (web, sementara)

**Tanggal:** 2026-11-01
**Status:** done

## Masalah
Di web, tombol *Choose image*, *Icon library*, trace warna, relief (filament-painting) dan SVG elemen
decorative layers masih stub ("not available in the web version yet"). Pengguna minta fitur ini dibuat,
dengan syarat: **web tidak menyimpan data** — file unggahan hanya sementara (hilang saat tab ditutup/refresh).

## Rencana Perubahan
- [x] `src/platform/session-files.js` — penyimpanan di memori: aset per tool (`user-assets/<uuid>.svg|png`) + icon pack; batas ukuran
- [x] `src/platform/web-api.js` — `chooseParameterFile` (input file), `saveIconAsset`, `saveHeightmapAsset`, `traceImage`,
      `iconIndex`/`readIcons`/`readIcon`, `openIconFolder` (pilih folder SVG → icon pack sesi)
- [x] `src/platform/render-job.js` — sertakan aset sesi yang dirujuk parameter; pesan jelas bila sudah hilang
- [x] vtracer (trace warna): `package.json` devDependency `@visioncortex/vtracer@1.0.0-alpha.4`;
      `scripts/fetch-assets.mjs` — WASM ber-hash ke `public/vtracer/<versi>/`, glue → `src/vendor/vtracer/vtracer.js` (ESM)
- [x] `scripts/sync-from-app.mjs` — ikut sinkron `image-trace.cjs`
- [x] `src/platform/trace.js` + `src/workers/trace.worker.js` — trace di Web Worker, batas waktu 60 s (sama dengan desktop)
- [x] `src/renderer.js` — teks web (icon pack sementara, tombol "Add icon folder", muat ulang daftar otomatis)
- [x] `test/` — penyimpanan sesi, rujukan aset, trace vtracer
- [x] Verifikasi di browser (build produksi): SVG, PNG→trace, relief filament-painting, icon pack, decorative layers

## Perubahan yang Sudah Dibuat
- [x] `src/platform/session-files.js` (baru) — aset per tool di memori (maks 200 MB/sesi), icon pack dari handle `File`
- [x] `src/platform/file-picker.js` (baru) — dialog file/folder browser, termasuk batal (`cancel`)
- [x] `src/platform/trace.js`, `src/workers/trace.worker.js` (baru) — vtracer di Web Worker, WASM dimuat saat pertama dipakai
- [x] `src/platform/web-api.js` — 7 stub diganti implementasi; validasi sama dengan desktop
- [x] `src/platform/render-job.js` — aset sesi ikut ke render/ekspor
- [x] `src/platform/engine.js` — `createModuleWorker` dipakai bersama (satu kebijakan Trusted Types)
- [x] `src/platform/assets.js` — `VTRACER_PATH`
- [x] `scripts/fetch-assets.mjs` — vtracer WASM + glue ESM (hash dikunci); `asset-manifest.json` kini 14 hash
- [x] `scripts/sync-from-app.mjs` — `image-trace` ikut disinkron → `src/shared/image-trace.js`
- [x] `src/renderer.js` — teks web untuk pemilih gambar, relief, icon library; daftar ikon dimuat ulang otomatis
- [x] `vercel.json` — cache immutable `/vtracer/`
- [x] `package.json`/`package-lock.json` — devDependency vtracer
- [x] `test/session-files.test.mjs` (baru), `test/vercel.test.mjs` — 15/15 lolos
- [x] `rancangan.md` §4, §15

## Catatan
- Uji di Chrome (build produksi; dialog file OS diganti file buatan, sisa alur asli):
  svg-icon-to-3d + SVG bintang ✓; PNG 3 warna → trace "Color layers" → 3 lapisan + `icon_left_colors` terisi ✓;
  filament-painting + JPG → "Prepare relief" → 360 436 segitiga ✓; pet-bowl-stand + icon pack 3 ikon (file .txt dilewati) ✓;
  c-decorativelatter elemen SVG ✓; ekspor STL dengan aset sesi 155 KB ✓; console bersih.
- Setelah refresh: IndexedDB, Cache Storage, sessionStorage kosong; icon pack 0 — tidak ada data unggahan tersimpan.
- Preset dan pengaturan tetap di localStorage (fitur lama, disimpan eksplisit oleh pengguna). Preset yang merujuk gambar
  sesi lama memberi pesan untuk memilih gambar lagi.
- App desktop tidak diubah.
