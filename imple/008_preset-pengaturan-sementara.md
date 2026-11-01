# [008] Preset dan pengaturan sementara (tanpa localStorage)

**Tanggal:** 2026-11-01
**Status:** done

## Masalah
Setelah [007] file unggahan sudah hanya di memori, tetapi preset (renderer.js) dan pengaturan (settings.js) masih
ditulis ke localStorage. Pengguna minta keduanya juga sementara: web tidak menyimpan data apa pun di browser.

## Rencana Perubahan
- [x] `src/platform/settings.js` — pengaturan di variabel memori, bukan localStorage
- [x] `src/platform/session-store.js` (baru) — penyimpanan preset di memori
- [x] `src/renderer.js` — preset baca/tulis/hapus lewat session-store (WEB)
- [x] `src/main.js` — sekali saat mulai, hapus kunci lama BonaStudio dari localStorage (sisa versi sebelumnya)
- [x] `test/` — pengaturan tidak menyentuh localStorage; preset per tool
- [x] Verifikasi browser: simpan preset + ubah pengaturan → localStorage tetap kosong; refresh → kembali ke default

## Perubahan yang Sudah Dibuat
- [x] `src/platform/settings.js` — `stored` di memori; validasi tidak berubah
- [x] `src/platform/session-store.js` — `sessionStore` (Map) + `forgetStoredData()` (hapus hanya kunci `bonastudio:`/`formforge:`)
- [x] `src/renderer.js` — 3 titik localStorage → `sessionStore`; teks: modal "Save preset", toast preset/pengaturan, status awal
- [x] `src/main.js` — panggil `forgetStoredData()` sebelum UI dimulai
- [x] `test/session-store.test.mjs` (baru) — 18/18 test lolos
- [x] `rancangan.md` §15

## Catatan
- Browser (build produksi): kunci lama yang sengaja diisi terhapus saat halaman dimuat; preset "Uji sementara" muncul di
  daftar dan tema berubah, sementara localStorage/sessionStorage/IndexedDB tetap kosong; setelah refresh preset hilang,
  tema kembali `system`, jeda pratinjau 250 ms; console bersih.
- Tidak ada lagi `localStorage.setItem` di kode web (selain vendor). App desktop tidak diubah.
