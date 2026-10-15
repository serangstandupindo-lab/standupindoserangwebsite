# Referensi Teknis Clone Komunitas

Untuk langkah yang ramah pemula, prompt siap salin, dan petunjuk tempat mengisi secret, mulai dari [PANDUAN_CLONE_PEMULA.md](PANDUAN_CLONE_PEMULA.md). Dokumen ini adalah catatan teknis maintainer; bukan urutan perintah yang boleh dijalankan mentah-mentah.

Source saat ini adalah instance Standupindo Serang. Clone harus mempertahankan fitur aplikasi, tetapi memiliki repository, Supabase/database, akun layanan, domain, dan data sendiri. Data pribadi komunitas lain tidak ikut disalin.

## Status terkini dan baseline acuan — 15 Oktober 2026

Bagian ini adalah ringkasan yang harus diutamakan bila bertentangan dengan catatan audit historis di bawah. Pada 15 Oktober 2026 pukul 14:35 WIB, pengguna menetapkan kondisi source dan konfigurasi yang dijelaskan di bagian **Baseline acuan yang disetujui pengguna** sebagai titik acuan 100% sesuai harapan untuk clone Standupindo Serang. Pertahankan perilaku, branding, layout, dan relasi migration tersebut pada perubahan berikutnya; jangan mengembalikan perilaku lama atau mengubah keputusan produk tanpa permintaan.

**Batas arti status 100%:** ini adalah persetujuan pengguna terhadap baseline kebutuhan dan hasil perubahan yang tercatat, bukan klaim bahwa seluruh alur produksi telah diuji atau bahwa frontend sudah live. Migration database Serang sudah diterapkan dan diverifikasi di remote. Source frontend pada baseline ini masih berada di repository lokal dan **belum dideploy**. Deployment, pengujian transaksi/peran/perangkat nyata, serta checklist operasional tetap harus dilakukan sebelum menyatakan rilis produksi selesai.

### Baseline acuan yang disetujui pengguna

- **Database dan migration:** paket clone di `supabase-serang/supabase/migrations/` terdiri dari baseline netral dan patch berurutan. Delapan migration (baseline dan tujuh patch) tercatat remote pada project Serang `dyrqcpbcdxgfryxtgyzg`, dengan daftar lokal dan remote cocok. Dua patch terakhir, `20261015120000_rename_ccs_schedule_brand.sql` dan `20261015130000_set_serang_social_profiles.sql`, diterapkan setelah project ref diverifikasi dan dry-run hanya menampilkan kedua patch tersebut. Nilai Instagram, TikTok, dan YouTube juga dibaca kembali dari `site_settings` setelah migration.
- **Branding dan identitas:** gunakan nama Standupindo Serang secara utuh, termasuk “Serang” pada header desktop; label jadwal publik adalah **Serang Sharing**, bukan CCS/Cilegon Comedy Sharing. Pertahankan tema dan aset Serang pada seluruh halaman serta state/slide, bukan hanya aksennya. Nama tabel, tipe, route, dan identifier internal `ccs_*` tetap dipertahankan demi kompatibilitas.
- **Settings dan kontak publik:** akun sosial dikelola melalui Admin Penuh → Settings → Sosial Media & Lokasi. Nilai awal Serang adalah Instagram `@standupindo_srg`, TikTok `@standupindo_serang`, dan YouTube `@standupindoserang`. Kontak/footer menampilkan ikon serta nama platform tanpa handle tercetak; klik membuka profil yang disetel. Popup tetap bernama “Follow Standupindo Serang” dan mengikuti URL Instagram Settings. Kartu WhatsApp umum hanya berlabel “WhatsApp”.
- **Navigasi dan tombol:** desktop dan bottom nav mobile masing-masing berisi Home, Open Mic, Event, Komika, dan More. Partner diakses dari More → `/more/kerja-sama`, bukan sebagai item tersendiri di header atau bottom nav. Menu tablet tetap memakai tombol Menu. Pertahankan tujuan route dan state aktif ketika mengubah navigasi.
- **Akses akun:** form reset password Admin/Komika dan Member menampilkan ikon mata hanya untuk password baru yang sedang diketik; password lama tidak tersedia untuk dibaca.
- **Push/VAPID:** konfigurasi backend Push Serang termasuk baseline: tiga Edge Functions aktif, VAPID P-256 dan webhook secret tersimpan di Supabase Secrets, Vault scheduler berisi URL/service-role key project, dan cron berjalan tiap 15 menit. `VAPID_SUBJECT` saat pencatatan masih memakai `https://standupindoserang.vercel.app`; ketika domain resmi aktif, ubah subject ke origin HTTPS tersebut tanpa membuat ulang key. Tidak ada subscription perangkat saat pemeriksaan, jadi push ke perangkat nyata belum tervalidasi.
- **Email Resend/tiket:** template konfirmasi pembayaran dan Free Pass yang mobile-first, berlogo Serang, termasuk bagian dari baseline source; `ticketing-admin` versi 11 tercatat aktif. `RESEND_FROM` sudah diset ke `Standupindo Serang <noreply@standupindoserang.site>`, tetapi `RESEND_API_KEY` yang tersedia di Supabase gagal pada pemeriksaan Resend dengan `400 API key is invalid`. Karena itu domain belum terkonfirmasi di dashboard Resend dan email uji belum berhasil terkirim. **Email belum boleh dianggap operasional** sampai key diperbaiki, domain diverifikasi, dan pengiriman uji berhasil.
- **Hasil fitur dan layout yang sudah disetujui sebelumnya:** pertahankan perbaikan detail Komika publik, tampilan/brand share Open Mic, Annual Recap (termasuk gambar loading dan tema Serang per slide), relasi angka recap, template email tiket mobile-first berlogo, serta perubahan layout desktop/mobile. Runbook ini menjadi acuan perilaku; audit atau pengujian ulang tetap mengikuti checklist, bukan asumsi bahwa semua layanan eksternal sudah lolos end-to-end.

- Paket clone berada di `supabase-serang/supabase/migrations/`: baseline clone netral ditambah patch berurutan. Delapan migration clone saat ini tercatat remote. Dua migration terbaru diterapkan setelah verifikasi project ref dan dry-run hanya memuat `20261015120000_rename_ccs_schedule_brand.sql` dan `20261015130000_set_serang_social_profiles.sql`. Jangan menjalankan semua migration dari `supabase/migrations/` source atau menganggap perubahan frontend lokal sudah live.
- Untuk migration berikutnya, pastikan project ref benar, migration list lokal/remote cocok, dan dry-run hanya memuat patch yang sudah direview sebelum push. Status migration adalah bagian backend; perubahan React/TypeScript memerlukan build dan deployment hosting terpisah.
- Source frontend menggunakan `site_settings` row `id = 1` sebagai satu-satunya konfigurasi informasi komunitas. Admin Settings menyimpan baris tersebut; setelah penyimpanan sukses, event browser `standupindo:site-settings-updated` memperbarui state Settings yang dibaca `RoutedApp`, sehingga kontak/footer tidak perlu menunggu reload. `ContactPage` membaca deskripsi, alamat, sosial media, serta nomor WhatsApp umum/pendaftaran/kerja sama/tiket. Footer membaca deskripsi, alamat, sosial media, dan WhatsApp umum (fallback ke pendaftaran). Nama penanggung jawab WhatsApp tidak ditampilkan publik.
- Akun sosial Serang dikonfigurasi di Admin Penuh → Settings → Sosial Media & Lokasi. Form menerima URL penuh atau handle; kartu Kontak dan footer menampilkan ikon/label platform tanpa menampilkan handle, dan klik membuka URL profil hasil setting. Popup tetap bernama “Follow Standupindo Serang”, menampilkan akun aktif, dan link-nya ikut berubah otomatis dari Settings. Kartu WhatsApp umum hanya berlabel “WhatsApp” (kanal khusus lain tetap menyebut Pendaftaran/Kerja Sama/Tiket).
- Popup di `src/components/FollowInstagramPopup.tsx` mempertahankan judul “Follow Standupindo Serang”, menampilkan handle aktif, serta mengambil link dari `settings.instagram_url`. Perubahan Settings diteruskan melalui event browser, jadi link popup/footer/kartu Kontak ikut berubah otomatis. Jika Instagram kosong atau nilainya tidak valid, popup dan tautan profil tidak ditampilkan.
- Navigasi publik di desktop dan mobile menuju route yang sama. Navigasi desktop dan bottom nav mobile memiliki lima item Home, Open Mic, Event, Komika, More. Akses Partner berada dalam More pada desktop dan mobile, dan membuka `/more/kerja-sama`; More juga menjadi pintu Kontak, Tentang, dan Gabung. Pada tablet header memakai tombol Menu agar tidak memaksa seluruh desktop nav masuk ke layar sempit.
- Header desktop menampilkan seluruh `site_short_name` dari Settings (termasuk “Serang”); versi mobile tetap menyusun nama dan kota sebagai dua baris.
- Navigasi Admin bukan salinan nav publik: `getWorkspaceNav` dan `getWorkspaceBottomNav` membatasi item berdasarkan role; item lanjutan tersedia pada `MorePage` hanya bila `canAccessSection` mengizinkan role tersebut. Saat menambah menu Admin, perbarui route/izin dan pastikan menu desktop, bottom nav, serta More tidak membuat route tanpa akses.
- Password yang boleh ditampilkan lewat ikon mata hanyalah password baru yang sedang diketik. Form berada di `KomikaManagement` dan `MemberAccountsPage`; keduanya tetap mengirim reset melalui Edge Function `admin-manage-members`. Auth tidak menyediakan password lama dalam teks biasa. Visibilitas direset saat target/modal berubah atau reset berhasil.
- Nama publik jadwal adalah **Serang Sharing**. Untuk kompatibilitas, tabel `ccs_schedules`, tipe `CcsSchedule`, route dan identifier internal `ccs-*` tetap dipakai. `getSerangSharingTitle` mengubah judul legacy persis “Serang Comedy Sharing”/“Cilegon Comedy Sharing” beserta akhiran `(CCS)` menjadi label Serang Sharing saat dirender; migration baru mengubah default database dan hanya menormalkan judul legacy yang sama persis, tanpa menimpa judul jadwal khusus.

### Peta file dan alur untuk perubahan berikutnya

| Kebutuhan | Implementasi dan perilaku |
| --- | --- |
| Baca/publikasi setting global | `src/lib/useSiteSettings.ts` membaca `site_settings.id = 1`, memasang token warna CSS, dan mendengar event `standupindo:site-settings-updated`. `src/pages/admin/AdminPage.tsx` (`SettingsPanel`) update row tersebut lalu menerbitkan event hanya setelah Supabase menyatakan update berhasil. Jangan mengubah fallback menjadi nilai rahasia. |
| Tampilkan kontak | `src/pages/public/ContactPage.tsx` menerima `settings` dari `RoutedApp` melalui prop. Deskripsi pendek, alamat, tiga sosial, dan empat WhatsApp (umum, pendaftaran, kerja sama, tiket) berasal dari kolom tabel `site_settings`. `src/lib/social-profile.ts` menerima URL HTTPS atau handle `@username` dan membentuk URL profil platform. Kartu sosial hanya memperlihatkan ikon dan nama platform, bukan username; klik tetap membuka profil. Label nomor WhatsApp umum adalah “WhatsApp”. Link WhatsApp dibentuk oleh `waLink`; jika nilainya kosong, kartu tidak dibuat. Teks nama admin/penanggung jawab tidak dipublikasikan. |
| Tampilkan footer | `src/components/AppShell.tsx` menggunakan setting yang sama untuk deskripsi, ikon sosial/WhatsApp, alamat, dan navigasi. Jika menambah kolom publik, cek baik ContactPage maupun footer; tidak ada fetch setting kedua khusus untuk salah satu halaman. |
| Navigasi publik | `src/components/nav/DesktopNavbar.tsx` berisi navigasi desktop lima item dan tombol Menu untuk ukuran tablet; `src/components/nav/MobileBottomNav.tsx` berisi bottom nav lima item (Home, Open Mic, Event, Komika, More). Partner tersedia dari `/more` dan route-nya `/more/kerja-sama`; `/more` tetap pusat submenu Kontak, Tentang, dan Gabung. Header desktop menampilkan nama singkat lengkap termasuk kota. |
| Navigasi Admin | `src/pages/admin/AdminPage.tsx`: `getWorkspaceNav`, `getWorkspaceBottomNav`, `canAccessSection`, `getSection`, dan `MorePage` membentuk navigasi sesuai role; daftar bottom nav yang pendek bukan bukti bahwa fitur hilang bila route aman tersedia di More. Jangan menambahkan menu tanpa memeriksa role, route, bottom nav, More, dan refresh direct URL. |
| Reset password akun | `KomikaManagement` di `src/pages/admin/AdminPage.tsx` dan `src/pages/admin/MemberAccountsPage.tsx` menampilkan/menyembunyikan **password baru** secara lokal. Kedua alur memakai `admin-manage-members` action `reset-password`; password lama tidak bisa dibaca dari Auth. Jangan menyimpan atau mencatat password plaintext. |
| Akun sosial | `src/pages/admin/AdminPage.tsx` menerima URL lengkap atau handle `@username`; kontak/footer/Follow Instagram memakai setting terbaru tanpa reload. Migration `20261015130000_set_serang_social_profiles.sql` menetapkan URL akun sosial Serang pada `site_settings`, dan sudah tercatat diterapkan ke project Serang. Admin tetap dapat mengganti URL/handle di Settings sesudah migration. |
| Jadwal Serang Sharing | `src/components/CcsScheduleHighlights.tsx` menampilkan jadwal publik; `src/pages/admin/CcsScheduleAdminPage.tsx` mengelolanya; `src/lib/ccs.ts` memformat tanggal, recurrence, dan legacy title; `src/lib/types.ts` tetap memakai tipe internal `CcsSchedule`. Tabel `ccs_schedules`, storage folder `ccs-schedules`, section `ccs-schedule`, serta route admin internal tidak perlu diganti hanya karena label publik berubah. |

## Gambaran Clone

Tujuan clone adalah memakai **aplikasi dan fitur yang sama**, tetapi setiap komunitas mempunyai repository, Supabase/database, akun layanan, domain, dan data sendiri. Logo, nama, warna, kontak, serta teks komunitas diganti. Data Cilegon seperti akun, pendaftar, event, order tiket, file Storage, dan subscription push **tidak** ikut disalin.

Cara paling mudah untuk pengelola yang bukan web developer adalah mengurus identitas dan akun layanan sendiri, lalu meminta satu penanggung jawab teknis mengerjakan database, secrets, dan bagian kode yang masih khusus Cilegon. Jangan menebak atau menjalankan SQL sendiri.

### Urutan yang harus diikuti

1. **Siapkan identitas komunitas.** Kumpulkan nama resmi dan nama singkat, kota/alamat, logo, warna utama, WhatsApp, sosial media, domain, email pengirim, dan daftar fitur yang ingin diaktifkan. Checklist lengkap ada di bagian Sebelum mulai.
2. **Pilih versi aplikasi yang disetujui.** Minta pengelola source menentukan commit/release yang sudah berjalan dan layak dijadikan titik awal. Jangan clone working copy yang belum disetujui, karena bisa berisi fitur setengah jadi atau perubahan yang belum dirilis.
3. **Buat repository baru milik komunitas.** Gunakan GitHub Import Repository atau minta pengelola source menyalin seluruh source dari commit yang disetujui. Pastikan repository tujuan berbeda dari repository Cilegon. Jangan hanya menyalin beberapa halaman.
4. **Buat akun layanan baru.** Buat Supabase project, akun hosting, dan akun email/Resend atas nama komunitas. Pakai domain sendiri bila siap. Jangan memakai project, akun, database, Storage, atau secret Cilegon.
5. **Catat konfigurasi publik dengan aman.** Simpan URL Supabase dan publishable/anon key project baru untuk langkah frontend nanti. Key ini memang dipakai browser, tetapi tetap catat project ref agar tidak tertukar. Service-role key, password, Resend API key, VAPID private key, dan webhook secret adalah rahasia: jangan kirim lewat chat atau commit ke Git.
6. **Validasi migration untuk target baru.** Paket clone saat ini ada di `supabase-serang/supabase/migrations/`; jangan memakai direktori source root atau menjalankan semua SQL mentah. Cocokkan project ref, migration list lokal/remote, dan status patch terbaru. Jika clone belum memiliki riwayat migration yang cocok atau patch belum ditinjau di staging, berhenti dan minta penanggung jawab teknis menguji urutan dari database kosong.
7. **Setelah target migration tervalidasi,** minta teknisi menerapkannya ke Supabase komunitas baru, menguji RLS/Storage, menyiapkan Edge Functions/secrets yang dipakai, serta membuat akun Admin Penuh dengan prosedur aman. Jangan membuat role admin dengan menyalin akun atau password dari Cilegon.
8. **Hubungkan frontend ke project baru.** Untuk pemula, isi Environment Variables hosting sesuai target project komunitas. `.env.example` hanya berisi placeholder; verifikasi URL/key yang dipakai sebelum build. Petunjuk ada di [PANDUAN_CLONE_PEMULA.md](PANDUAN_CLONE_PEMULA.md).
9. **Ganti branding dan isi data awal.** Setelah teknisi mengonfirmasi database serta akun Admin siap, isi Settings dengan identitas komunitas, ganti aset/teks statis yang masih menyebut Cilegon, lalu buat data Open Mic, Event, dan Komika baru. Database clone dimulai dengan data sendiri, bukan salinan database Cilegon.
10. **Uji dulu, baru umumkan.** Ikuti checklist pada Tahap 9. Pastikan semua URL memakai domain/project baru, role non-admin tidak bisa melakukan tindakan admin, dan alur yang akan dipakai komunitas berhasil di desktop serta mobile.

### Siapa mengerjakan apa?

| Pengelola komunitas | Penanggung jawab teknis |
| --- | --- |
| Menentukan nama, warna, logo, kontak, domain, fitur, serta pemilik akun layanan | Memilih commit source yang benar dan menyiapkan repository clone |
| Membuat/menjadi pemilik akun GitHub, Supabase, hosting, dan email | Menyiapkan dan menguji baseline migration di staging kosong |
| Menyediakan konten awal dan memeriksa tampilan branding | Mengatur RLS, Storage, Auth role, Edge Functions, dan secrets |
| Mengikuti smoke test dan melaporkan masalah | Menghubungkan environment frontend, memperbaiki teks/kode statis, build, dan deploy |

### Pilihan hosting termudah

Repository ini memiliki `vercel.json` untuk mengarahkan route aplikasi ke `index.html`, sehingga Vercel adalah opsi sederhana untuk website statis: pilih repository clone, gunakan build `npm run build` dan output `dist`, lalu isi Environment Variables milik komunitas. Jangan lakukan deploy database dari Vercel; migration dan secrets backend ditangani terpisah oleh teknisi.

Jika memakai Hostinger/Apache, ikuti langkah upload `dist` pada Tahap 8. Jangan mengunggah `.env`, `node_modules`, service-role key, atau file rahasia.

**Status project Serang pada baseline acuan:** baseline clone dan tujuh patch clone (delapan migration total) sudah tercatat pada project Serang, termasuk patch branding Serang Sharing dan akun sosial. Frontend pada source lokal belum dideploy ke hosting. Peluncuran clone baru tetap memerlukan pemeriksaan project ref, urutan migration, secrets, RLS/Storage, serta smoke test role dan transaksi pada targetnya. Daftar file di Tahap 4 adalah bahan kerja teknisi, bukan urutan paste/run untuk pemula.

## Ringkasan untuk pengelola komunitas

Tujuannya adalah memakai **fitur, alur, struktur database, aturan akses, dan fungsi backend yang sama** dengan Standupindo Cilegon, tetapi dengan identitas dan data komunitas sendiri: nama lengkap/nama singkat, logo, warna, kontak, domain, dan data komunitas. Migration clone harus mempertahankan kebutuhan fitur tersebut, tetapi tidak boleh membawa data, akun, credential, atau konfigurasi project Cilegon. Gunakan satu versi source code yang utuh; jangan mengambil beberapa halaman atau migration secara acak.

Yang bisa disiapkan tanpa kemampuan pemrograman:

1. Kumpulkan identitas dan aset komunitas pada checklist di bawah.
2. Buat akun layanan komunitas sendiri atau minta penanggung jawab komunitas membuatnya.
3. Ikuti bagian pengisian Settings, pengaturan hosting, dan pengujian setelah penanggung jawab teknis menyiapkan aplikasi dan database.

**Catatan historis:** pemeriksaan 9 Oktober 2026 belum memiliki paket migration clone yang dapat dipakai dari nol. Baseline netral dan patch clone kemudian disiapkan serta diterapkan pada project Serang. Untuk clone baru, tetap minta penanggung jawab teknis memastikan paket dan konfigurasi Supabase CLI sesuai; status project Serang tidak otomatis berarti project komunitas lain sudah siap.

### Yang disalin dan yang tidak

| Salin/pakai dari source Standupindo Cilegon | Jangan salin dari lingkungan Cilegon |
| --- | --- |
| Seluruh source code aplikasi dari satu commit yang disepakati, termasuk `src/`, `public/`, `supabase/functions/`, migration, dan file konfigurasi yang memang dilacak Git | `.env`, kredensial, API key, service-role key, password, token, atau isi password manager |
| Versi dependency yang ditetapkan manifest dan lockfile (`package.json`, `package-lock.json`) | Folder `.git`, `node_modules`, `dist`, log, backup, atau file lokal |
| Fitur dan alur aplikasi tanpa menghapus bagian yang tidak dikenal | Data database, pengguna/Auth, order, bukti pembayaran, data pendaftar/member, file Storage, dan subscription push Cilegon |
| Migration sebagai berkas sumber **untuk diperiksa dan diuji oleh penanggung jawab teknis** | Menjalankan semua SQL di folder migration secara langsung; termasuk migration seed akun admin |

Buat repository tujuan dan project layanan baru milik komunitas. Jangan melakukan perubahan langsung atau push ke repository Cilegon. Pengambilan source penuh tidak berarti backend/datanya ikut tersalin.

## Prinsip isolasi

Setiap komunitas mengelola dan membayar layanannya sendiri. Jangan menggunakan kredensial atau resource produksi komunitas lain.

| Resource | Yang disiapkan untuk setiap komunitas |
| --- | --- |
| Source code | Repository Git sendiri; fitur awal sama, perubahan berikutnya dikelola sendiri |
| Domain | Domain dan akses registrar/DNS sendiri |
| Hosting | Akun hosting dan deployment sendiri |
| Supabase | Organization/project, database, Auth, Storage, Edge Functions, secrets, dan backup sendiri |
| Email | Akun Resend, domain pengirim terverifikasi, API key, dan pengelola sendiri |
| Push notification | VAPID key, webhook secret, konfigurasi Vault, dan jadwal sendiri jika fitur push diaktifkan |
| Operasional | Admin, password manager, metode pembayaran layanan, dan penanggung jawab sendiri |

Satu orang boleh membantu mengelola beberapa komunitas jika memang dipilih, tetapi itu tidak membuat akun, billing, database, atau kredensial menjadi terpisah. Untuk kepemilikan mandiri sungguhan, buat akun/organisasi layanan atas nama pengelola komunitas masing-masing dan undang pihak lain dengan role seperlunya.

## Sebelum mulai

Tentukan dan kumpulkan:

- Nama resmi (lengkap), nama singkat untuk header, kota, dan deskripsi komunitas.
- Logo berkualitas baik untuk header, favicon/PWA, serta gambar untuk pratinjau tautan/Open Graph.
- Warna utama, hover, aksen, dan netral (kode warna seperti `#123ABC`).
- Domain, akses DNS, akun hosting, dan nama penanggung jawab.
- Nomor WhatsApp untuk admin, pendaftaran, kerja sama, dan tiket; akun sosial dan alamat.
- Email pengirim serta domain email yang akan diverifikasi di Resend.
- Admin awal, email admin, dan password kuat yang disimpan di password manager.
- Penanggung jawab/pemilik akun Supabase dan metode pembayaran layanan.
- Fitur yang akan digunakan sejak peluncuran: Open Mic, Member, Evaluasi, Event, tiket, Gate/QR, email, dan push.

Jangan meminta atau menyimpan password, API key, service-role key, atau token orang lain di repository, chat, atau dokumen ini.

## Tahap 1 — Buat repository dan salinan kode

1. Minta pengelola source menetapkan commit yang akan dijadikan versi awal.
2. Buat repository baru milik organisasi/pengelola komunitas, lalu salin seluruh file source yang dilacak Git dari commit tersebut.
3. Pastikan `src/`, `public/`, `supabase/functions/`, migration, `package.json`, dan `package-lock.json` tersedia di repository baru.
4. Jangan salin `.env`, `.git`, `node_modules`, `dist`, log, backup, atau file kredensial lokal.
5. Pastikan remote Git mengarah ke repository komunitas baru sebelum melakukan push. Jika proses ini dikerjakan melalui GitHub, periksa nama repository tujuan sebelum menekan tombol **Create repository** atau **Push**.
6. Catat URL repository sumber dan commit yang disalin agar versi fitur awal dapat ditelusuri.

Contoh nama repository:

```text
standupindo-serang
standupindo-rangkasbitung
standupindo-pandeglang
```

Salinan repository berdiri sendiri. Perbaikan bug dan fitur baru di repository Cilegon tidak otomatis masuk; pengelola perlu memilih dan menerapkan perubahan tersebut sendiri.

## Tahap 2 — Buat layanan mandiri

Lakukan untuk setiap komunitas:

1. Buat domain dan hosting atas nama/pengelolaan komunitas tersebut.
2. Buat Supabase project baru. Jangan menghubungkan situs baru ke URL/key Cilegon.
3. Buat akun Resend dan verifikasi domain email pengirim milik komunitas tersebut.
4. Buat secret push/VAPID sendiri bila push notification akan digunakan.
5. Catat URL, key publik, project ref, domain, dan status setup di password manager atau inventaris privat. Jangan memasukkan secret ke Git.

Email frontend hanya memakai `VITE_SUPABASE_URL` dan publishable/anon key milik project baru. Service-role key, Resend API key, VAPID private key, dan secret webhook hanya berada di server/Supabase Secrets/Vault.

## Tahap 3 — Periksa branding yang tertanam di kode

Admin Settings dapat mengubah sebagian branding database, tetapi bukan semua teks/assets statis. Sebelum build, cari dan putuskan nilai komunitas untuk:

- `index.html`: title, description, favicon, Open Graph/Twitter image, dan theme color.
- `src/lib/types.ts`, `src/lib/useSiteSettings.ts`: fallback nama, logo, sosial media, dan alamat.
- Halaman publik serta formulir admin yang memiliki teks/lokasi default Cilegon.
- Footer di `src/components/AppShell.tsx`: copyright memakai nama situs dari Settings; periksa teks deskripsi dan informasi/footer statis lain agar sesuai dengan komunitas baru. `src/components/AppCredit.tsx` memuat kredit pembuat tetap—tentukan apakah kredit itu dipertahankan atau diganti sesuai kebutuhan clone.
- `public/`: logo, ikon PWA, manifest, service worker, dan gambar fallback.
- Supabase Edge Functions: template email, nama pengirim, URL tiket, pesan push/WhatsApp.
- Seed SQL: nama, lokasi, URL, dan data contoh.

Contoh: template ticketing saat ini memiliki branding/pengirim email tertentu di kode Edge Function. Domain dan akun Resend baru saja tidak otomatis mengganti `from`, logo, atau copy HTML. Pastikan semua nilai memakai branding komunitas baru sebelum deploy.

Perubahan hanya untuk identitas dan konfigurasi layanan. Jangan menghapus atau mengubah fitur aplikasi saat melakukan proses branding.

## Tahap 4 — Siapkan database baru dengan migration yang tervalidasi

### Status migration saat audit

Jangan menjalankan seluruh file dalam `supabase/migrations` secara membabi buta dan jangan langsung menjalankan `supabase db push` terhadap project baru berdasarkan urutan yang ada sekarang.

Audit awal 14 Oktober 2026 menemukan rangkaian schema awal yang berulang/duplikat, migration seed akun admin, dan migration fitur sampai `20261013140000_add_annual_recap_music.sql`. Source terbaru juga mencakup Annual Recap, lineup Event, pengalaman panggung Member, dan jadwal CCS. Migration `20261009100000_create_annual_recaps.sql` menjadi prasyarat migration musik Annual Recap; keduanya harus dipertimbangkan bersama bila fitur Annual Recap dipakai. Migration `20261010100000_update_community_logo.sql` masih menulis path logo Cilegon dan tidak boleh diterapkan apa adanya pada Serang. Tambahan migration terbaru ini **belum** membuktikan urutan yang aman untuk database kosong.

Pada 14 Oktober 2026, workspace uji maintainer menerapkan baseline netral, hardening Storage, dan grant publik foto kartu Komika. Verifikasi menunjukkan Settings Serang, tanpa seed Open Mic/Event/Komika/CCS/Annual Recap, RLS push aktif, dan anon dapat membaca `photo_card` tanpa akses ke `full_name`/WhatsApp. Pemeriksaan lanjutan menemukan query detail Komika meminta `karya_url`, tetapi baseline tidak memberi grant kolom tersebut; sebelumnya error izin tertutup sebagai tampilan “Komika tidak ditemukan”. Migration `20261015110000_grant_public_komika_karya_url.sql` memberi akses hanya ke kolom karya publik untuk anon/authenticated, dan halaman Komika membedakan gagal muat dari data kosong. Migration kini telah diterapkan dan diverifikasi di project Serang; hasilnya tercatat di bagian pemeriksaan terbaru. Detail project dan credential uji tidak dicatat di panduan publik.

### Pemeriksaan lanjutan — 15 Oktober 2026

- Smoke test tanpa login ke preview publik berhasil membuka Home, Open Mic, Event, Komika, More, dan halaman Gabung, Tentang, Kerja Sama, serta Kontak. Ini hanya membuktikan route dapat dimuat, bukan seluruh interaksi atau alur transaksi.
- Pemeriksaan awal menemukan daftar Komika menampilkan Serang Geh sementara detail `/komika/serang-geh` gagal dengan `401 / 42501: permission denied for table komika`. Query detail meminta `karya_url`; baseline belum memberi grant kolom tersebut.
- Audit referensi database di frontend dan Edge Functions tidak menemukan tabel, RPC, atau nama bucket yang dipakai aplikasi tetapi tidak didefinisikan dalam paket migration clone. Ketiga bucket yang dirujuk (`standupindo-media`, `ticket-payment-proofs`, `annual-recap-audio`) terdefinisi di baseline. Keberadaan definisi bukan bukti upload, download, policy, atau signed URL berhasil pada setiap role.
- Paket clone berisi baseline gabungan dan empat patch sebelumnya: hardening policy Storage, grant foto kartu Komika, penautan akun service-role, dan pembaruan specialties Member. Semua lima migration tersebut sudah tercatat di remote. Pada 15 Oktober, `supabase db push --dry-run` menunjukkan hanya `20261015110000_grant_public_komika_karya_url.sql` yang pending; migration itu kemudian diterapkan, dan `supabase migration list` mengonfirmasi keenamnya tercatat remote.
- Verifikasi privilege database setelah deploy: role `anon` dapat SELECT `karya_url`, tetapi tidak `full_name` atau `whatsapp`. Role `authenticated` juga memiliki SELECT untuk ketiga kolom tersebut; ini adalah privilege yang sudah ada pada role sebelum patch kolom karya dan tidak diubah/dikurangi oleh migration ini. Karena policy publik Komika berlaku untuk authenticated pada profil yang diterbitkan/aktif, pembatasan data privat bagi semua user login perlu ditinjau terpisah sebelum klaim keamanan produksi.
- Preview menggunakan project ref `dyrqcpbcdxgfryxtgyzg` (`.env` mengarah ke host project yang sama). Sesudah migration diterapkan, uji ulang tanpa login pada `https://standupindoserang.vercel.app/komika/serang-geh` berhasil menampilkan detail Serang Geh; request REST Komika teramati berstatus 200. Selain patch grant Komika, tiga Edge Function Push juga telah dideploy. Halaman Admin/Member serta alur pembayaran, upload per-role, email, pengiriman Push nyata, dan check-in belum lulus smoke test menyeluruh.
- Perbandingan migration source: baseline clone memuat 90 source-migration markers. Sepuluh migration setup/awal yang timestamp-nya tidak ada di baseline merupakan schema/patch lama yang sudah digabung atau digantikan oleh baseline netral. Migration seed admin `20260903040009_create_admin_auth_user.sql` dan update logo Cilegon `20261010100000_update_community_logo.sql` memang sengaja tidak dibawa. Empat patch clone-specific (`20261014120000` sampai `20261014150000`: Storage, foto kartu, tautan akun service-role, dan specialties Member) disimpan terpisah, lalu grant `karya_url` sebagai patch kelima. Keenam file migration clone sudah tercatat diterapkan remote. Tidak ditemukan migration fitur source yang tertinggal selain file yang sengaja dikecualikan/digantikan tersebut.
- Verifikasi live: tabel fitur utama `annual_recaps`, `ccs_schedules`, `event_lineups`, `member_stage_experiences`, `push_subscriptions`, dan tabel siklus/delivery Push ada. Bucket `standupindo-media` dan `annual-recap-audio` berstatus public, sedangkan `ticket-payment-proofs` private—sesuai deklarasi baseline. Ini memeriksa konfigurasi bucket, bukan uji upload/download dengan seluruh role.
- Saat audit awal, migration branding Serang Sharing dan akun sosial masih lokal/pending. Setelah dry-run pada 15 Oktober hanya memuat dua file tersebut, keduanya diterapkan dan diverifikasi tercatat remote sebagaimana dicatat pada butir berikutnya. Patch title menormalkan hanya judul legacy yang sama persis dan mengubah default kolom; patch sosial menetapkan profil Serang pada Settings.
- Status sesudah tindak lanjut 15 Oktober: migration `20261015120000_rename_ccs_schedule_brand.sql` dan `20261015130000_set_serang_social_profiles.sql` telah diterapkan ke project `dyrqcpbcdxgfryxtgyzg`; `supabase migration list` mengonfirmasi seluruh delapan migration clone, termasuk kedua patch tersebut, tercatat remote. Patch judul hanya menormalkan title lama yang sama persis dan mengubah default; patch sosial mengisi URL akun sosial Serang pada baris Settings. Frontend belum dideploy, jadi perubahan ikon tanpa handle, navigasi mobile, dan header desktop memerlukan deployment aplikasi terpisah.
- Audit relasi/perhitungan Annual Recap pada 15 Oktober: jumlah Open Mic dan Event hanya mengambil aktivitas terbit, tidak dibatalkan, dan tanggalnya sudah masuk periode recap; penampilan Open Mic hanya pendaftar `confirmed` dengan presensi `attended`. Penampilan Event menghitung kategori lineup, opener, guest star, MC/host, special show, dan peran kustom `other`, tetapi tidak juri. Jumlah komika adalah identitas unik (ID Komika tertaut atau nama panggung untuk pengisi eksternal), dan first-timer merujuk ke penampilan Open Mic pertama yang tercatat. Jumlah member baru hanya menghitung profil aktif-terbit dan mencocokkan tahun di `joined_at` yang berupa teks, termasuk format seperti `September 2026`. Pengalaman panggung eksternal member tidak dijumlahkan sebagai event komunitas. Di data live yang diperiksa pada 15 Oktober, Open Mic dan Event tahun 2026 yang terbit berikutnya bertanggal 16 Oktober, sementara belum ada Komika aktif-terbit dengan tahun bergabung 2026; karena itu angka aktivitas/member 2026 yang tampil nol sesuai cakupan tanggal/data, bukan karena relasi atau migration Annual Recap hilang. Bucket musik tersedia, tetapi belum berisi file.
- **Konfigurasi backend Push sudah dipasang pada 15 Oktober:** pasangan VAPID P-256 baru untuk Serang, `VAPID_SUBJECT=https://standupindoserang.vercel.app`, dan `PUSH_WEBHOOK_SECRET` tersimpan sebagai Edge Function secrets. Ketiga fungsi `manage-push-subscription`, `send-web-push`, dan `automate-public-event-push` berstatus ACTIVE. Gateway JWT verification dimatikan untuk fungsi tersebut karena fungsi menerapkan pemeriksaan sesi Supabase, webhook secret, atau service-role secara internal. Uji runtime membuktikan endpoint publik mengembalikan public key, sender menerima webhook secret, dan pasangan VAPID diterima library web-push; pengecekan sender menggunakan ID subscription palsu sehingga tidak mengirim notifikasi. Scheduler Vault sudah berisi URL project dan service-role key yang diverifikasi cocok; cron aktif tiap 15 menit. Saat pemeriksaan tidak ada subscription PWA (`0`), sehingga pengiriman notifikasi ke perangkat belum dapat diuji.
- Saat domain resmi dipasang, ganti `VAPID_SUBJECT` ke URL HTTPS domain baru melalui Edge Function Secrets; pasangan VAPID tidak perlu dibuat ulang hanya karena subject/domain berubah. Public VAPID key tetap diberikan oleh `manage-push-subscription`, bukan melalui `VITE_VAPID_PUBLIC_KEY`. `.env.example` dan panduan clone sudah disesuaikan. Browser uji saat ini berstatus notifikasi belum aktif dan izin situs ditolak, jadi tes subscription/penerimaan pada perangkat masih perlu dilakukan. Vercel env tidak dapat diperiksa karena CLI Vercel tidak tersedia; implementasi saat ini memang tidak memerlukan `VITE_VAPID_PUBLIC_KEY`.
- **Konfigurasi pengirim Resend dipasang pada 15 Oktober:** secret `RESEND_FROM` diset sebagai `Standupindo Serang <noreply@standupindoserang.site>` sesuai pilihan pengelola; `RESEND_API_KEY` tersedia di Supabase dan nilainya tidak dibaca/ditampilkan. DNS publik mengembalikan record DKIM, SPF, MX pengiriman, dan DMARC, tetapi pemeriksaan Resend API dengan key yang dikonfigurasi dibalas `400 API key is invalid`; status domain Resend belum terkonfirmasi dan email uji belum berhasil dikirim. Ganti/perbaiki API key di Supabase, pastikan dashboard Resend menandai domain `standupindoserang.site` sebagai **Verified**, lalu uji satu order menggunakan alamat email tester yang dikuasai sendiri.
- Template email konfirmasi pembayaran dan Free Pass sudah diperbarui agar mobile-first, memakai palet marun-merah-kuning, menampilkan kode akses dengan jelas, dan menyertakan logo Serang. `ticketing-admin` versi 11 sudah aktif. Aset logo berhasil diperiksa di `standupindoserang.vercel.app`; `standupindoserang.site` saat ini masih menampilkan halaman domain parkir Hostinger, sehingga logo email sementara dimuat dari Vercel. Setelah domain website diarahkan ke hosting aktif dan aset PNG dapat diakses di sana, pindahkan URL logo ke domain tersebut.
- Satu log email pembayaran lama masih `failed` dengan alasan `Konfigurasi Resend belum tersedia.` (terjadi sebelum secret pengirim dipasang). Pembayaran yang sudah berstatus lunas tidak otomatis memicu ulang email karena pengiriman dikaitkan ke transisi status menuju `Lunas`; fitur “Cek / Kirim Ulang Kode Akses” saat ini mengembalikan kode/tautan WhatsApp dan bukan retry email. Jangan klaim email historis terkirim; untuk order tersebut kirim akses secara manual melalui alur admin dan verifikasi proses retry email secara terpisah sebelum menjanjikan pengiriman ulang.
- Source Edge Function tetap berada di `supabase/functions/`, terpisah dari konfigurasi CLI `supabase-serang/supabase/config.toml`. Deployment Push dilakukan dengan menyalin sementara hanya tiga folder fungsi ke direktori konfigurasi untuk deploy, lalu menghapus salinan tersebut; worktree tidak menyimpan salinan deploy.

Staging belum lulus smoke test lengkap: sepuluh Edge Functions termasuk administrasi, statistik Annual Recap, check-in, ticketing, dan tiga fungsi Push sudah aktif. Secret enkripsi/pepper ticketing sudah disiapkan, dan halaman Admin Accounts sudah lulus smoke test tanpa request CORS gagal. Profil Komika Serang Geh kini tertaut ke akun Member. Simpan Komika mengabaikan kolom sistem `user_id`/ID; trigger mengizinkan service-role menautkan akun dan Member memperbarui specialties tanpa mengubah field terlindungi. Save profil tetap perlu diuji dari sesi Member. Pesan kegagalan pembuatan akun kini membaca alasan dari Edge Function. Push secrets dan Vault scheduler sudah dikonfigurasi; masih perlu tes izin/subscription perangkat dan pengiriman aktual. Template email tiket sudah diperbarui dan `ticketing-admin` versi 10 aktif, tetapi pengiriman tetap terblokir sampai API key Resend valid dan domain terverifikasi; situs `standupindoserang.site` juga masih parked. Upload per-role, RPC dengan akun non-admin, email/tiket, dan alur check-in belum lulus pengujian menyeluruh. Baseline staging bukan perintah untuk production; urutan sumber di bawah tetap catatan penelaahan, bukan urutan deploy siap pakai. Jangan catat password akun di repository atau chat.

Migration seed admin berikut tidak boleh dijalankan untuk produksi:

```text
20260903040009_create_admin_auth_user.sql
```

Panduan arsip `DUPLICATE_DEPLOY_GUIDE.md` pernah mencantumkan urutan yang hanya mencakup baseline/fitur lama. **Jangan menyalin urutan itu** untuk project baru saat ini; itu belum mencakup seluruh fitur terbaru, termasuk ticketing, push, materi, sesi akun, serta foto kartu Komika.

### Yang wajib disiapkan penanggung jawab teknis

1. Siapkan satu baseline migration bersih dan berurutan dari **seluruh fitur yang akan dipakai**, bukan hanya schema awal. Urutan kandidat bagian A, lalu B, lalu C di bawah hanya panduan penelaahan teknis; jangan jalankan daftar tersebut sebelum staging kosong membuktikannya.
2. Periksa dependensi, tabel/kolom yang diasumsikan ada, policy RLS/Storage, seed/demo, trigger/RPC, dan fungsi yang memanggil layanan eksternal.
3. Hapus dari paket produksi credential seed dan semua URL/key milik Cilegon; jangan melonggarkan policy untuk mempermudah setup.
4. Jalankan urutan tersebut pada database Supabase staging baru yang kosong. Uji dari nol; jangan memakai database Cilegon sebagai percobaan.
5. Uji RLS (anon, member, role operasional, admin), Storage, RPC, Edge Functions, dan alur aplikasi untuk seluruh fitur terpilih.
6. Simpan urutan migration yang lolos, hasil pengujian, dan commit paketnya. Setelah itu barulah pengelola dapat mengikuti instruksi migration yang spesifik pada paket tersebut untuk project production.
7. Deploy Edge Functions yang cocok dengan commit aplikasi dan set secret milik komunitas. Jangan mengaktifkan job push sebelum secrets dan endpoint project baru benar.

**Status praktis baseline staging (14 Oktober 2026):** workspace `supabase-serang/` memuat baseline gabungan tenant-neutral dari 90 source markers; baseline tersebut menambahkan schema `push_subscriptions` yang tidak ada di source chain dan tidak membawa demo data/admin Cilegon. Baseline dan patch Storage telah diterapkan ke staging kosong. Status patch tambahan dan pemeriksaan terbaru dirinci pada bagian “Pemeriksaan lanjutan”. Jangan menjalankan `supabase db push` dari direktori migration utama atau menerapkan baseline staging ke production. Tahan deployment publik sampai seluruh tes serta function/secrets lulus.

Jangan pernah menganggap daftar A/B/C sebagai urutan resmi hanya karena sudah dikelompokkan. Penanggung jawab teknis harus menghasilkan satu paket/commit final dengan urutan yang benar-benar diuji, serta menyatakan migration mana yang termasuk dan tidak termasuk. Karena target clone adalah kesetaraan fitur, staging Serang memasukkan Annual Recap beserta audio. Fitur ini belum boleh dibawa ke production sebelum Storage, RLS, dan alur upload/playback lulus uji.

### Urutan kandidat hasil telaah dependensi

Ini adalah daftar file yang tampak membentuk jalur fitur source saat ini, disusun ulang bila suatu migration memakai kolom yang ditambahkan migration sesudahnya. Daftar bukan instruksi untuk paste ke SQL Editor, dan belum membuktikan bahwa tiap file berhasil pada project Supabase kosong.

**A. Fondasi, Open Mic, profil, dan event**

```text
20260903035848_create_standup_indo_cilegon_schema.sql
20260903035853_add_registration_seq_rpc.sql
20260903035858_add_maps_url_and_contacts.sql
20260903035903_add_social_affiliation_settings.sql
20260903035907_add_ticket_price_to_events.sql
20260903035912_extend_event_tickets_with_url_status_sort.sql
20260903035918_fix_open_mic_registrations_rls_protect_whatsapp.sql
20260903035924_create_media_storage_bucket.sql
20260903050000_add_branding_settings.sql
20260904090000_add_open_mic_attendance_status.sql
20260904100000_add_komika_joined_at.sql
20260904110000_add_context_whatsapp_settings.sql
20260904120000_add_whatsapp_contact_names.sql
20260909100000_add_community_and_event_participants.sql
20260910100000_add_full_name_to_komika.sql
20260910110000_link_open_mic_registrations_to_komika.sql
20260910120000_restrict_komika_private_columns.sql
20260910130000_public_event_lineup.sql
20260912010000_add_komika_featured_order.sql
20260912000000_restore_public_select_grants.sql
20260912020000_add_event_rules_to_events.sql
20260913000000_add_partners_and_event_partnerships.sql
20260913010000_add_partner_event_pic_columns.sql
```

`20260912010000_add_komika_featured_order.sql` sengaja ditempatkan sebelum `20260912000000_restore_public_select_grants.sql`: migration grant memberi akses kolom `featured_order`, sehingga kolom itu harus sudah ada.

**B. Tiket awal, member, evaluator, dan role admin**

```text
20260913110000_create_ticket_orders.sql
20260913120000_add_email_to_ticket_orders.sql
20260913130000_add_order_number_to_ticket_orders.sql
20260915000000_add_evaluator_assignment_and_evaluation.sql
20260915100000_extend_member_profile_and_notifications.sql
20260915110000_harden_member_rls_and_profile_updates.sql
20260915120000_close_authenticated_public_registration.sql
20260915130000_support_global_evaluator_assignments.sql
20260915140000_allow_global_evaluator_assignments.sql
20260915150000_member_read_evaluations_by_profile.sql
20260916100000_add_operational_admin_roles.sql
20260917100000_register_member_open_mic_rpc.sql
20260917110000_prevent_duplicate_member_open_mic_registration.sql
20260917120000_register_public_open_mic_rpc.sql
20260917130000_allow_open_mic_admin_read_komika.sql
20260918000000_add_member_notification_reads.sql
20260921150000_allow_open_mic_admin_manage_evaluator_assignments.sql
20260921152000_add_karya_url_to_komika.sql
20260921153000_create_private_materials.sql
20260921154000_create_private_material_nodes.sql
20260921155000_create_private_material_setlists.sql
20260921160000_create_member_open_mic_history_submissions.sql
20260921170000_fix_public_open_mic_lineup_access.sql
20260922000000_restore_public_komika_read_access.sql
20260923100000_allow_members_delete_rejected_open_mic_history.sql
20261001090000_add_material_premis.sql
```

**C. Ticketing V1, Gate, push, dokumentasi Event, dan penyempurnaan**

```text
20261002100000_ticketing_v1_access_foundation.sql
20261002110000_ticketing_v1_core_schema.sql
20261002120000_ticketing_v1_order_rpcs.sql
20261002130000_ticketing_v1_lifecycle_rpcs.sql
20261002140000_grant_authenticated_ticket_order_rpc.sql
20261002150000_limit_ticket_order_quantity_to_10.sql
20261002160000_allow_legacy_sudah_bayar_payment_review.sql
20261002170000_restrict_event_ticket_crud_to_scoped_ticket_admins.sql
20261002180000_fix_ticket_access_session_expiry_ambiguity.sql
20261002190000_ticketing_checkout_drafts_until_proof.sql
20261002200000_reset_ticket_login_limits_on_success.sql
20261002210000_scope_ticket_login_limits.sql
20261002220000_ticket_gates_checkin_windows.sql
20261002230000_optional_ticket_gate_restrictions.sql
20261002235500_default_checkin_event_day.sql
20261003000000_preserve_disabled_gate_config.sql
20261003020000_enable_ticket_order_notifications.sql
20261003030000_ticket_payment_email_logs.sql
20261003050000_automate_event_open_mic_push_notifications.sql
20261004090000_isolate_pwa_push_subscriptions.sql
20261004100000_add_event_documentation_photos.sql
20261004110000_ensure_event_documentation_schema.sql
20261004114000_ticketing_free_pass.sql
20261004120000_reuse_ticket_payment_methods.sql
20261004130000_clear_default_whatsapp_contact_numbers.sql
20261006100000_add_ots_ticket_sales.sql
20261006110000_auto_deactivate_event_payment_methods.sql
20261006120000_add_mc_member_history.sql
20261007082000_fix_ticket_order_payment_assignment_lookup.sql
20261007083000_default_ticket_payment_method.sql
20261007134000_add_account_active_sessions.sql
20261008120000_add_komika_card_photo.sql
```

Urutan terakhir penting: setelah model pembayaran Event dipindah ke tabel assignment oleh `20261004120000_reuse_ticket_payment_methods.sql`, migration penjualan OTS mengganti fungsi order, lalu `20261007082000_fix_ticket_order_payment_assignment_lookup.sql` memperbaiki fungsi itu agar membaca assignment. Checkout publik jangan diaktifkan sebelum fungsi final ini dan smoke test pembayaran berhasil.

### Blocker dan perubahan wajib sebelum urutan kandidat dapat disahkan

| Temuan | Dampak / tindakan |
| --- | --- |
| `20260903035848_create_standup_indo_cilegon_schema.sql` bukan schema-only: ia memasukkan contoh Komika/Open Mic/Event/tiket Cilegon dan memberi policy awal `authenticated` yang luas. Beberapa migration berikut juga menulis kontak/branding Cilegon. | Buat baseline clone netral tanpa seed/data Cilegon; set identitas baru setelah migration yang memodifikasi Settings selesai. Jangan bawa data atau akun produksi. |
| Source chain tidak membuat `public.push_subscriptions`, tetapi `20261004090000_isolate_pwa_push_subscriptions.sql` langsung mengubah tabel itu. Baseline staging menambahkan schema dasar push, mengaktifkan RLS, dan mencabut akses langsung `anon`/`authenticated`. | Schema kini ada di baseline staging; sebelum mengaktifkan push, uji subscription/role melalui Edge Functions setelah deploy dan secret VAPID/webhook tersedia. |
| `20261004110000_ensure_event_documentation_schema.sql` mengulang kolom/constraint dari `20261004100000_add_event_documentation_photos.sql`. | Keduanya tampak idempotent, tetapi pilih satu sumber definisi di baseline bersih atau buktikan keduanya berjalan berurutan. Jangan menghapus migration dari ledger database yang sudah berjalan. |
| Policy source awal `standupindo-media` mengizinkan semua role `authenticated` upload, update, dan hapus media. Baseline staging menggantinya dengan policy per role/folder; upload Member kini memakai subfolder ID akun. | Uji upload/delete Admin, role Open Mic/Event, Member pada folder sendiri, dan pastikan Member lain serta evaluator tidak dapat menulis folder tersebut. Public read untuk bucket media memang tetap aktif agar poster/logo dapat ditampilkan. |
| `20260917100000_register_member_open_mic_rpc.sql` dan `20261006120000_add_mc_member_history.sql` berisi teks komunitas Cilegon di fungsi SQL. | Jadikan nama komunitas konfigurasi/brand baru, atau pastikan fungsi tersebut diganti pada paket clone dan dites. |
| `20261010100000_update_community_logo.sql` menetapkan logo Cilegon yang sudah tidak ada pada aset Serang. | Jangan masukkan migration ini apa adanya; gunakan logo Serang yang benar di seed Settings baseline. |
| `20261012130000_create_ccs_schedules.sql` memiliki judul default `Cilegon Comedy Sharing (CCS)`. Migration terbaru lain membuat lineup Event, pengalaman panggung, dan audio Annual Recap. | Sesuaikan default CCS dengan identitas Serang; urutkan migration fitur baru setelah tabel prasyaratnya dan uji RLS/Storage-nya. Jika Annual Recap diaktifkan, sertakan tabel Annual Recap sebelum migration musik dan bucket audio. |
| Migration push menggunakan `pg_cron`, `pg_net`, schema Vault, dan secret URL/service-role di Vault. Ticketing juga memakai job cron dan secrets Edge Function. | Pastikan extension tersedia, secrets project baru diset, dan job baru diaktifkan setelah function ter-deploy serta dites. Jangan salin secrets atau job dari project lain. |
| Policy awal beberapa tabel memberi akses kepada semua `authenticated`. Migration `20260915110000_harden_member_rls_and_profile_updates.sql` dan `20260916100000_add_operational_admin_roles.sql` menggantinya untuk sebagian besar tabel, termasuk community applications dan partners. | Kedua migration role tersebut wajib ada sebelum akun non-admin dibuat. Verifikasi policy final seluruh tabel—khususnya Storage dan tabel yang tidak disentuh migration tersebut—dengan akun member/evaluator biasa. |

### File yang dikecualikan dari paket clone baru

Berkas berikut merupakan baseline/patch lama yang duplikat, perubahan untuk memperbaiki Auth yang dibuat manual, atau seed Cilegon. Jangan jalankan sebagai tambahan setelah jalur kandidat di atas:

```text
20260826072748_create_standup_indo_cilegon_schema.sql
20260826073021_add_registration_seq_rpc.sql
20260826080529_revision_add_maps_url_and_contacts.sql
20260827044933_20260827090000_add_social_affiliation_settings.sql.sql
20260828023943_20260828091000_fix_auth_users_null_columns.sql.sql
20260828025351_20260828092000_set_admin_app_role.sql.sql
20260829015642_20260828100000_create_media_storage_bucket.sql.sql
20260902014716_add_ticket_price_to_events.sql
20260903023741_extend_event_tickets_with_url_status_sort.sql
20260903024408_fix_open_mic_registrations_rls_protect_whatsapp.sql
20260903040009_create_admin_auth_user.sql
```

Catatan: migration Auth lama bukan pengganti pembuatan admin melalui Supabase Auth API. Jangan membuat akun dengan password SQL yang tertanam di source.

Sebelum label status di bagian ini diubah menjadi “tervalidasi”, penanggung jawab teknis perlu membuat Supabase staging kosong, menyusun baseline netral, menjalankan seluruh urutan terpilih dari nol, memverifikasi schema/policies/RPC/extensions/functions, dan mencatat hasilnya. Repository saat ini tidak menyertakan `supabase/config.toml`, sehingga belum ada konfigurasi Supabase CLI lokal yang siap dipakai untuk membuktikan `db reset` dari source ini.

### Supabase CLI atau SQL Editor?

- **Pilihan yang disarankan setelah paket tervalidasi tersedia:** minta penanggung jawab teknis memakai Supabase CLI sesuai instruksi paket. CLI membantu menyimpan riwayat migration.
- SQL Editor hanya boleh dipakai oleh orang yang diberi urutan SQL hasil validasi; jalankan sesuai urutan, satu langkah per satu langkah, dan catat hasilnya.
- Jangan campur SQL Editor dengan `db push` tanpa menyelaraskan riwayat migration. Hal ini dapat membuat migration terulang atau status riwayat tidak sesuai.
- CLI bukan pengganti pengujian. Bila paket belum diuji dari database kosong, kedua cara tetap berisiko.

Jangan memasukkan data komunitas Cilegon ke database baru. Buat admin baru melalui prosedur Auth yang disiapkan dan diuji penanggung jawab teknis; role Admin Penuh harus diberikan dengan mekanisme server-side yang aman. Pengelola non-teknis jangan mengedit tabel `auth.users`, menjalankan SQL untuk role, atau menebak lokasi metadata Auth. Jangan gunakan seed admin/password yang ada di migration.

## Tahap 5 — Konfigurasi Supabase dan Edge Functions

Setelah schema lolos validasi dan diterapkan ke project baru:

1. Atur Auth Site URL dan redirect URL ke domain HTTPS komunitas baru.
2. Periksa RLS untuk semua tabel serta policy `storage.objects`. Pastikan anon hanya mendapat akses publik yang memang diperlukan, dan operasi admin benar-benar dibatasi dengan role.
3. Buat bucket/policy sesuai migration tervalidasi. Jangan menggunakan bucket atau Storage project lain.
4. Masukkan secrets Edge Function ke Supabase Secrets/Vault project ini, bukan `.env` frontend.
5. Deploy Edge Functions yang digunakan aplikasi, termasuk fungsi auth/admin, ticketing, dan push jika fitur terkait diaktifkan.
6. Untuk push automation, migration menjadwalkan job dan memerlukan extension/configuration serta URL dan service-role key project ini di Vault. Gunakan VAPID dan webhook secret khusus komunitas.
7. Periksa log function setelah deploy. Jangan mengaktifkan scheduler sebelum secrets dan endpoint target telah benar.

Daftar nama secret harus diinventarisasi dari `Deno.env.get(...)` di setiap function yang akan dideploy. Masukkan hanya secret yang memang diperlukan fungsi tersebut, dan simpan nilainya secara privat.

Source saat audit menyediakan Edge Functions berikut; deploy hanya versi dari repository clone yang sama dan ikuti inventaris secret per fungsi:

| Fungsi | Kegunaan |
| --- | --- |
| `admin-create-member`, `admin-manage-members`, `admin-manage-admins` | Pembuatan dan pengelolaan akun |
| `ticketing-public`, `ticketing-admin`, `ticketing-check-in-report` | Alur tiket publik, administrasi tiket, dan laporan check-in |
| `manage-push-subscription`, `send-web-push`, `automate-public-event-push` | Subscription dan pengiriman/jadwal push bila fitur push digunakan |

Jangan menyalin/deploy folder `_shared` sebagai function terpisah; itu adalah kode bersama. Penanggung jawab teknis harus memeriksa perubahan fungsi, dependensi database, dan secret wajib sebelum deploy.

### Fitur terbaru yang perlu disiapkan pada clone

Fitur di bawah sudah ada pada source saat runbook ini diperbarui. Jika fitur dipakai di komunitas baru, masukkan migration dan konfigurasinya ke baseline bersih yang telah diuji; jangan menyalin data atau secrets produksi Cilegon.

| Fitur | Yang wajib disesuaikan atau diuji |
| --- | --- |
| Login lintas perangkat | Migration `20261007134000_add_account_active_sessions.sql` membuat catatan perangkat aktif, RLS, dan Realtime. Sertakan dalam paket migration tervalidasi dan terapkan sebelum frontend yang memakai fitur ini. Uji login Admin dan Member di dua browser/perangkat, pilihan batal dan pindah, serta logout. Realtime mengeluarkan sesi aplikasi lama; Supabase tidak dapat membatalkan access JWT yang sudah diterbitkan sebelum masa berlakunya habis. |
| Email dan akses tiket | `ticketing-admin` membentuk tautan tiket dari origin aplikasi dan membaca alamat pengirim dari secret `RESEND_FROM` (format Resend: `Nama Komunitas <alamat@domain-terverifikasi>`). Verifikasi domain komunitas di Resend, lalu set `RESEND_API_KEY` dan `RESEND_FROM` milik komunitas. Buat nilai rahasia unik untuk `TICKET_ACCESS_CODE_ENCRYPTION_KEY`, `TICKET_ACCESS_CODE_PEPPER`, dan `TICKET_ACCESS_RATE_LIMIT_PEPPER` sesuai kebutuhan `ticketing-admin`/`ticketing-public`; jangan gunakan ulang nilai Cilegon. |
| Ketersediaan tiket | Uji kategori yang kuotanya benar-benar habis (tidak dapat dipesan dan tidak ditawarkan sebagai tiket tersedia) terpisah dari kategori yang kuotanya sedang tertahan order belum selesai (tetap terlihat tetapi pemesanan nonaktif). Pastikan pemeriksaan server pada `ticketing-public` tetap menjadi otoritas, bukan hanya status UI. |
| Notifikasi Admin dan Member | Buat order tiket uji dan pastikan notifikasi Admin Tiket menampilkan nama pembeli, event, dan kategori/status yang tepat. Pastikan badge mengikuti menu tujuan untuk setiap role Admin dan Member, bukan hanya total lonceng. Uji perubahan status/realtime dan hak akses tiap role. |
| Popup Instagram | Isi `instagram_url` pada Settings dengan URL HTTPS Instagram komunitas baru. Popup hanya untuk pengunjung yang belum login, menunggu sekitar 4 detik, dan tidak tampil di halaman tiket/pendaftaran. Batas saat ini maksimal 3 kali per 30 hari, minimal jeda 1 hari, jeda 7 hari setelah ditutup, dan 30 hari setelah follow. Status tersimpan di browser, bukan di akun; uji tampil/tutup/follow pada browser bersih. |

## Tahap 6 — Isi data dan branding

1. Login menggunakan akun admin baru.
2. Isi Settings: nama komunitas, logo, warna, kontak, sosial, alamat, dan afiliasi.
3. Ganti semua seed Open Mic/Event/Komika dengan data komunitas baru sebelum publikasi.
4. Upload logo/favicons/PWA assets ke lokasi project baru dan perbarui aset yang masih spesifik Cilegon.
5. Konfigurasikan penerima pembayaran/QRIS serta kebijakan tiket komunitas tersebut.
6. Verifikasi email Resend memakai `from` yang telah diverifikasi dan template/tautan menampilkan identitas komunitas yang tepat.

Jangan menyalin order, bukti pembayaran, nomor WhatsApp pendaftar, akun Auth, subscription push, atau data pribadi komunitas lama.

## Tahap 7 — Environment dan build frontend

**Peringatan penting:** `.env.example` berisi placeholder. File `.env` lokal diabaikan Git dan dapat menunjuk ke project development milik pengelola. Sebelum build/deploy, cocokkan URL serta publishable/anon key dengan project komunitas yang dituju. `VITE_*` adalah nilai publik; jangan pernah menaruh service-role key, Resend API key, VAPID private key, atau webhook secret di frontend.

Gunakan hanya nilai publik dari Supabase project komunitas baru:

```env
VITE_SUPABASE_URL=https://PROJECT_REF.supabase.co
VITE_SUPABASE_ANON_KEY=YOUR_PUBLISHABLE_OR_ANON_KEY
```

`VITE_*` dimasukkan ke bundle dan dapat dilihat di browser. Isinya hanya boleh berupa konfigurasi publik; jangan masukkan `service_role`, Resend API key, VAPID private key, atau secret webhook. Implementasi Push meminta public VAPID key dari Edge Function `manage-push-subscription`, jadi tidak memerlukan `VITE_VAPID_PUBLIC_KEY`.

Untuk Vercel, buka pengaturan project lalu isi `VITE_SUPABASE_URL` dan `VITE_SUPABASE_ANON_KEY` dari project komunitas yang dituju. Setelah mengganti Environment Variables, jalankan deployment ulang agar build membaca nilai baru.

Jalankan quality gate dari repository komunitas baru:

```bash
npm ci
npm run typecheck
npm run lint
npm run build
```

Jangan publish bila perintah wajib gagal atau konfigurasi masih menunjuk ke project/domain komunitas lain.

## Tahap 8 — Deploy hosting dan domain

### Vercel (opsi paling sederhana)

1. Masuk ke akun Vercel milik komunitas dan pilih **Add New Project**.
2. Import repository GitHub clone, bukan repository Cilegon.
3. Gunakan root directory repository. Periksa build command `npm run build` dan output directory `dist`.
4. Isi Environment Variables sesuai Tahap 7. Jangan masukkan service-role key atau secret server di sini.
5. Deploy ke URL preview lebih dulu. Pastikan konfigurasi Supabase Auth dan Edge Functions telah memakai project/domain clone.
6. Hubungkan domain komunitas setelah smoke test lolos, aktifkan HTTPS, lalu perbarui Site URL dan redirect URL Supabase Auth.

Vercel hanya membangun dan menyajikan frontend. Vercel tidak membuat schema database, akun admin, Storage bucket, atau secrets Edge Function.

### Hostinger/Apache

1. Arahkan DNS domain ke hosting komunitas baru dan aktifkan HTTPS.
2. Upload isi folder `dist` ke web root hosting (misalnya `public_html`), bukan folder `dist` sebagai subfolder.
3. Pastikan `index.html`, aset, dan aturan SPA fallback tersedia. Untuk Apache, pastikan `.htaccess` dari `public/` ikut masuk hasil deploy.
4. Jangan mengunggah `.env`, `node_modules`, service-role key, file lokal, atau source jika hosting hanya membutuhkan static build.
5. Pastikan konfigurasi Supabase Auth memakai domain baru.
6. Uji refresh langsung pada halaman publik, admin, member, event, dan Open Mic.

Perubahan `.env` frontend memerlukan build dan upload ulang `dist`.

## Tahap 9 — Uji sebelum diumumkan

### Isolasi layanan

- Domain mengarah ke hosting yang benar.
- Frontend memakai URL/key publishable milik Supabase project komunitas tersebut.
- Auth user, database, Storage, dan Edge Functions berada di project komunitas tersebut.
- Resend memakai akun/domain pengirim komunitas ini.
- Push memakai VAPID/webhook/Vault sendiri jika aktif.
- Tidak ada nama, logo, kontak, link, poster, email pengirim, atau URL tiket komunitas lain.

### Keamanan dan fitur

- Pengunjung publik tidak dapat membaca data pribadi pendaftar, bukti pembayaran, atau kolom internal.
- User login non-admin tidak dapat menjalankan operasi admin.
- Role operasional dibatasi pada scope yang benar.
- Uji registrasi publik/member, kapasitas, approval/attendance, event, order tiket, pembayaran, email, QR/check-in, expiry, dan upload sesuai fitur yang digunakan.
- Uji login/logout, reset/auth redirect, HTTPS, pembatasan Storage, serta error Edge Function.
- Ubah Instagram, TikTok, YouTube, alamat, deskripsi, dan nomor WhatsApp melalui Admin Settings; pastikan halaman More → Kontak & Sosial Media dan footer berubah pada sesi browser yang sama sesudah simpan. Pastikan nomor kosong tidak menghasilkan tautan WhatsApp rusak.
- Pada lebar mobile, uji lima item bottom navigation serta akses Partner dari More → `/more/kerja-sama`; pastikan More → `/more` dan hanya item route aktif yang tersorot. Uji desktop dengan lima item nav dan akses Partner dari More, serta tablet dengan tombol Menu.
- Uji menu Admin dengan tiap role yang digunakan: route yang tidak diizinkan tidak boleh muncul di desktop, bottom nav, atau More dan tidak boleh bisa dibuka lewat URL langsung.
- Pada kedua form reset password, uji tombol mata menyembunyikan/menampilkan hanya password baru, state kembali tersembunyi saat akun berganti/modal ditutup/sukses, dan reset tetap melalui Edge Function.
- Buat atau buka jadwal dengan title legacy dan title khusus; title legacy harus tampil sebagai Serang Sharing, title khusus tidak boleh ditimpa. Terapkan migration branding hanya di database test terlebih dahulu dan pastikan default baru serta nilai khusus tetap benar.
- Periksa log tanpa menampilkan token, password, kode akses, nomor pembayaran, atau data pribadi.
- Uji desktop dan mobile serta route langsung/refresh.

## Tahap 10 — Operasional berkelanjutan

- Setiap pengelola bertanggung jawab atas biaya, billing, rotasi secret, admin, backup, dan incident response resource-nya.
- Aktifkan backup database dan dokumentasikan pemulihan.
- Batasi admin hanya kepada orang yang perlu; cabut akses ketika tidak lagi bertugas.
- Catat versi/commit yang sedang live per komunitas.
- Terapkan security update dan perbaikan bug secara terpisah ke setiap repository mandiri.

## Checklist ringkas per komunitas

- [ ] Repository baru dan remote Git sudah benar.
- [ ] Domain, DNS, hosting, dan HTTPS mandiri.
- [ ] Supabase organization/project/database mandiri.
- [ ] Paket migration lengkap telah diuji pada database kosong.
- [ ] RLS dan Storage policies sudah diuji dengan anon, non-admin, dan admin.
- [ ] Admin baru dibuat; migration seed credential tidak dijalankan.
- [ ] Resend account, domain, sender, dan API key mandiri.
- [ ] Push secrets/VAPID/Vault mandiri jika push diaktifkan.
- [ ] Secrets ticket-access unik; sender email dan tautan tiket tidak lagi menunjuk ke Cilegon.
- [ ] Login lintas perangkat diuji setelah migration aktif dan sebelum frontend dirilis.
- [ ] Ketersediaan tiket, notifikasi pembeli, serta badge per-menu diuji untuk role terkait.
- [ ] Popup Instagram memakai URL komunitas baru dan aturan tampilnya diuji.
- [ ] Branding statis dan dinamis sudah diperiksa.
- [ ] Settings publik (Kontak/footer), navigasi Partner/More di mobile/tablet, reset password dengan ikon mata, dan label Serang Sharing sudah diuji.
- [ ] `.env` hanya berisi URL/key publik dari project baru dan tidak di-commit.
- [ ] `npm run typecheck`, `npm run lint`, dan `npm run build` lulus.
- [ ] Smoke test isolasi dan fitur lulus sebelum pengumuman.
