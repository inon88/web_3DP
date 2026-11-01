# [003] Uji teknis M0 — mesin render (Manifold vs CGAL)

**Tanggal:** 2026-11-01
**Status:** done

## Masalah
Sebelum membangun UI, ukur kinerja OpenSCAD WASM (snapshot 2026.10.11) pada contoh pustaka, dan pastikan `--backend=manifold` didukung serta hasilnya setara.

## Rencana Perubahan
- [x] `spike/bench-engine.mjs` + `spike/bench-worker.mjs` — tiap contoh dirender dengan default / CGAL / Manifold (pratinjau) + Manifold (ekspor); waktu, ukuran, jumlah segitiga
- [x] `spike/browser/` — halaman minimal: compileStreaming sekali + module worker per render, parsing STL di worker, header keamanan lengkap
- [x] `rancangan.md` — hasil uji di bagian 11

## Perubahan yang Sudah Dibuat
- [x] `spike/bench-engine.mjs`, `spike/bench-worker.mjs` — benchmark Node (CGAL ekspor hanya dengan `--cgal-export`, karena makan menit per model)
- [x] `spike/browser/serve.mjs`, `index.html`, `main.js`, `render.worker.js` — uji di Chrome dengan CSP + Trusted Types + COOP/COEP
- [x] `spike/bench-export.log`, `spike/bench-results-export.json` — data mentah
- [x] `rancangan.md` — bagian 11, S1 diperjelas, S4 dibatalkan, S8 ditambahkan, catatan Trusted Types untuk Worker

## Catatan
- Snapshot 2026.10.11 sudah memakai Manifold sebagai default (17/17 contoh identik). CGAL 15–225× lebih lambat.
- Kualitas ekspor dengan Manifold ≤ 1,6 s untuk semua contoh → pratinjau bisa langsung di kualitas ekspor (S8).
- Instantiate per render 8–15 ms → instance cadangan tidak perlu.
- Trusted Types memblokir `new Worker(url)` tanpa `TrustedScriptURL` → perlu policy `worker-url`.
- Font di spike memakai Arial dari Windows (hanya lokal); produksi memakai Liberation (bagian 4).
