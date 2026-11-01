# [006] Font Google Fonts lewat link (khusus web)

**Tanggal:** 2026-11-01
**Status:** done

## Masalah
Web hanya punya 12 font Liberation; desktop bisa memakai semua font sistem (mis. Segoe Script di
decorated-font jatuh ke Liberation Sans). Pengguna minta font Google bisa dipakai di web, **hanya untuk
web**, lewat **link referensi** (bukan file font disimpan di repo/Vercel).

Temuan teknis:
- OpenSCAD butuh byte TTF/OTF di sistem file virtual; `<link>` CSS saja tidak cukup.
- Google mengirim TTF *tanpa hinting* (tanpa tabel `fpgm`) ke klien modern → FreeType di OpenSCAD WASM
  crash (aturan `fontSupportsOpenScadWasm` dari app). Ke klien Windows lama Google mengirim **WOFF ber-hinting**
  → lolos. WOFF1 = tabel sfnt yang di-zlib, bisa diubah ke TTF tanpa kehilangan apa pun.
- `fonts.gstatic.com` mengirim `Access-Control-Allow-Origin: *` + `Cross-Origin-Resource-Policy: cross-origin`
  + cache 1 tahun → aman dengan COEP `require-corp`.

## Rencana Perubahan
- [x] `src/shared/woff.js` — konversi WOFF1 → TTF (fflate), dipakai browser & skrip
- [x] `scripts/google-fonts.mjs` — daftar keluarga font; ambil URL WOFF dari Google Fonts CSS API,
      cek kompatibel OpenSCAD, baca nama fontconfig, tulis `src/platform/google-fonts.json` (url + SRI)
- [x] `src/platform/fonts.js` — gabung Liberation + Google; `fontData` ambil dari gstatic dengan SRI lalu konversi;
      alias Segoe Script → Dancing Script, Comic Sans → Comic Neue, Impact → Anton
- [x] `src/web/font-preview.js` + `src/main.js` — pratinjau font terpilih lewat `FontFace` (hanya font yang dipilih diunduh)
- [x] `security-headers.mjs`, `vercel.json` — `connect-src` + `https://fonts.gstatic.com`
- [x] `package.json` — skrip `google-fonts`
- [x] `test/` — uji WOFF→TTF, daftar font, alias
- [x] Verifikasi: render tiap font Google di engine (Node) + di browser (build produksi)

## Perubahan yang Sudah Dibuat
- [x] `src/shared/woff.js` — `woffToSfnt`, `makeOpenScadCompatible` (tambah `fpgm` kosong untuk font tanpa hinting), `fontForOpenScad`
- [x] `scripts/google-fonts.mjs` + `src/platform/google-fonts.json` — 40 keluarga / 62 font (3,9 MB total, diunduh per font saat dipilih)
- [x] `src/platform/fonts.js` — daftar gabungan 74 font diurutkan; alias baru; resolusi nama per keluarga (mis. `Roboto:style=Regular` → `Roboto`, gaya yang tidak ada → yang terdekat)
- [x] `src/web/font-preview.js`, `src/main.js` — pratinjau font terpilih
- [x] `src/platform/render-job.js` — pesan error font menyebut Google Fonts
- [x] `src/renderer.js` — teks bantuan pemilih font (WEB)
- [x] `security-headers.mjs`, `vercel.json` — `connect-src 'self' https://fonts.gstatic.com`
- [x] `package.json` — `npm run google-fonts`
- [x] `test/fonts.test.mjs` — round-trip WOFF, perbaikan fpgm, daftar link + SRI, alias (11/11 test lolos)
- [x] `rancangan.md` §4 dan §14

## Catatan
- Uji awal "WOFF ber-hinting lolos" ternyata salah: pemeriksa membaca byte WOFF mentah. Setelah dikonversi, 35 dari 62
  font tidak punya `fpgm`. Dipastikan di engine: tanpa perbaikan → crash; dengan `fpgm` kosong → semua 62 font render
  (lebar teks berbeda antar-ketebalan, jadi font asli yang dipakai, bukan font cadangan).
- Browser (build produksi): Pacifico, Dancing Script (alias Segoe Script di decorated-font) dan Poppins Bold render dan
  tampil di pratinjau; console bersih, tanpa pelanggaran CSP.
- "Macet" saat uji ternyata dialog `confirm()` "unsaved parameter changes" ketika pindah tool (perilaku sama dengan desktop),
  bukan bug.
- App desktop tidak diubah.
