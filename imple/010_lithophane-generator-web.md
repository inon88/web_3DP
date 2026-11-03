# [010] Web: generator Lithophane (mesin JavaScript) + mode di atas dropdown

**Tanggal:** 2026-11-03
**Status:** done

## Masalah
App desktop sudah punya generator Lithophane JavaScript (App `imple/048`–`051`): 9 bentuk, posisi foto (G/R/S di viewport), pratinjau beresolusi ekspor, kontur halus, dan pengalih mode Lithophane | SCAD tools di atas dropdown. Pengguna meminta fitur yang sama di web.

## Rencana Perubahan
- [x] `scripts/sync-from-app.mjs` — tambah modul `lithophane`; `npm run sync` (juga `heightmap` baru: `LITHOPHANE_LIMITS`, `decodeGrayPng`)
- [x] `src/platform/library.js` — tool generator bawaan di depan pustaka
- [x] `src/platform/render-job.js` — `validateParameterValues` dipisah (dipakai generator)
- [x] `src/platform/lithophane.js` (baru) + `src/workers/lithophane.worker.js` (baru) — worker browser, batal per kanal, batas waktu; zip 3MF lewat fflate
- [x] `src/platform/web-api.js` — render/ekspor generator; `saveHeightmapAsset` menerima `lithophane_image_file`; `deleteTool` generator
- [x] `src/renderer.js`, `index.html`, `src/styles.css` — port perubahan UI App (kontrol & modal gambar lithophane, label sumber, mode switch)
- [x] Test (`test/`), build, verifikasi di browser

## Perubahan yang Sudah Dibuat
- [x] `scripts/sync-from-app.mjs` — `lithophane` di `MODULES`; `npm run sync` → `src/shared/lithophane.js` baru, `src/shared/heightmap.js` diperbarui (modul lain hanya beda akhir baris).
- [x] `src/platform/library.js` — `GENERATOR_TOOLS` (manifest dari `lithophaneManifest`, `revision: generator-<versi>`, `files: []`) di depan daftar `/library/index.json`.
- [x] `src/platform/render-job.js` — `validateParameterValues(tool, values)` diekspor; `prepareRenderJob` memakainya.
- [x] `src/workers/lithophane.worker.js` — decode PNG (`unzlibSync`), mesh, STL / 3MF (`zipSync`: pratinjau level 0 = tanpa kompresi, ekspor level 6), echo item `formforge-item`, `info.timings` per tahap.
- [x] `src/platform/lithophane.js` — `renderLithophane` (validasi, foto dari `session-files`, worker per kanal dengan batal & batas waktu), `isGeneratorTool`.
- [x] `src/platform/web-api.js` — `render` & `renderExport` bercabang untuk generator; `saveHeightmapAsset` menerima `lithophane_image_file` dengan `LITHOPHANE_LIMITS`.
- [x] `src/renderer.js`, `index.html`, `src/styles.css` — diff UI App (`imple/048`–`051`) diterapkan dengan `patch` (20/21 hunk otomatis, 1 manual karena teks petunjuk web berbeda): kontrol & modal gambar lithophane, label "Built-in generator", `canRender`, pengalih mode Lithophane | SCAD tools.
- [x] `test/lithophane.test.mjs` — 3 test (batas 1000 px + decode fflate; semua bentuk watertight + zip/unzip 3MF fflate; item foto → `image_x/_y/_rot/_size`). `npm test` 21 lulus; `npm run build` sukses (chunk worker ±30 kB).

## Catatan
- **Browser nyata** (`vite preview` + jendela Chromium via CDP): mode Lithophane → dropdown non-aktif (18 tool SCAD, tanpa Lithophane), unggah foto 1000 px → Circle 488 rb segitiga; klik foto → "Active · Image"; G + geser → `image_x 21.5`, `image_y 7`, area kosong menjadi Light; SCAD tools → kembali ke Articulated Cube Keychain, model SCAD tampil. Screenshot dicek.
- Waktu worker generator di browser: 0,3–0,5 s (decode 5 ms, mesh 70–110 ms, XML 140–235 ms, zip 70–120 ms) setelah zip pratinjau tanpa kompresi (sebelumnya 0,65–1,0 s). Total di UI ±2,8–3,2 s, sebagian besar parsing 3MF oleh viewer.
- **Jebakan pengukuran:** jendela uji yang tersembunyi diberi prioritas Idle oleh Windows (`visibility hidden`): loop CPU 608 ms vs 44 ms di Node → render tampak 22 s. Diukur ulang dengan jendela terlihat (`backgroundThrottling: false`). Di tab browser yang aktif kecepatannya normal.
- Pindah tool dengan parameter berubah tetap memakai `confirm()` bawaan (perilaku lama, bukan dari tugas ini).
- Belum diuji end-to-end di web: tombol Export (dialog simpan / unduhan butuh gestur pengguna). Jalurnya sama dengan render (format `stl`/`3mf`), dan writer-nya diuji di test.
- Foto di web tetap hanya di memori tab (prinsip §15).
