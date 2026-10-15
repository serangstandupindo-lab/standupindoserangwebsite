# Panduan Clone Komunitas untuk Pemula

Panduan ini untuk pengelola komunitas yang tidak punya latar belakang coding. Targetnya: setiap komunitas punya website, data, dan layanan sendiri, sambil mempertahankan fitur aplikasi.

> **Status template:** source saat ini masih dalam uji staging. Database dasar sudah diterapkan, tetapi uji seluruh role/upload belum selesai; Push dan email Resend juga belum siap. Jangan pakai project live sampai pemilik source menandai rilis sebagai **SIAP CLONE / SIAP PRODUKSI**.

## Pilihan Paling Sederhana

Setelah ada rilis yang sudah lulus uji maintainer, setiap komunitas cukup membuat **satu project Supabase miliknya sendiri** untuk website live. Pengguna clone tidak perlu membuat staging kedua. Staging dipakai maintainer source satu kali untuk menguji rilis/schema baru, bukan dibebankan ke setiap komunitas.

Jangan jalankan folder `supabase/migrations` utama secara langsung. Folder itu berisi riwayat migration lama dan tidak dirancang sebagai paket database kosong. Untuk rilis yang sudah disetujui, gunakan baseline khusus `supabase-serang/supabase` dan ikuti langkah AI di bawah; maintainer perlu menyesuaikan nama paket ini sebelum menerbitkan template umum.

## Siapkan Data Komunitas

Isi daftar ini dulu. Tidak perlu membuat desain atau menulis kode:

- Nama resmi dan nama singkat komunitas.
- Kota, alamat, deskripsi, tagline Home, cerita Tentang, dan teks footer.
- Warna utama, hover, dan aksen dalam HEX, misalnya `#D71920` dan `#FFC928`.
- Logo utama transparan, favicon, ikon PWA Admin/Member/Public, serta gambar preview tautan.
- Nomor WhatsApp untuk admin, pendaftaran, kerja sama, dan tiket.
- URL Instagram, TikTok, YouTube, domain website, dan email pengirim.
- Fitur yang akan diaktifkan: Open Mic, Member/Evaluator, Event, tiket/QR, email, dan push.

Buat akun GitHub, Supabase, hosting (misalnya Vercel), dan Resend atas kepemilikan komunitas. Jangan gunakan akun, data, domain, atau credential komunitas lain.

## Langkah Clone

1. **Fork repository** ke GitHub milik komunitas. Jangan push perubahan ke repository sumber.
2. **Buat satu project Supabase milik komunitas.** Catat Project Ref, Project URL, dan publishable/anon key. Key publik ini boleh dipakai di browser; jangan mengambil `service_role` key untuk frontend.
3. **Tunggu rilis database dinyatakan siap.** Jika belum ada rilis dengan baseline teruji, berhenti di sini dan minta pemilik source menyiapkannya. Jangan menekan `db push` dari migration lama.
4. **Minta AI menyesuaikan branding** menggunakan Prompt Branding di bawah. Sertakan data komunitas dan nama file aset logo. Jangan menyertakan password atau secret.
5. **Isi environment frontend.** Salin `.env.example` menjadi `.env` hanya untuk kerja lokal, lalu isi `VITE_SUPABASE_URL` dan `VITE_SUPABASE_ANON_KEY` dari project komunitas yang sama. Untuk hosting, isi variabel yang sama di pengaturan Environment Variables Vercel. Jangan commit `.env`.
6. **Minta AI memeriksa dan menerapkan baseline rilis** menggunakan Prompt Setup. Pastikan AI menyebut nama project tujuan, menampilkan hasil dry-run, dan berhenti bila project/ref atau daftar migration tidak sesuai. Perintah database hanya dijalankan setelah kamu mengonfirmasi project tujuan.
7. **Buat akun Admin Penuh pertama** melalui Supabase Auth dengan prosedur bootstrap yang disediakan maintainer rilis. Beri tahu AI email akun saja jika perlu menautkan role; jangan kirim password. Admin pertama harus dibuat sebelum Admin operasional.
8. **Isi Settings dan data awal** melalui website: nama, logo, warna, kontak, sosial media, Open Mic, Event, Komika, payment method, dan aturan tiket. Database baru tidak membawa data contoh/produksi komunitas lain.
9. **Deploy Edge Functions** dari commit source yang sama. Untuk push/email/ticketing, siapkan secret sesuai tabel berikut sebelum mengaktifkan fiturnya.
10. **Deploy ke preview hosting**, uji alur yang akan dipakai di desktop dan mobile, lalu hubungkan domain dan HTTPS. Periksa Supabase Auth Site URL/redirect URL dan deploy ulang setelah Environment Variables diubah.

## Simpan Nilai di Tempat yang Tepat

| Nilai | Simpan di mana | Boleh masuk prompt/chat? |
| --- | --- | --- |
| `VITE_SUPABASE_URL` | `.env` lokal dan Environment Variables hosting | Ya, konfigurasi publik |
| `VITE_SUPABASE_ANON_KEY` / publishable key | `.env` lokal dan Environment Variables hosting | Boleh, tetapi lebih mudah isi langsung di file/dashboard |
| `RESEND_API_KEY`, `RESEND_FROM` | Supabase Edge Function Secrets | Jangan kirim nilai API key di chat |
| `TICKET_ACCESS_CODE_ENCRYPTION_KEY`, `TICKET_ACCESS_CODE_PEPPER`, `TICKET_ACCESS_RATE_LIMIT_PEPPER` | Supabase Edge Function Secrets | Jangan kirim nilainya di chat |
| `VAPID_PUBLIC_KEY`, `VAPID_PRIVATE_KEY`, `VAPID_SUBJECT`, `PUSH_WEBHOOK_SECRET` | Supabase Edge Function Secrets | Private key/webhook secret jangan dikirim di chat |
| `event_open_mic_push_project_url`, `event_open_mic_push_service_role_key` | Supabase Vault, hanya jika scheduler Push diaktifkan | Jangan kirim service-role key di chat |
| `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `SUPABASE_SERVICE_ROLE_KEY` untuk Edge Functions | Disediakan otomatis oleh Supabase pada runtime function | Jangan menyalin ke frontend atau repository |

Public VAPID key diambil aplikasi dari Edge Function `manage-push-subscription`; jangan menambahkan `VITE_VAPID_PUBLIC_KEY` ke frontend. Simpan pasangan VAPID server (`VAPID_PUBLIC_KEY`, `VAPID_PRIVATE_KEY`, `VAPID_SUBJECT`) hanya di Supabase Edge Function Secrets.

Jika domain email belum diverifikasi di Resend, lewati pengiriman email saat uji. Email tiket/Free Pass belum bisa dinyatakan berhasil sampai `RESEND_API_KEY` dan `RESEND_FROM` memakai domain pengirim terverifikasi. Jika Push belum disiapkan, jangan deploy/aktifkan scheduler Push.

## Prompt Siap Salin

Ganti teks di dalam kurung siku dengan data komunitas. **Jangan isi prompt dengan password, service-role key, Resend API key, VAPID private key, atau webhook secret.**

### Prompt Branding

```text
Saya pengelola komunitas awam dan mem-fork repository ini untuk komunitas baru.
Pertahankan semua fitur, alur, database contract, dan role yang ada; jangan menghapus atau menyederhanakan fitur.
Ubah hanya identitas berikut:
- Nama resmi: [NAMA KOMUNITAS]
- Nama singkat: [NAMA SINGKAT]
- Kota/alamat: [KOTA, PROVINSI]
- Tagline Home: [TAGLINE]
- Deskripsi/footer: [DESKRIPSI]
- Warna utama/hover/aksen: [HEX]
- Logo header: [PATH FILE LOGO TRANSPARAN]
- Favicon/PWA: [PATH FILE ASET]
- WhatsApp/sosial/domain: [DAFTAR KONTAK]

Audit source dan database baseline agar tidak ada default/link/logo komunitas lama yang tertinggal.
Jangan mengubah atau menjalankan migration, jangan deploy, dan jangan membuat akun.
Tunjukkan daftar perubahan serta hasil build. Jika ada nilai yang tidak tersedia, tanyakan dan jangan menebaknya.
```

### Prompt Setup Supabase

```text
Bantu saya menyiapkan clone komunitas ini langkah demi langkah, dengan bahasa sederhana.
Nama komunitas: [NAMA]
Project Ref Supabase tujuan: [PROJECT REF]
Project URL: [URL PUBLIK]
Target: [PRODUCTION setelah rilis disetujui / STAGING untuk maintainer]

Sebelum menjalankan perubahan database:
1. Pastikan folder baseline adalah paket resmi yang ditandai SIAP CLONE.
2. Cocokkan Project Ref yang ter-link dengan Project Ref di atas.
3. Tampilkan dry-run migration dan berhenti jika ada migration tak dikenal, seed akun/data contoh, atau target tidak cocok.
4. Tunggu persetujuan saya sebelum menerapkan migration.
5. Jangan pernah meminta atau menampilkan password, service-role key, API key, VAPID private key, atau webhook secret. Arahkan saya mengisi secret langsung di Supabase Dashboard.

Setelah disetujui, verifikasi schema/RLS/Storage, deploy hanya Edge Function yang diperlukan, lalu pandu saya membuat Admin pertama dan menguji fitur. Jangan menyentuh project Supabase lain.
```

### Prompt Secret dan Resend

```text
Tolong pandu saya mengatur secret Supabase untuk project [NAMA/PROJECT REF] satu per satu.
Jangan minta saya menempelkan nilai secret ke chat. Beri tahu nama secret, fungsinya, menu Dashboard tempat mengisinya, dan cara memeriksa bahwa nama secret sudah tersimpan tanpa membaca nilainya.
Email Resend belum siap karena domain belum diverifikasi; jangan mengarang sender dan jangan menyatakan email berhasil diuji.
Push hanya diaktifkan jika saya sudah membuat pasangan VAPID dan webhook secret khusus project ini.
```

### Prompt Error

```text
Saya awam. Bantu telusuri error berikut di clone komunitas ini: [TEMPEL PESAN ERROR, TANPA PASSWORD/KEY].
Periksa browser, Edge Function, migration, dan role yang terkait. Jangan membuat/menghapus akun atau mengubah data produksi.
Jelaskan penyebab dalam bahasa sederhana, buat perubahan terkecil, uji di staging jika menyentuh schema/security, lalu beri saya langkah ulang yang aman.
```

## Checklist Sebelum Diumumkan

- [ ] `.env` lokal dan Environment Variables hosting memakai URL/key dari project yang sama.
- [ ] Release baseline database berstatus SIAP CLONE; migration diterapkan ke project milik komunitas sendiri.
- [ ] Tidak ada data contoh atau akun komunitas lain.
- [ ] Akun Admin Penuh dibuat dan login berhasil; role Member, Evaluator, dan Admin operasional diuji sesuai kebutuhan.
- [ ] Pengunjung publik hanya melihat kolom/profil publik; RLS dan Storage sudah diuji.
- [ ] Open Mic, pendaftaran Member, Event, Komika, tiket/QR, email, dan Push diuji untuk fitur yang diaktifkan.
- [ ] Domain, HTTPS, Supabase Auth redirect, logo/PWA, sosial media, dan kontak komunitas sudah benar.
- [ ] `npm run build` berhasil; error typecheck/lint yang tersisa sudah ditriase.
- [ ] Tidak ada `.env`, service-role key, API key, password, atau secret di repository.

## Catatan Teknis untuk Maintainer

- Workspace uji/database terpisah diperlukan untuk **maintainer yang mengubah baseline, schema, policy, atau function**. Pengelola komunitas yang memakai rilis resmi teruji tidak perlu membuat staging kedua untuk setiap clone.
- Jangan deploy seluruh `supabase/migrations` utama. Gunakan hanya baseline resmi yang dirilis bersama source dan jangan mencampur migration CLI dengan SQL Editor manual.
- Sebelum menandai rilis SIAP CLONE, maintainer wajib menguji dari database kosong: schema, RLS, Storage, role, trigger/RPC, cron, Edge Functions, dan alur app. Jangan menandai siap hanya karena `db push` sukses.
- `supabase-serang/` saat ini adalah workspace uji Serang, bukan otomatis baseline umum production. Maintainer perlu menyesuaikan branding/default komunitas dan menerbitkan versi baseline yang disetujui sebelum publik menggunakan langkah database.
