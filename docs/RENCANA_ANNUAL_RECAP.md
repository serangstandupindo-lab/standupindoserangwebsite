# Rencana Annual Recap

> **Status: IMPLEMENTED LOCALLY — ANNUAL RECAP MIGRATION APPLIED**

Dokumen ini menjadi acuan utama saat pekerjaan dilanjutkan melalui permintaan **"Lanjutkan Rencana Annual Recap"**. Isinya merangkum keputusan produk, audit role/RLS, batas data, status database, dan gerbang verifikasi.

## Status dan Artefak

- Halaman publik, Story, agregasi statistik, dan panel Admin Penuh sudah diimplementasikan lokal; typecheck masih melaporkan error di file non-Annual-Recap.
- Migration [20261009100000_create_annual_recaps.sql](../supabase/migrations/20261009100000_create_annual_recaps.sql) diterapkan langsung melalui CLI ke project linked, lalu versinya dicatat sebagai applied. Tabel, kolom, policy, dan grants diverifikasi sesudahnya.
- Hanya migration Annual Recap yang diterapkan. `supabase db push` tidak dijalankan karena migration history lokal/remote lain belum sinkron.
- Tidak ada perubahan tabel sumber, role, fitur lain, atau deployment aplikasi.

## Tujuan dan Ruang Lingkup

Annual Recap adalah rangkuman tahunan komunitas Standupindo Cilegon dalam format Story yang memakai data aplikasi yang sudah tersedia.

Termasuk dalam rencana:

- Halaman publik per tahun, dengan rancangan route `/recap/:year`.
- Pintasan di Home untuk recap published terbaru; recap draft tidak ditampilkan.
- Halaman pengelolaan untuk Admin Penuh/Superadmin: pilih tahun, simpan draft, publish/unpublish, edit narasi penutup, dan buka preview.
- Slide cerita berisi ringkasan metrik yang telah diverifikasi, kilas balik aktivitas, komunitas/komika, serta penutup.
- Pembatasan akses melalui pemeriksaan role di UI **dan** RLS Supabase.

Di luar ruang lingkup untuk saat ini:

- Tidak menambah menu archive di bagian Lainnya publik.
- Tidak menambah upload foto/video, tabel statistik, dependency Story baru, atau kolom database tanpa kebutuhan yang dijelaskan dan persetujuan terlebih dahulu.
- Tidak mengubah autentikasi, role, Open Mic, Event, ticketing, QR Scanner, PWA, navigasi, atau fitur existing di luar kebutuhan integrasi Annual Recap yang disetujui.

## Akses dan Identitas Role

Sumber role aplikasi adalah klaim Supabase Auth `app_metadata`, bukan status login umum atau tabel profil. Frontend membaca role secara eksak; `admin` berbeda dari role operasional. Detail aktual ada di [src/lib/auth.tsx](../src/lib/auth.tsx).

| Identitas | Nilai role | Hak Annual Recap yang direncanakan |
|---|---|---|
| Admin Penuh/Superadmin | `admin` | Kelola semua recap; baca draft dan published |
| Admin Open Mic | `open_mic_admin` | Tidak boleh mengelola atau membaca draft |
| Admin Event | `event_admin` | Tidak boleh mengelola atau membaca draft |
| Admin Tiket | `admin_ticket` | Tidak boleh mengelola atau membaca draft |
| Admin QR Scanner | `admin_qr` | Tidak boleh mengelola atau membaca draft |
| Member/Evaluator | `member` / `evaluator` | Tidak boleh mengelola atau membaca draft |
| Publik | `anon` | Hanya membaca recap published |

Syarat otorisasi fitur adalah role persis `admin`. `admin-app` hanya menunjukkan bahwa akun boleh masuk ke aplikasi admin; syarat tersebut mencakup role operasional dan **tidak** boleh dipakai sebagai izin Annual Recap.

Migration role operasional mendefinisikan `public.jwt_has_role(required_role text)`. Helper membandingkan teks role secara eksak setelah normalisasi huruf besar/kecil dan spasi. Implementasi memilih array `app_metadata.roles` jika tersedia, jika tidak memilih `user_roles` array, lalu fallback ke scalar `role`. Karena itu, klaim `role = 'admin'` lolos bila tidak dikalahkan oleh array yang diprioritaskan; konfirmasi bentuk klaim aktual akun Admin Penuh tetap menjadi gerbang sebelum implementasi.

## Aturan Statistik dan Sumber Data

Gunakan hanya data yang sudah ada dan dapat dibuktikan. Jangan mengubah status pendaftaran menjadi asumsi kehadiran.

- Penampilan Open Mic yang benar-benar terjadi harus difilter dengan `open_mic_registrations.attendance_status = 'attended'`. Kode aplikasi juga membedakan hadir dari sekadar confirmed; lihat pola pada [src/pages/admin/AdminPage.tsx](../src/pages/admin/AdminPage.tsx) dan [src/pages/member/MemberDashboardPage.tsx](../src/pages/member/MemberDashboardPage.tsx).
- Jangan menghitung pendaftar, pendaftar confirmed, atau orang dalam lineup sebagai komika yang benar-benar tampil.
- Jumlah penampilan dan jumlah komika unik adalah metrik berbeda. Komika unik sebaiknya dihitung dari ID komika yang valid pada baris attended. Baris tanpa `komika_id` tidak boleh dianggap sebagai identitas unik tanpa aturan pencocokan yang diaudit; tentukan apakah dilaporkan terpisah atau dikecualikan sebelum implementasi.
- Jangan menganggap peserta Event sebagai penonton yang hadir. Data `event_participants`/pendaftaran bukan bukti kehadiran aktual jika tidak ada field atau sumber check-in yang menyatakan kehadiran.
- Jumlah event, open mic, aktivitas per bulan, komunitas/komika teratas, dan momen teramai hanya boleh ditampilkan setelah definisi metrik, filter status/cancelled, kolom tanggal, relasi, serta rentang tahun diverifikasi terhadap skema dan data aktual.
- Tentukan batas tahun berdasarkan tanggal acara yang relevan dan konsisten dengan timezone proyek (umumnya WIB); jangan mencampur tanggal kalender dengan timestamp tanpa aturan eksplisit.
- Jangan memakai angka placeholder yang mungkin terdapat di scaffold lama. Nilai harus dihitung dari query sumber aktual, atau tidak ditampilkan jika tidak tersedia.
- Tahun tanpa data harus memiliki tampilan kosong yang jujur; jangan membuat angka atau acara sintetis.

## Rancangan UI/UX

- Pengalaman utama berupa Story fullscreen vertikal sembilan layar, bukan dashboard statistik berbentuk grid sebagai layar utama.
- Urutan layar: pembuka, angka setahun, komika yang sering tampil, komunitas, aktivitas bulanan, Open Mic dengan penampilan terbanyak, tiga Open Mic teraktif, kilas balik Event, dan penutup.
- Kilas balik memilih maksimal tiga Event published/completed yang punya poster atau dokumentasi. Tiap Event menampilkan maksimal tiga aset unik; pilih satu gambar utama dan thumbnail untuk aset sisanya agar layar tidak padat.
- Interaksi yang direncanakan: progress per slide, tap/aksi berikutnya dan sebelumnya, tahan untuk pause, kontrol pause/play, tombol tutup, serta dukungan `prefers-reduced-motion`.
- Hindari dependency Story baru selama komponen sederhana yang ada mencukupi. Jangan menambah upload/media baru; gunakan aset yang memang telah tersedia bila diperlukan.
- Admin dapat mengedit narasi penutup. Default copy yang pernah diusulkan hanyalah fallback dan perlu review produk sebelum dianggap final.
- Preview draft berjalan di dalam panel admin dan tidak membuka akses publik ke data draft.
- Simpan perubahan mempertahankan status publikasi. Publish dan unpublish adalah aksi eksplisit.
- Sediakan state loading, recap unpublished/tidak tersedia, tahun tanpa data, serta tampilan mobile dan desktop.

## Rancangan Database

Proposal menggunakan satu tabel `public.annual_recaps` untuk metadata publikasi per tahun, bukan untuk menyimpan agregat statistik:

| Kolom | Tujuan |
|---|---|
| `id` | UUID primary key, default `gen_random_uuid()` |
| `year` | Tahun recap, unique |
| `published` | Status draft/published, default false |
| `closing_narrative` | Narasi penutup opsional |
| `created_by` | ID pembuat opsional |
| `created_at` | Waktu pembuatan |
| `updated_at` | Waktu perubahan yang dikelola aplikasi untuk saat ini |

Tidak ada tabel atau kolom statistik tambahan yang disetujui. Statistik harus dibaca/agregasi dari sumber existing. Schema minimal pada proposal perlu dibandingkan dengan target aktual sebelum dijalankan: `CREATE TABLE IF NOT EXISTS` tidak memperbaiki atau memvalidasi struktur tabel yang sudah ada dengan nama sama.

## Hasil Audit RLS dan ACL

Proposal yang terakhir ditinjau menggunakan helper existing `public.jwt_has_role('admin')`; tidak membuat ulang helper global dan tidak memakai pencocokan substring `ILIKE '%admin%'`.

- SELECT published: policy permissive untuk `anon, authenticated` dengan syarat `published = true`.
- SELECT admin: policy permissive terpisah untuk `authenticated` dengan role eksak `admin`, sehingga Admin Penuh dapat membaca draft.
- SELECT visibility guard: policy restrictive untuk `anon, authenticated`, membatasi hasil ke published atau role eksak `admin`. Policy ini mencegah policy SELECT permissive lain pada tabel membuka draft.
- INSERT: policy admin dengan `WITH CHECK`, ditambah restrictive guard admin.
- UPDATE: policy admin memakai `USING` dan `WITH CHECK`, ditambah restrictive guard admin pada kedua tahap.
- DELETE: tidak diberikan untuk MVP; recap yang pernah dibuat dikelola lewat draft, publish, dan unpublish.
- Privilege tabel: proposal mencabut privilege pada tabel tersebut dari `PUBLIC`, `anon`, dan `authenticated`, lalu memberi SELECT ke `anon, authenticated` dan INSERT/UPDATE ke `authenticated`. RLS tetap membatasi operasi; GRANT saja tidak memberi akses ke draft atau melewati policy.
- `service_role` dan pemilik tabel adalah role backend istimewa yang dapat melewati RLS sesuai model Supabase; keduanya bukan role pengguna aplikasi yang diuji dalam tabel akses.

Definisi helper aktual berasal dari [migration operational roles](../supabase/migrations/20260916100000_add_operational_admin_roles.sql). Repository tidak menunjukkan `GRANT`/`REVOKE EXECUTE` eksplisit untuk helper maupun `ALTER DEFAULT PRIVILEGES`. Secara default PostgreSQL memberi EXECUTE pada fungsi baru kepada `PUBLIC`, sehingga `anon` dan `authenticated` semestinya dapat memanggil helper. Namun ACL Supabase yang terpasang tidak dapat dipastikan dari source saja.

## Status Migration

[20261009100000_create_annual_recaps.sql](../supabase/migrations/20261009100000_create_annual_recaps.sql) diterapkan dengan `supabase db query --linked --file ...`, lalu dicatat dengan `supabase migration repair --linked --status applied 20261009100000`. Verifikasi remote pada 13 Oktober 2026 menunjukkan tabel memiliki tujuh kolom yang direncanakan, tujuh policy SELECT/INSERT/UPDATE, anon dapat SELECT, authenticated dapat INSERT/UPDATE, dan DELETE tidak diberikan. Riwayat migration mencatat versi Annual Recap; tidak ada migration lain yang diterapkan dalam langkah tersebut.

Migration ini memakai helper global `public.jwt_has_role('admin')` dan hanya mengubah `public.annual_recaps`. Pemeriksaan remote mengonfirmasi helper tersedia, definisinya cocok, `anon` dan `authenticated` dapat menjalankannya, serta PostgreSQL remote versi 17.6 mendukung restrictive policy.

Peringatan operasional:

1. Jangan menjalankan `supabase db push` sebelum migration history lokal/remote yang lain direkonsiliasi; banyak versi lokal masih belum tercatat di remote.
2. Migration Annual Recap sudah diterapkan pada project linked yang diperiksa. Verifikasi ulang target sebelum mengulang SQL di environment lain.

## Langkah Verifikasi Sebelum Implementasi

1. Audit ulang skema dan query sumber untuk Open Mic, Event, komika, tanggal, timezone, status cancelled, serta data null. Tulis definisi setiap metrik dan cocokkan beberapa hasil dengan data sumber.
2. Pastikan helper ACL dan struktur/policy tabel memenuhi prasyarat di bagian Status Migration. Jalankan uji database hanya setelah lingkungan dan perubahan disetujui; mulai dari lingkungan non-produksi bila tersedia.
3. Uji RLS secara terpisah untuk `anon`, role `admin`, `admin_ticket`, `admin_qr`, `open_mic_admin`, `event_admin`, dan `member`: published dapat dibaca sesuai aturan; draft hanya oleh `admin`; create/update/publish/unpublish hanya oleh `admin`; DELETE tidak diberikan.
4. Uji halaman admin membaca semua tahun, membuat draft, mengubah narasi tanpa meng-unpublish, publish, unpublish, dan preview draft. Uji route publik hanya menampilkan published dan tidak membocorkan isi draft melalui query, error, cache, atau state UI.
5. Uji Story: next/previous, progress dan auto-advance, pause/resume, hold, close, reduced motion, loading, unavailable/unpublished, tahun tanpa data, dan viewport mobile/desktop.
6. Jalankan typecheck, lint, build, serta pemeriksaan regresi pada navigasi/fitur existing. Catatan audit sebelumnya: typecheck proyek gagal dengan 23 error pada 7 file non-Annual-Recap; ulangi pemeriksaan baseline dan pastikan perubahan Annual Recap tidak menambah error.
7. Laporkan file yang berubah, hasil verifikasi role/RLS, publish/unpublish, Story, build, dan status migration. Jangan menyatakan database teruji jika hanya validasi statis yang dilakukan.

## Batas Perubahan

Penerapan migration Annual Recap pada project linked sudah selesai. Deployment aplikasi dan penerapan migration lain tidak termasuk dalam pekerjaan ini; jangan jalankan `db push` sampai migration history direkonsiliasi.