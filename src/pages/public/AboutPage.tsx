import { useState } from 'react';
import { Mic, CalendarDays, Users, Handshake } from 'lucide-react';
import type { Router } from '@/lib/router';
import type { SiteSettings } from '@/lib/types';
import { PageHeader } from '@/components/PageHeader';
import { ImageLightbox } from '@/components/ui/ImageLightbox';

const ACTIVITIES = [
  { icon: Mic, label: 'Open Mic' },
  { icon: CalendarDays, label: 'Event' },
  { icon: Users, label: 'Community' },
  { icon: Handshake, label: 'Collaboration' },
];

const COMMUNITY_STORY = [
  'November 2013 menjadi salah satu titik awal perjalanan Standupindo Cilegon. Saat itu, Adam Datau, Luthfi, dan Entus Bewok tampil membawakan stand-up comedy dalam acara Apresiasi Seni di SMPN 5 Cilegon. Sebuah penampilan sederhana yang mungkin tak pernah mereka bayangkan akan membuka jalan bagi sesuatu yang lebih besar.',
  'Usai acara, Adam Datau mengunggah beberapa dokumentasi penampilan mereka ke Facebook. Respons pun berdatangan. Di antara banyaknya tanggapan, seorang pecinta stand-up comedy menawarkan kesempatan bagi mereka untuk tampil di Premiere Cafe.',
  'Tawaran itu membawa mereka ke sebuah panggung baru. Malam itu, mereka kembali tampil, sekaligus berkenalan dengan teman-teman dari Standupindo BSC (Banten Serang Cilegon), komunitas yang dalam perjalanannya kemudian berganti nama menjadi Standupindo Serang.',
  'Pertemuan tersebut menjadi bagian penting dari perjalanan mereka. Sebab, terkadang, sebuah perkenalan sederhana bisa membuka jalan menuju sesuatu yang sebelumnya tak pernah terpikirkan.',
  'Sekitar seminggu setelah penampilan itu, Adam Datau dihubungi oleh Ray Koto. Keduanya kemudian bertemu di Premiere Cafe. Dari pertemuan tersebut, muncul sebuah gagasan untuk membangun komunitas stand-up comedy di Kota Cilegon.',
  'Gagasan itu tidak berhenti sebagai percakapan di sebuah kafe. Open mic mulai digelar, promosi terus dilakukan, dan perlahan ruang bagi para pecinta stand-up comedy di Cilegon mulai terbentuk.',
  'Hingga akhirnya, pada Januari 2014, Standupindo Cilegon muncul ke permukaan dan secara resmi menandai terbentuknya komunitas ini.',
  'Waktu terus berjalan. Orang-orang datang dan pergi, pengalaman bertambah, dan banyak hal berubah. Namun, semangat yang mengawali perjalanan ini tetap menjadi bagian penting dari identitas Standupindo Cilegon.',
];

export function AboutPage({ router, settings }: { router: Router; settings: SiteSettings }) {
  const [logoLightbox, setLogoLightbox] = useState(false);
  return (
    <div className="animate-fade-in">
      <PageHeader router={router} title="Tentang Komunitas" />
      <div className="container-app py-10">
        <div className="mx-auto max-w-3xl">
          <article
            data-scroll-reveal
            className="scroll-reveal relative mx-auto overflow-hidden rounded-[26px] border border-[#cdbf9f] bg-[radial-gradient(ellipse_at_12%_18%,rgba(131,103,62,0.12),transparent_23%),radial-gradient(ellipse_at_92%_82%,rgba(131,103,62,0.1),transparent_20%),linear-gradient(135deg,#f3ead4_0%,#fbf6e9_48%,#efe3c9_100%)] px-5 py-7 text-left shadow-[0_18px_45px_rgba(70,55,32,0.12)] sm:px-10 sm:py-10"
          >
            <div className="pointer-events-none absolute inset-2 rounded-[20px] border border-[#b8a987]/45" />
            <div className="relative mx-auto max-w-2xl">
              <div className="mb-6 flex items-center gap-4 border-b border-[#8d7a58]/25 pb-5 sm:mb-7 sm:gap-5 sm:pb-6">
                <button
                  onClick={() => setLogoLightbox(true)}
                  aria-label="Lihat logo Standupindo Cilegon"
                  className="group flex h-[4.5rem] w-[4.5rem] shrink-0 items-center justify-center transition-transform duration-200 hover:scale-[1.03] sm:h-20 sm:w-20"
                >
                  <img src={settings.logo_url ?? '/assets/images/Logo%20Standupindo%20Cilegon%20Biru.png'} alt={`Logo ${settings.site_name}`} className="h-full w-full object-contain" />
                </button>
                <div className="min-w-0 font-mono text-[#302b22]">
                  <p className="text-[10px] font-bold uppercase tracking-[0.2em] text-[#806b46] sm:text-xs">{settings.site_name}</p>
                  <h2 className="mt-1 text-lg font-black leading-tight tracking-tight sm:text-2xl">Standupindo Cilegon: The Story</h2>
                  <p className="mt-1 text-xs italic leading-5 text-[#625740] sm:text-sm">Berawal dari tawa, tumbuh menjadi cerita.</p>
                </div>
              </div>
              <div className="font-mono text-[13px] leading-[1.65] text-[#302b22] sm:text-[15px] sm:leading-[1.7]">
                <div className="space-y-4 sm:space-y-5">
                  {COMMUNITY_STORY.map((paragraph) => <p key={paragraph}>{paragraph}</p>)}
                </div>
              </div>
            </div>
          </article>

          <div className="mx-auto mt-8 max-w-2xl text-center">
            <div data-scroll-reveal className="scroll-reveal overflow-hidden rounded-[30px] border border-slate-200 bg-[radial-gradient(circle_at_top,_rgba(96,165,250,0.12),_transparent_42%),linear-gradient(180deg,_#ffffff_0%,_#f8fbff_100%)] p-4 shadow-[0_18px_45px_rgba(15,23,42,0.06)] sm:p-6">
              <div className="rounded-[24px] border border-blue-100 bg-white/90 p-5 shadow-[0_10px_25px_rgba(37,99,235,0.06)]">
                <button onClick={() => setLogoLightbox(true)} aria-label="Lihat logo Standupindo Cilegon" className="group mx-auto block">
                  <div className="relative mx-auto flex h-24 w-24 items-center justify-center overflow-hidden rounded-[26px] border border-blue-100 bg-white shadow-[0_12px_28px_rgba(29,94,219,0.12)] transition-transform duration-200 group-hover:scale-[1.02]">
                    <img src={settings.logo_url ?? '/assets/images/Logo%20Standupindo%20Cilegon%20Biru.png'} alt={`Logo ${settings.site_name}`} className="h-16 w-16 object-contain" />
                  </div>
                </button>
                <p className="mt-5 text-[11px] font-semibold uppercase tracking-[0.18em] text-blue-600">Community</p>
                <h1 className="mt-1 text-2xl font-black tracking-[-0.04em] text-slate-900 sm:text-3xl">{settings.site_name}</h1>
                <p className="mt-3 text-sm leading-6 text-slate-500 sm:text-base">{settings.short_description}</p>
                <button onClick={() => router.navigate('/more/gabung')} className="btn-primary mt-5 w-full">Gabung Komunitas</button>
              </div>

              <div className="mt-4 grid grid-cols-2 gap-3 sm:grid-cols-4">
                {ACTIVITIES.map((a) => {
                  const Icon = a.icon;
                  return (
                    <div key={a.label} className="rounded-[20px] border border-slate-200 bg-white/90 p-4 shadow-[0_8px_22px_rgba(15,23,42,0.03)]">
                      <div className="mx-auto flex h-11 w-11 items-center justify-center rounded-2xl bg-gradient-to-br from-blue-100 to-blue-50 text-blue-700 shadow-inner ring-1 ring-blue-100">
                        <Icon className="h-5 w-5" />
                      </div>
                      <span className="mt-2 block text-sm font-semibold text-slate-700">{a.label}</span>
                    </div>
                  );
                })}
              </div>
            </div>
          </div>
        </div>
      </div>
      <ImageLightbox src={settings.logo_url ?? '/assets/images/Logo%20Standupindo%20Cilegon%20Biru.png'} alt={`Logo ${settings.site_name}`} open={logoLightbox} onClose={() => setLogoLightbox(false)} closeAriaLabel="Tutup logo" />
    </div>
  );
}
