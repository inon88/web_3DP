# [012] Font Google: Coiny, Chewy, Gorditas

**Tanggal:** 2026-11-07
**Status:** done

## Masalah
Pengguna minta Coiny, Chewy, dan Gorditas menjadi font bawaan app desktop dan web (app: `../imple/053`).

## Rencana Perubahan
- [x] `scripts/google-fonts.mjs` — tambah family di `FAMILIES` (Display); `npm run google-fonts` → `src/platform/google-fonts.json`
- [x] Verifikasi: test, render teks dengan tiap font di browser

## Perubahan yang Sudah Dibuat
- [x] `scripts/google-fonts.mjs` — `Coiny` 400, `Chewy` 400, `Gorditas` 400/700 (Display)
- [x] `src/platform/google-fonts.json` — 4 entri baru (url gstatic + SRI); total 66 font

## Catatan
- Coiny tidak ber-hinting (`hinted: false`) → program font kosong saat dimuat; Chewy & Gorditas ber-hinting.
- Chrome (build produksi): Default Name Keychain dengan tiap font dirender (3MF 136–268 KB, berbeda per font). `npm test` 35/35.
- File TTF yang sama juga dibundel di app desktop (`../fonts/`, `../imple/053`).
