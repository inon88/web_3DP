# Rancangan BonaStudio Web

Versi web dari aplikasi desktop **BonaStudio** (folder induk `..`). Pengguna membuka situs, memilih model dari pustaka contoh, mengubah parameter, melihat pratinjau 3D, lalu mengunduh STL/3MF. Semua render terjadi **di browser pengguna**: tanpa server render, tanpa akun, dan bisa dipakai offline setelah kunjungan pertama.

---

## 0. Lokasi & repositori

- Proyek web berada di `D:\_FRELENCE\hadi\App\web`; sumber modul desktop adalah folder induk (`..`), **bukan** `../App`.
- `web/` di-*ignore* oleh repo App (`/web/` di `.gitignore`), jadi **web perlu repo git sendiri** (`git init` di `web/`) sebelum kode ditulis.

---

## 1. Tujuan & batasan

| Tujuan | Ukuran keberhasilan |
|---|---|
| Fitur inti setara desktop | Pilih tool → ubah parameter → pratinjau otomatis → ekspor STL/3MF resolusi maksimum |
| Cepat | UI tampil < 1 detik (koneksi biasa); mesin render diunduh di latar belakang dan di-cache; render ulang tidak memuat ulang WASM |
| UX terbaik | Langsung bisa dipakai tanpa instalasi, galeri pustaka, tautan berbagi, offline, bisa di-*install* (PWA), dapat dipakai di tablet/ponsel |
| Hosting gratis & statis | Hanya file statis → Vercel / Cloudflare Pages / GitHub Pages |
| Privasi | File & data pengguna tidak pernah dikirim ke server |

Di luar cakupan: akun/login, sinkronisasi antarperangkat, render di server.

---

## 2. Pilihan teknologi

| Lapisan | Pilihan | Alasan |
|---|---|---|
| Build & dev server | **Vite 8** | Bundler web tercepat saat ini (Rolldown), dev server instan + HMR, dukungan Web Worker & WASM bawaan, code-splitting otomatis |
| UI | **Vanilla JS (ES modules)** — UI dari App dipakai ulang | UI desktop sudah matang & teruji (±2.800 baris). Menulis ulang dengan React/Svelte menambah ukuran bundle dan risiko regresi tanpa manfaat UX. Tanpa framework = JS awal lebih kecil = tampil lebih cepat |
| Pratinjau 3D | **Three.js 0.179** (sama dengan App) | Sudah dipakai: orbit, gizmo transform, loader 3MF |
| Mesin render | **OpenSCAD WebAssembly** (build resmi `-web`) di **Web Worker** | Render tidak membekukan UI; worker bisa dihentikan saat parameter berubah (pratinjau terasa responsif) |
| Kompilasi WASM | `WebAssembly.compileStreaming` sekali, modul dibagikan ke tiap worker | Render ulang tidak mengompilasi ulang 11 MB WASM |
| Trace gambar | **vtracer WASM** di Web Worker | Sama dengan App, glue Node diubah ke ESM browser |
| ZIP (3MF, ekspor multi-plate) | **fflate** | Pustaka zip tercepat & kecil (±8 KB), pengganti `node:zlib` |
| Penyimpanan | **IndexedDB** (pembungkus kecil buatan sendiri) + `localStorage` untuk pengaturan/preset | Menyimpan tool impor, aset, icon pack, thumbnail; kapasitas besar |
| Offline & install | **vite-plugin-pwa** (Workbox) | Service worker precache UI + WASM + font; aplikasi bisa di-*install* dari browser |
| Hosting | **Vercel** (statis), `vercel.json` untuk header cache | Gratis, CDN global; bisa juga Cloudflare Pages |

---

## 3. Arsitektur

```
Browser
├── UI thread
│   ├── src/renderer.js        ← UI App (parameter, preset, viewport, transform, modal)
│   ├── src/web/gallery.js     ← galeri pustaka + layar sambutan
│   └── src/platform/web-api.js  → window.formforge  (API sama dengan preload.cjs desktop)
│        ├── library.js        ← pustaka bawaan (public/library) + tool impor (IndexedDB)
│        ├── storage.js        ← IndexedDB + localStorage
│        ├── engine.js         ← kompilasi WASM, pool worker, batal/timeout
│        ├── fonts.js          ← font bawaan + font perangkat (Local Font Access API)
│        ├── files.js          ← pemilih file/folder, unduhan, File System Access API
│        └── icons.js          ← icon pack (folder SVG yang diimpor)
├── Web Workers
│   ├── render.worker.js       ← OpenSCAD WASM (port dari scad-render-worker.cjs)
│   └── trace.worker.js        ← vtracer WASM
└── Service worker (PWA)       ← cache UI, WASM, font, pustaka
```

**Kunci desain: lapisan kompatibilitas `window.formforge`.** Renderer desktop memanggil 21 fungsi IPC (`render`, `export`, `importFile`, …). Versi web menyediakan objek dengan nama & bentuk data yang sama, diimplementasikan dengan API browser. Hasilnya, sebagian besar kode UI dipakai ulang apa adanya; perubahan di `renderer.js` hanya pada bagian yang memang berbeda di web (ekspor, folder, impor folder, pengaturan).

### Modul yang dipakai ulang dari App
`scripts/sync-from-app.mjs` menyalin modul murni dari folder induk (`..`) ke `src/shared/` dan mengubahnya ke ESM:
`parameters`, `transform`, `heightmap`, `raster-to-svg`, `svg-layers`, `font-name`, `image-trace`, `mesh-transform` (zlib → fflate, `crypto.randomUUID` browser), `scad-assets` (bagian murni). Perbaikan di App cukup disinkronkan ulang.

---

## 4. Pemetaan fitur desktop → web

| Fitur desktop | Versi web |
|---|---|
| Pustaka di `%APPDATA%` | **Pustaka bawaan** dari `examples/` (read-only, disajikan statis) + **tool impor pengguna** di IndexedDB |
| Add tool › SCAD file | `<input type=file>` + **seret & lepas** file `.scad` ke jendela |
| Add tool › Project folder | Pemilih folder (`webkitdirectory`) + pilih file utama bila ada beberapa `.scad` |
| Add tool › From URL | `fetch` langsung (butuh CORS dari sumber; pesan jelas bila diblokir; GitHub/raw didukung) |
| Hapus tool | Hanya tool impor; tool bawaan bisa "direset" |
| Render (worker Node) | Web Worker, WASM dikompilasi sekali, **render usang dibatalkan** saat parameter berubah |
| Ekspor (dialog simpan) | **File System Access API** (Chrome/Edge: dialog simpan asli) atau unduhan biasa (Firefox/Safari) |
| Ekspor per plate | Satu **file .zip** berisi semua plate (browser memblokir banyak unduhan sekaligus) |
| Folder ekspor default | Dihapus (ditentukan browser) |
| Font sistem | **Font bawaan Liberation** (Sans/Serif/Mono, metrik setara Arial/Times/Courier) + **62 font Google Fonts lewat link** (§14) + alias `Arial → Liberation Sans`, `Segoe Script → Dancing Script`, `Comic Sans MS → Comic Neue`, `Impact → Anton` dsb. Font perangkat (Local Font Access API) masih opsi M3. |
| Ikon/gambar parameter, trace, relief | Sama (trace = vtracer WASM di Web Worker); file **hanya di memori tab**, hilang saat halaman ditutup/refresh (§15) |
| Icon pack (folder) | Tombol **"Add icon folder…"** memilih folder SVG; hanya untuk sesi itu (§15) |
| Preset | `localStorage` (sama) |
| Pengaturan | `localStorage`; bagian folder ekspor dihilangkan |
| Judul aplikasi | Tetap bisa diubah (judul tab) |

---

## 5. User experience

1. **Langsung pakai.** Kunjungan pertama membuka **galeri pustaka** (kartu: nama, kategori, deskripsi singkat). Klik kartu → parameter & pratinjau.
2. **Mesin dimuat di latar belakang** dengan indikator progres ("Menyiapkan mesin render… 6,1 / 11 MB"); UI dan parameter sudah bisa disentuh selama itu. Kunjungan berikutnya instan (cache).
3. **Pratinjau responsif.** Render lama dihentikan saat parameter berubah; hasil terakhir tetap tampil sampai yang baru siap (perilaku App).
4. **Tautan berbagi.** Tombol **Share** menyalin URL berisi tool + nilai parameter yang diubah (`#tool=…&p=…`). Membuka tautan langsung menampilkan model yang sama.
5. **Seret & lepas** `.scad` / folder proyek ke mana saja di jendela.
6. **Offline & install.** Setelah dimuat sekali, berjalan tanpa internet; bisa dipasang sebagai aplikasi (PWA) di Windows/macOS/Android/ChromeOS.
7. **Responsif.** Desktop: tata letak App. Tablet/ponsel (< 900 px): sidebar menjadi panel geser, viewport penuh, tombol aksi besar.
8. **Thumbnail galeri** diambil otomatis dari pratinjau pertama tiap tool dan disimpan lokal.
9. **Pesan jelas** untuk batasan web (CORS impor URL, browser tanpa File System Access, model terlalu berat untuk perangkat).

### Tambahan kenyamanan (usulan 2026-11-01)

- **Undo/redo** parameter (Ctrl+Z / Ctrl+Shift+Z), penanda "berubah dari default", dan tombol reset per parameter.
- **Pulihkan sesi otomatis:** tool + nilai parameter terakhir dibuka kembali saat situs dikunjungi lagi.
- **Tautan berbagi ringkas:** parameter dikompres (fflate deflate) lalu base64url di `#p=…`.
- **Mobile:** parameter di *bottom sheet* yang bisa ditarik; viewport tetap penuh.
- **Progres jelas:** tahap render + estimasi waktu dari riwayat render tool tersebut; galat OpenSCAD dipetakan ke parameter/baris penyebab bila bisa.
- **Pembaruan PWA terlihat:** "Versi baru tersedia — muat ulang?" (bukan pembaruan diam-diam).
- **Penyimpanan awet:** `navigator.storage.persist()` agar tool impor tidak dihapus browser saat ruang menipis.
- **Aksesibilitas & pintasan:** navigasi keyboard penuh, fokus terlihat, `prefers-reduced-motion`, pintasan R (render), E (ekspor), `/` (cari parameter).

---

## 6. Performa

- JS awal hanya UI + Three.js (code-split); WASM OpenSCAD (11 MB) & vtracer dimuat lazy.
- `compileStreaming` → kompilasi sambil mengunduh; modul dikirim ke worker (tanpa kompilasi ulang).
- Instance OpenSCAD baru per render (OpenSCAD tidak aman dipakai ulang setelah `callMain`), tetapi tanpa unduh/kompilasi ulang.
- Service worker precache semua aset → kunjungan kedua tanpa jaringan.
- Header cache `immutable` untuk aset ber-hash (Vercel).
- Batas waktu sama dengan App: pratinjau 120 s, ekspor 5 menit + fallback resolusi model.

### Tambahan kecepatan (usulan 2026-11-01)

| # | Usulan | Dampak |
|---|---|---|
| S1 | **Backend Manifold dipatok eksplisit** (`--backend=manifold`). Uji M0: snapshot 2026.10.11 **sudah** memakai Manifold sebagai default (hasil identik), jadi ini pengaman agar snapshot berikutnya tidak diam-diam kembali ke CGAL (15–200× lebih lambat) | Pengaman |
| S2 | **Mesh pratinjau dibuat saat build** untuk parameter default tiap tool (+ thumbnail) → model tampil < 1 s walau WASM belum siap | Besar (kesan pertama) |
| S3 | **Cache hasil render** dengan kunci hash(tool + parameter + kualitas), di memori (LRU) + IndexedDB → undo/preset/kembali ke nilai lama tanpa render | Besar |
| S4 | ~~Instance cadangan~~ — **dibatalkan**: uji M0 menunjukkan instantiate dari modul terkompilasi hanya ±8–15 ms | — |
| S8 | **Pratinjau langsung di kualitas ekspor** bila render terakhir cepat (uji M0: semua contoh ≤ 1,6 s di kualitas ekspor). Kualitas pratinjau rendah hanya dipakai bila model terbukti berat → yang dilihat = yang dicetak | Besar (kenyamanan) |
| S5 | **Debounce adaptif:** jeda dari durasi render terakhir; slider dirender saat dilepas, bukan tiap gerak | Sedang |
| S6 | **Parsing mesh di worker:** worker mengirim `Float32Array` posisi/normal sebagai *transferable* → main thread tidak tersendat | Sedang |
| S7 | WASM disajikan **Brotli** (±11 MB → ±3 MB), unduhan dimulai saat idle setelah UI tampil (`requestIdleCallback`) | Sedang |

---

## 7. Keamanan & privasi

- Tidak ada backend; tidak ada data pengguna yang dikirim.
- CSP ketat (`script-src 'self' 'wasm-unsafe-eval'`, `worker-src 'self'`), `connect-src` dibuka hanya untuk impor URL HTTPS.
- Semua HTML dinamis tetap memakai `escapeHtml` (warisan App); SVG pengguna hanya ditampilkan lewat `<img>`.
- Validasi parameter sama dengan App (rentang, opsi, nested tree) sebelum render.
- Impor URL: hanya `https:`, tanpa kredensial, maks 10 MB.

### Tambahan keamanan (usulan 2026-11-01)

- **CSP sebagai header HTTP** di `vercel.json` (bukan `<meta>`), ditambah `frame-ancestors 'none'`, HSTS, `X-Content-Type-Options: nosniff`, `Referrer-Policy: no-referrer`, `Permissions-Policy` minimal, serta **COOP/COEP** (isolasi; membuka opsi WASM multi-thread nanti).
- **Trusted Types:** renderer desktop memakai `innerHTML` 21 kali (dijaga `escapeHtml`). Di web, pindahkan ke DOM API / satu policy, lalu aktifkan `require-trusted-types-for 'script'`. Uji M0: `new Worker(url)` juga butuh `TrustedScriptURL` → satu policy `worker-url` yang hanya menerima URL `.js` *same-origin*.
- **Tautan berbagi tidak membawa kode:** hanya ID tool pustaka + parameter yang divalidasi skema. Bila kelak mendukung berbagi `.scad` kustom → wajib konfirmasi pengguna.
- **Hash WASM dipatok di repo** (bukan mengunduh `.sha256` dari server yang sama dengan arsip, seperti `scripts/fetch-openscad-wasm.cjs` saat ini).
- **Batas sumber daya:** timeout + batas memori instance; worker di-`terminate()` bila terlampaui (juga untuk `.scad` tak tepercaya).
- **Impor URL:** `credentials: 'omit'`, periksa redirect tetap `https:`, batas 10 MB ditegakkan saat *streaming*.
- **Rantai pasok:** lockfile, `npm audit` + Dependabot di CI, dependensi seminimal mungkin.

---

## 8. Struktur folder

```
web/
├── index.html
├── public/
│   ├── library/          ← hasil build-library (salinan examples + index.json)
│   ├── openscad/         ← openscad.js + openscad.wasm (diunduh & diverifikasi)
│   ├── fonts/            ← Liberation fonts (OFL)
│   └── icons/            ← ikon PWA
├── src/
│   ├── main.js           ← entry: pasang window.formforge, lalu muat renderer
│   ├── renderer.js       ← UI (dari App, disesuaikan)
│   ├── styles.css
│   ├── platform/         ← web-api, storage, library, engine, fonts, files, icons
│   ├── workers/          ← render.worker.js, trace.worker.js
│   ├── shared/           ← modul murni dari App (disinkronkan)
│   └── vendor/vtracer/   ← glue vtracer versi ESM
├── library-src/          ← salinan examples dari App (sumber pustaka)
├── scripts/              ← sync-from-app, fetch-assets, build-library
├── imple/
├── rancangan.md
├── vite.config.js
└── vercel.json
```

---

## 9. Fase

Fase 1 dipecah menjadi milestone agar keputusan teknis teruji sebelum UI dibangun:

| Milestone | Isi |
|---|---|
| **M0 — uji teknis** | OpenSCAD WASM: CGAL vs Manifold pada semua contoh; WASM di Web Worker browser (kompilasi sekali, instance per render). Hasil → bagian 11 |
| **M1 — inti** | Proyek Vite, sinkron modul, worker render, viewport + parameter, S3 cache, S5 debounce adaptif, S6 parsing di worker, undo/redo, ekspor STL/3MF |
| **M2 — distribusi** | Galeri + S2 mesh pratinjau saat build, tautan berbagi ringkas, PWA + notifikasi pembaruan, header keamanan, deploy Vercel |
| **M3 — lengkap** | Impor file/folder/URL, font perangkat, icon pack, trace gambar, mobile bottom sheet, Trusted Types penuh |
| Fase 2 (opsional) | Impor/ekspor cadangan pustaka pengguna, terjemahan Bahasa Indonesia, analitik anonim |

---

## 10. Risiko

| Risiko | Mitigasi |
|---|---|
| Model berat lambat di perangkat lemah | Pratinjau resolusi rendah (sama App), batal otomatis, pesan & opsi ekspor resolusi model |
| Memori WASM (ponsel) | Instance dibuang setelah tiap render; peringatan bila gagal alokasi |
| Font proprietary (Arial, Segoe Script) tidak bisa dibundel | Alias ke Liberation; font perangkat via Local Font Access; fallback otomatis di daftar font |
| Impor URL diblokir CORS | Pesan jelas + saran unduh lalu impor file |
| Safari tanpa File System Access / Local Font Access | Fallback unduhan & font bawaan (fitur inti tetap jalan) |
| Snapshot OpenSCAD dihapus server | WASM disimpan di `public/openscad` setelah diverifikasi (ikut repo/deploy) |

---

## 11. Hasil uji teknis M0 (2026-11-01)

Skrip: `spike/bench-engine.mjs` (Node 26, worker per render, WASM dikompilasi sekali) dan `spike/browser/` (Chrome, module worker, header keamanan lengkap). Data mentah: `spike/bench-export.log`, `spike/bench-results-export.json`. OpenSCAD WASM snapshot **2026.10.11**, 17 contoh dari `examples/`.

### Backend (Node, kualitas pratinjau `$fa=20 $fs=2`)

| Contoh | CGAL | Manifold | Kali lebih cepat |
|---|---:|---:|---:|
| svg_icon_to_3d | 31 247 ms | 444 ms | 70× |
| Name_zigzag_multi | 27 878 ms | 147 ms | 190× |
| filament_painting | 20 074 ms | 89 ms | 225× |
| decorated_font | 15 502 ms | 118 ms | 131× |
| pet_bowl_stand | 14 854 ms | 75 ms | 198× |
| articulated_cube_keychain | 12 450 ms | 138 ms | 90× |
| contoh lain (11) | 11–6 713 ms | 7–232 ms | 1–110× |

- **Default snapshot = Manifold** (jumlah segitiga & ukuran identik di 17/17 contoh). App desktop sudah otomatis menikmatinya; web tetap mematok `--backend=manifold` (S1).
- **Kualitas ekspor (`$fa=2 $fs=0.2`) dengan Manifold: 7 ms – 1,57 s** (terberat: Name_zigzag_multi). CGAL di kualitas ekspor: 136 s untuk articulated_cube_keychain → tidak diuji lebih lanjut.

### Browser (Chrome, Manifold, kualitas pratinjau, server lokal)

- `compileStreaming` 11 MB: **1 065 ms** pertama kali, **221 ms** saat dari cache HTTP.
- Instantiate per render: **8–37 ms**; parsing STL di worker: **≤ 1 ms**; transfer `Float32Array` tanpa salin.
- Total pulang-pergi per render: **28–503 ms** untuk 16 contoh (sejalan dengan angka Node).
- Berjalan di bawah CSP ketat + `require-trusted-types-for 'script'` + COOP/COEP (`crossOriginIsolated = true`) setelah menambah policy `worker-url`.

### Keputusan

1. Arsitektur dipertahankan: kompilasi sekali di main thread → modul dikirim ke **worker baru per render**, `terminate()` untuk membatalkan.
2. S4 (instance cadangan) dibatalkan; S8 (pratinjau di kualitas ekspor bila cepat) ditambahkan.
3. Batas waktu App (120 s pratinjau / 5 menit ekspor + fallback resolusi) cukup sebagai jaring pengaman; untuk pustaka saat ini tidak pernah tersentuh. Debounce awal bisa turun dari 700 ms ke ±150–250 ms (S5).
4. Header keamanan bagian 7 terbukti kompatibel dengan WASM + module worker.
5. Belum diuji: perangkat lemah/ponsel, Firefox & Safari, ukuran Brotli WASM di CDN. Masuk ke awal M1.

---

## 12. Catatan M1 (2026-11-01)

**CDN.** Diputuskan per jenis aset:
- **WASM OpenSCAD & font** → boleh dari CDN publik (jsDelivr) lewat `VITE_ASSET_BASE` (mis. `https://cdn.jsdelivr.net/gh/<owner>/<repo>@<tag>/public/`). Setiap unduhan memakai `fetch(url, { integrity })` dengan hash dari `src/platform/asset-manifest.json`, jadi file CDN yang berubah ditolak. jsDelivr mengirim `Access-Control-Allow-Origin: *` dan `Cross-Origin-Resource-Policy: cross-origin` → kompatibel dengan COEP. `connect-src` CSP otomatis ditambah origin CDN.
- **three.js, fflate** → tetap di-*bundle*. Cache browser kini dipartisi per situs, jadi CDN bersama tidak memberi *cache hit* lintas situs; bundel Vite hanya memuat bagian yang dipakai dan tidak menambah koneksi/ketergantungan pihak ketiga.
- **Situs itu sendiri** → di Vercel/Cloudflare (sudah CDN global, M2).
- Glue `openscad.js` (0,1 MB) tetap *same-origin*: impor modul di worker tidak bisa diberi SRI.

**Kinerja nyata (Chrome, build produksi).** Render pertama tiap tool 0,14–2,0 s; ulang/undo/redo dari cache 0–2 ms. Lebih lambat dari angka M0 karena kebanyakan tool menetapkan `$fn` sendiri (resolusi model dipakai, sama seperti desktop), sedangkan M0 memaksa kualitas pratinjau. S8 hanya aktif untuk tool tanpa `$fn/$fa/$fs`.

**S6 ditunda.** Pratinjau memakai 3MF (warna model), dan `ThreeMFLoader` butuh `DOMParser` yang tidak ada di worker. Parsing di main thread untuk pustaka saat ini singkat; dievaluasi ulang bila ada model besar.

**Belum di M1:** impor/hapus tool, parameter kustom, icon pack, trace gambar, relief (M3); galeri, tautan berbagi, PWA, `vercel.json` (M2); Trusted Types penuh (M3).

---

## 13. Deploy ke Vercel gratis (Hobby), tanpa GitHub

`web/` belum dimasukkan ke GitHub, jadi deploy dilakukan dengan **Vercel CLI dari folder lokal**. CLI mengunggah folder (kecuali isi `.vercelignore`), lalu Vercel menjalankan `npm ci` + `npm run build` dan menyajikan `dist/` dari CDN-nya.

**Sekali saja:**
```
cd D:\_FRELENCE\hadi\App\web
npx vercel login
npx vercel link        # buat proyek baru; pengaturan dibaca dari vercel.json
```

**Setiap rilis:**
```
npm test
npx vercel             # deploy pratinjau (URL acak, untuk dicek dulu)
npx vercel --prod      # deploy produksi
```

Alternatif yang hanya mengunggah hasil build: `npx vercel build --prod` lalu `npx vercel deploy --prebuilt --prod`.

**Yang sudah dikondisikan untuk Vercel:**
- `vercel.json`: framework Vite, `npm ci`, output `dist`, header keamanan (sama dengan `security-headers.mjs`; dijaga `test/vercel.test.mjs`), cache `immutable` 1 tahun untuk `/assets` (nama ber-hash), `/openscad/<versi>/`, `/fonts/liberation-<versi>/`; `/library` selalu divalidasi ulang.
- Build mandiri: `npm run build` hanya menjalankan `vite build`; semua yang dibutuhkan (`public/`, `src/vendor/openscad/openscad.js`, `src/platform/asset-manifest.json`) ada di folder `web/`, tidak bergantung pada `..`.
- Situs statis murni: tidak ada serverless function, jadi kuota fungsi paket gratis tidak terpakai.
- Total unggahan ±16 MB (WASM 10,5 MB, font 4,2 MB, sisanya kecil).

**Perhatikan pada paket Hobby:**
- Paket Hobby untuk **penggunaan non-komersial**. Bila situs dipakai untuk klien/bisnis, perlu paket Pro (atau hosting statis lain, mis. Cloudflare Pages; `vercel.json` perlu diterjemahkan ke `_headers`).
- Kuota transfer data bulanan terbatas (cek angka terbaru di halaman harga Vercel). Pengunjung baru mengunduh ±11–15 MB sekali; kunjungan berikutnya dari cache browser (immutable). Setelah deploy pertama, cek apakah WASM dikirim terkompresi: `curl -sI -H "Accept-Encoding: br, gzip" https://<domain>/openscad/2026.10.11/openscad.wasm` → lihat `content-encoding`.
- Bila kuota menjadi masalah, WASM & font bisa dipindah ke CDN lain lewat `VITE_ASSET_BASE` (integritas tetap diperiksa SRI) — butuh lokasi publik untuk file-file itu.

## 14. Font Google Fonts lewat link (khusus web, 2026-11-01)

- **Cara kerja:** `src/platform/google-fonts.json` hanya berisi daftar link `fonts.gstatic.com` + hash SHA-256 (SRI). Tidak ada file font Google di proyek atau di Vercel. Saat font dipilih, browser mengunduhnya langsung dari Google (`fetch` dengan `integrity`, tanpa cookie, tanpa referrer), mengubah WOFF → TTF (`src/shared/woff.js`), lalu memberikannya ke OpenSCAD. Pratinjau di panel memakai `FontFace` dari byte yang sama (`src/web/font-preview.js`); hanya font yang dipilih yang diunduh.
- **Kenapa WOFF:** OpenSCAD tidak bisa membaca WOFF2 (yang dikirim Google ke browser modern). Skrip meminta CSS dengan user-agent Windows lama → Google memberi WOFF 1.0 (zlib), yang bisa diubah ke TTF tanpa kehilangan apa pun.
- **Font tanpa hinting:** OpenSCAD WASM crash ("function signature mismatch") pada TrueType tanpa tabel `fpgm`, karena FreeType lalu memakai auto-hinter yang rusak di build WASM. `makeOpenScadCompatible` menambahkan program font kosong (PUSHB 0, POP) → FreeType memakai interpreter biasa; outline tidak berubah. Ke-62 font diuji render di engine.
- **Menambah font:** ubah `FAMILIES` di `scripts/google-fonts.mjs`, jalankan `npm run google-fonts` (butuh internet). Entri lama dipertahankan apa adanya.
- **Keamanan:** CSP `connect-src` hanya menambah `https://fonts.gstatic.com` (bukan `fonts.googleapis.com`); file yang berubah di URL yang sama ditolak SRI. gstatic mengirim `Access-Control-Allow-Origin: *` + `Cross-Origin-Resource-Policy: cross-origin`, jadi cocok dengan COEP.
- **Privasi:** saat font Google dipilih, IP pengunjung terlihat oleh Google (hanya saat itu). Liberation tetap dari situs sendiri.
- **Bila Google mengganti versi font** (URL `/v29/` dsb.), link lama biasanya tetap hidup; jika suatu saat gagal, pengguna mendapat pesan "Could not load the font …" dan cukup menjalankan ulang skrip setelah menghapus entri itu.
- **Desktop tidak diubah.** Perbaikan `fpgm` juga bisa membuat font tanpa hinting di komputer pengguna desktop terbaca — tugas terpisah bila diinginkan.

## 15. Unggah gambar/ikon — sementara (2026-11-01)

Prinsip: **web tidak menyimpan data unggahan.** Gambar, ikon, hasil trace, relief dan icon pack hanya ada di memori tab
(`src/platform/session-files.js`): tidak ke IndexedDB/localStorage, tidak dikirim ke server. Refresh/tutup tab = hilang.

- **Pilih file:** `<input type="file">` (`file-picker.js`); batas 10 MB, jenis file sama dengan desktop.
- **Aset tool:** dirujuk sebagai `user-assets/<uuid>.svg|png` (sama dengan desktop) dan ikut ditulis ke sistem file OpenSCAD
  di samping file tool saat render (`render-job.js`). Batas total 200 MB per sesi. Rujukan ke file yang sudah hilang
  (mis. dari preset lama) → pesan "kept only until the page is closed … Choose the image again".
- **Trace warna:** vtracer 1.0.0-alpha.4 (npm, hash sama dengan desktop). WASM 653 KB di `public/vtracer/<versi>/` (SRI,
  immutable) diunduh hanya saat pertama kali trace; glue diubah ke ESM oleh `fetch-assets.mjs`; `image-trace.cjs` ikut
  disinkron. Berjalan di Web Worker, batas 60 s.
- **Icon pack:** folder yang dipilih → pack per sub-folder; yang disimpan hanya handle `File`, isi dibaca saat ikon ditampilkan.
- **Preset dan pengaturan juga sementara** (sejak [008]): disimpan di memori (`session-store.js`, `settings.js`), bukan localStorage. Saat mulai, kunci lama `bonastudio:*`/`formforge:*` dari build sebelumnya dihapus. Hasilnya: web **tidak menyimpan apa pun** di browser (localStorage, sessionStorage, IndexedDB, Cache Storage kosong).

