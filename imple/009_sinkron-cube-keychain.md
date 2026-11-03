# [009] Sinkron perbaikan articulated cube keychain ke pustaka web

**Tanggal:** 2026-11-02
**Status:** done

## Masalah
Link horizontal (datar) pada `articulated_cube_keychain.scad` diperbaiki di app desktop
(`App/imple/045_perbaiki-link-datar-cube-keychain.md`). Pustaka web berisi salinan file contoh itu.

## Rencana Perubahan
- [x] `public/library/` — `npm run library` (salin ulang dari `../examples`); pastikan hanya tool ini yang berubah
- [x] Verifikasi di web (build produksi): tool render, hasil ekspor identik dengan desktop

## Perubahan yang Sudah Dibuat
- [x] `public/library/articulated-cube-keychain/articulated_cube_keychain.scad` — versi baru
- [x] `public/library/index.json` — revisi tool `09cc626991e4a9f1` → `7da53cfa13b65186` (cache render lama otomatis tidak dipakai)

## Catatan
- Isi tool lain tidak berubah (git hanya menandai perbedaan line ending).
- Ekspor STL default di web identik byte-per-byte dengan desktop (sha256 `8738d5fee617aef9…`); render "ABC" 0,20 s.
- `npm test` 18/18.
