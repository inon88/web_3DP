# [011] Unduhan Firefox/Safari, tampilan ponsel, PWA + galeri, impor tool sendiri

**Tanggal:** 2026-11-07
**Status:** done (uji Firefox/WebKit menyusul)

## Masalah
Empat sisa pekerjaan web (dari ringkasan proyek):
1. Jalur unduhan biasa (tanpa File System Access API) di Firefox/Safari belum diuji. Unduhan dipicu setelah render
   yang bisa berlangsung lama, sehingga gestur pengguna sudah kedaluwarsa (Safari bisa memblokir).
2. Tampilan ponsel: `html, body { min-width: 960px }`, sidebar tetap 304 px. Tidak bisa dipakai di ponsel.
3. PWA + galeri (M2).
4. Impor tool sendiri (M3): SCAD file, project folder, from URL, hapus tool, parameter kustom.

Keputusan pengguna (2026-11-07):
- Tool impor **hanya sesi** (di memori tab, hilang saat refresh), sama dengan prinsip §15.
- **PWA penuh + offline.** Cache Storage hanya berisi file aplikasi (UI, WASM, font, pustaka), tidak pernah data pengguna.

## Rencana Perubahan
- [x] `src/platform/export.js`, `src/platform/web-api.js`, `src/renderer.js` — unduhan fallback: klik otomatis bila
      gestur masih aktif, kalau tidak tombol "Download" di modal (gestur baru); label "Preparing…" bila tanpa dialog simpan
- [x] `src/platform/session-tools.js` (baru) — tool impor di memori: file `.scad`, folder proyek (pilih file utama),
      URL HTTPS (GitHub blob → raw, batas 10 MB, timeout 15 s), hapus, parameter kustom; batas sama dengan desktop
- [x] `src/platform/library.js`, `render-job.js` — gabung tool sesi; aset `user-assets` di samping file entry;
      galat jelas bila `import()`/`surface()` merujuk file yang tidak ada
- [x] `src/renderer.js`, `index.html` — tombol Add tool/Delete/Add custom parameter aktif; modal pilih file utama;
      konfirmasi hapus lewat modal; seret & lepas `.scad`/folder; teks "hanya sesi"
- [x] `security-headers.mjs`, `vercel.json` — `connect-src https:` (impor URL), `/sw.js` no-cache
- [x] Tampilan ponsel (`src/web.css`, `index.html`, `src/renderer.js`) — < 900 px: sidebar jadi panel geser + backdrop,
      tombol buka di topbar, toolbar viewport bisa digeser, `100dvh`, modal/toast penuh lebar
- [x] PWA: `public/manifest.webmanifest`, ikon PNG 192/512/maskable, service worker dihasilkan saat build
      (plugin di `vite.config.js`: daftar precache + versi hash), `src/web/pwa.js` (daftar setelah mesin siap,
      banner "versi baru", tombol Install)
- [x] Galeri: `scripts/build-library.mjs` (deskripsi dari komentar awal `.scad`), modal galeri (kartu + cari),
      dibuka saat mulai dan dari tombol Browse; thumbnail `public/gallery/<id>.webp` dari `scripts/gallery-thumbnails.mjs`
- [x] `test/` — session-tools, URL, sw/precache, manifest
- [x] `rancangan.md` — catatan §16
- [x] Verifikasi: `npm test`, `npm run build`, Chrome (desktop + emulasi ponsel + offline)
- [ ] Verifikasi Firefox & WebKit (Playwright) — menyusul

## Perubahan yang Sudah Dibuat
- [x] `src/platform/export.js` — `hasSaveDialog`, `writeTarget` mengembalikan `{ download }` bila gestur habis (`navigator.userActivation`); `web-api.js` meneruskannya; renderer: modal *Your file is ready* + tombol Download, label "Preparing…"
- [x] `src/platform/session-tools.js` (baru) — impor file/folder/URL, pilih file utama, hapus, parameter kustom, `missingReferencedFiles`; `describe.js` (baru) — deskripsi galeri
- [x] `src/platform/library.js` — tool sesi + parameter kustom digabung; generator punya deskripsi & gambar
- [x] `src/platform/render-job.js` — galat file `import()`/`surface()` hilang; `user-assets` di folder entry
- [x] `src/platform/session-files.js` — `forgetToolAssets`
- [x] `src/platform/web-api.js` — `importFile`, `importProject`/`importProjectEntry`, `importDropped`, `importUrl`, `deleteTool`, `addParameter`, `saveDialog`
- [x] `src/web/drop-import.js`, `src/web/gallery.js`, `src/web/pwa.js` (baru)
- [x] `src/renderer.js` — modal pilih file utama, seret & lepas, konfirmasi hapus, unduhan, galeri saat mulai + Browse, panel ponsel
- [x] `index.html` — tombol Add/Delete/Custom parameter aktif, Browse, Parameters (ponsel), Install, overlay drop, manifest & ikon
- [x] `src/web.css` — galeri, impor, overlay, banner pembaruan, tata letak < 900 px (sheet bawah / panel kiri lanskap), target sentuh
- [x] `public/manifest.webmanifest`, `public/assets/app-icon-{180,192,512,maskable-512}.png` (dirender dari `app-icon.svg` dengan Chrome headless)
- [x] `scripts/service-worker.mjs` + `service-worker.template.js` (baru), `vite.config.js` — `dist/sw.js` saat build
- [x] `scripts/gallery-thumbnails.mjs` (baru, `npm run thumbnails`) → `public/gallery/*.webp` (19 gambar, 372 KB); `scripts/build-library.mjs` — `description`, `thumbnail`
- [x] `security-headers.mjs`, `vercel.json` — `connect-src 'self' https:`; `/sw.js` & manifest `no-cache`
- [x] `test/session-tools.test.mjs`, `test/pwa.test.mjs` (baru) — `npm test` 35/35
- [x] `rancangan.md` — §16; tabel §4 dan §15 disesuaikan

## Catatan
- Verifikasi Chrome (Playwright + Chrome terpasang, build produksi, `vite preview`): galeri 19 kartu bergambar + pencarian; drop `.scad` → render 20 mm; folder 2 `.scad` → pemilih; impor URL GitHub (`CSG.scad`) → raw, render; hapus via modal; parameter kustom; ekspor tanpa `showSaveFilePicker` → unduhan otomatis; SW aktif (63 file precache + runtime), **offline reload → galeri tampil & Name Zigzag dirender**; `crossOriginIsolated` tetap true; ponsel 390×844 tanpa scroll horizontal, sheet & modal dicek lewat screenshot; lanskap 844×390 panel kiri. Konsol tanpa galat.
- Diperbaiki setelah screenshot: footer viewport terpotong di ponsel (kini satu baris), panel lanskap terpotong di atas.
- `index.json`: hanya field `description`/`thumbnail` bertambah; revisi tool tidak berubah (cache render tetap berlaku).
- `connect-src https:` memperlebar CSP (sudah direncanakan §7) — diperlukan karena impor URL bisa dari host mana pun yang mengizinkan CORS.
- Firefox & WebKit (jalur unduhan nyata) belum diuji: unduhan browser Playwright sangat lambat; diuji menyusul.
