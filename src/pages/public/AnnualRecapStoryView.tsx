import { useEffect, useRef, useState } from 'react';
import { ArrowLeft, ArrowRight, CalendarDays, ChevronLeft, ChevronRight, Menu, Mic2, Pause, Play, Sparkles, Star, Trophy, Users, X } from 'lucide-react';
import { DEFAULT_RECAP_CLOSING, type AnnualRecapStats } from '@/lib/annual-recap';
import { LOGO_URL } from '@/lib/types';

const SLIDE_DURATION = 6500;
const MONTHS = ['JAN', 'FEB', 'MAR', 'APR', 'MEI', 'JUN', 'JUL', 'AGU', 'SEP', 'OKT', 'NOV', 'DES'];
const SLIDE_LABELS = ['Opening / Pembuka', 'Angka Tahun Ini', 'Orang-orang yang Memeriahkan', 'Komunitas & Umum', 'Perjalanan Setahun', 'Momen Paling Ramai', 'Kilas Balik Open Mic', 'Kilas Balik Event', 'Penutup'];
const formatCount = (count: number) => count.toLocaleString('id-ID');

export function AnnualRecapStory({ year, stats, closingNarrative, onClose }: {
  year: number;
  stats: AnnualRecapStats;
  closingNarrative: string | null;
  onClose: () => void;
}) {
  const [index, setIndex] = useState(0);
  const [progress, setProgress] = useState(0);
  const [paused, setPaused] = useState(false);
  const [holdPaused, setHoldPaused] = useState(false);
  const [reducedMotion, setReducedMotion] = useState(false);
  const [menuOpen, setMenuOpen] = useState(false);
  const [selectedPhoto, setSelectedPhoto] = useState<string | null>(null);
  const holdTimerRef = useRef<number | null>(null);
  const progressRef = useRef(0);
  const isPaused = paused || holdPaused;
  const slides = ['opening', 'numbers', 'people', 'communities', 'yearline', 'spotlight', 'open-mics', 'events', 'closing'] as const;
  const activeSlide = slides[index];
  const busiestMonth = stats.monthlyActivity.reduce<{ month: string; count: number } | null>(
    (busiest, month) => month.count > (busiest?.count ?? 0) ? month : busiest,
    null,
  );
  const largestActivity = Math.max(...stats.monthlyActivity.map((month) => month.count), 0);
  const crowdImage = stats.spotlightEvent?.photo || stats.eventPhotos[0]?.url || null;
  const closingCopy = closingNarrative?.trim() || DEFAULT_RECAP_CLOSING;

  useEffect(() => {
    const mediaQuery = window.matchMedia('(prefers-reduced-motion: reduce)');
    const updatePreference = () => setReducedMotion(mediaQuery.matches);
    updatePreference();
    mediaQuery.addEventListener?.('change', updatePreference);
    return () => mediaQuery.removeEventListener?.('change', updatePreference);
  }, []);

  useEffect(() => {
    if (isPaused || reducedMotion) return;
    if (index === slides.length - 1) {
      progressRef.current = 100;
      setProgress(100);
      return;
    }
    const startedAt = Date.now() - (progressRef.current / 100) * SLIDE_DURATION;
    const timer = window.setInterval(() => {
      const nextProgress = Math.min(((Date.now() - startedAt) / SLIDE_DURATION) * 100, 100);
      progressRef.current = nextProgress;
      setProgress(nextProgress);
      if (nextProgress >= 100) {
        progressRef.current = 0;
        setProgress(0);
        setIndex(index + 1);
      }
    }, 50);
    return () => window.clearInterval(timer);
  }, [index, isPaused, reducedMotion, slides.length]);

  useEffect(() => () => {
    if (holdTimerRef.current !== null) window.clearTimeout(holdTimerRef.current);
  }, []);

  function goToSlide(nextIndex: number) {
    progressRef.current = 0;
    setProgress(0);
    setIndex(Math.max(0, Math.min(slides.length - 1, nextIndex)));
    setMenuOpen(false);
  }

  function startHold() {
    if (reducedMotion) return;
    if (holdTimerRef.current !== null) window.clearTimeout(holdTimerRef.current);
    holdTimerRef.current = window.setTimeout(() => setHoldPaused(true), 300);
  }

  function endHold() {
    if (holdTimerRef.current !== null) window.clearTimeout(holdTimerRef.current);
    holdTimerRef.current = null;
    setHoldPaused(false);
  }

  return (
    <div className="recap-stage min-h-dvh bg-[#040d1c] text-white md:grid md:place-items-center md:p-6">
      <div className="recap-device relative mx-auto flex h-[100dvh] w-full max-w-[430px] flex-col overflow-hidden bg-[#071a35] shadow-2xl md:h-[min(880px,calc(100dvh-48px))] md:w-auto md:aspect-[9/19.5] md:rounded-[38px] md:border md:border-white/30">
        <div className="recap-device-texture pointer-events-none absolute inset-0" aria-hidden="true" />
        {crowdImage && <div className="pointer-events-none absolute inset-x-0 bottom-0 h-36 opacity-30" aria-hidden="true"><img src={crowdImage} alt="" className="h-full w-full object-cover object-center" /><div className="absolute inset-0 bg-gradient-to-t from-[#030b19] via-[#071a35]/65 to-transparent" /></div>}

        <header className="relative z-30 flex h-14 shrink-0 items-center justify-between border-b border-white/10 bg-[#071a35]/90 px-4 backdrop-blur-sm">
          <div className="flex min-w-0 items-center gap-2.5">
            <span className="flex h-9 w-9 shrink-0 items-center justify-center overflow-hidden rounded-xl bg-white p-1"><img src={LOGO_URL} alt="Logo Standupindo Cilegon" className="h-full w-full object-contain" /></span>
            <span className="min-w-0 leading-tight"><span className="block text-[10px] font-black uppercase text-white">Standupindo</span><span className="block text-[10px] font-black uppercase text-cyan-300">Cilegon</span></span>
          </div>
          <button type="button" onClick={() => setMenuOpen((current) => !current)} aria-label={menuOpen ? 'Tutup menu recap' : 'Buka menu recap'} aria-expanded={menuOpen} className="flex h-10 w-10 items-center justify-center rounded-xl border border-white/20 bg-white/5 text-white transition hover:bg-white/10">{menuOpen ? <X className="h-5 w-5" /> : <Menu className="h-5 w-5" />}</button>
        </header>

        <div className="relative z-20 flex shrink-0 gap-1 px-3 pt-2.5" aria-label={`Slide ${index + 1} dari ${slides.length}`}>
          {slides.map((slide, slideIndex) => <div key={slide} className="h-1 flex-1 overflow-hidden rounded-full bg-white/20"><div className="h-full rounded-full bg-cyan-300" style={{ width: slideIndex < index ? '100%' : slideIndex === index ? `${reducedMotion ? 0 : progress}%` : '0%' }} /></div>)}
        </div>

        {menuOpen && <nav className="absolute inset-x-3 top-[4.5rem] z-50 rounded-2xl border border-white/15 bg-[#0a2042]/98 p-2 shadow-2xl backdrop-blur-xl" aria-label="Daftar slide recap">
          {SLIDE_LABELS.map((label, slideIndex) => <button key={label} type="button" onClick={() => goToSlide(slideIndex)} className={`flex w-full items-center gap-3 rounded-xl px-3 py-2.5 text-left text-xs font-semibold ${index === slideIndex ? 'bg-cyan-300 text-[#071a35]' : 'text-white hover:bg-white/10'}`}><span className="w-5 font-black">{String(slideIndex + 1).padStart(2, '0')}</span>{label}</button>)}
          <button type="button" onClick={onClose} className="mt-1 flex w-full items-center gap-3 border-t border-white/10 px-3 py-3 text-left text-xs font-bold text-cyan-200"><ArrowLeft className="h-4 w-4" /> Tutup recap</button>
        </nav>}

        <main className="relative z-10 flex min-h-0 flex-1 flex-col overflow-y-auto overscroll-contain px-5 pb-3 pt-4 sm:px-6" onPointerDown={startHold} onPointerUp={endHold} onPointerCancel={endHold} onPointerLeave={endHold}>
          <div key={activeSlide} className="recap-slide-enter flex min-h-full flex-col">
            {activeSlide === 'opening' && <section className="relative flex min-h-full flex-col justify-between overflow-hidden pb-2 pt-5">
              <div className="absolute right-1 top-[27%] rotate-[-13deg] text-cyan-300/80" aria-hidden="true"><Mic2 className="h-24 w-24 drop-shadow-[0_10px_18px_rgba(12,173,255,0.3)] sm:h-28 sm:w-28" strokeWidth={1.4} /><span className="absolute -left-7 top-2 h-20 w-px rotate-[-26deg] bg-cyan-300/50" /><span className="absolute -left-2 top-[-1.5rem] h-16 w-px rotate-[-26deg] bg-cyan-300/30" /></div>
              <div><p className="text-[11px] font-bold uppercase text-cyan-100">Satu tahun bersama Standupindo Cilegon</p><h1 className="mt-5 flex flex-col text-[4.5rem] font-black leading-[0.78] text-white sm:text-[5.5rem]"><span>RECAP</span><span className="mt-3 -rotate-2 text-[5.8rem] text-cyan-300 sm:text-[6.5rem]">{year}</span></h1><p className="mt-7 max-w-[18rem] text-sm leading-6 text-blue-100">Setahun penuh cerita, panggung, tawa, dan orang-orang yang ikut memeriahkan.</p><p className="mt-6 max-w-[15rem] -rotate-2 font-serif text-lg italic text-cyan-200">Yuk, lihat apa yang terjadi selama setahun...</p></div>
              <div className="flex items-end justify-between pb-2"><span className="text-[9px] font-bold uppercase text-blue-200/80">STANDUPINDO CILEGON</span><button type="button" onClick={() => goToSlide(1)} aria-label="Lanjut ke slide berikutnya" className="flex h-12 w-12 items-center justify-center rounded-full border border-cyan-200/60 bg-cyan-300 text-[#071a35] shadow-[0_0_28px_rgba(34,211,238,0.25)] transition hover:translate-x-1"><ArrowRight className="h-5 w-5" /></button></div>
            </section>}

            {activeSlide === 'numbers' && <section className="relative flex min-h-full flex-col pb-2">
              <p className="text-[3.5rem] font-black leading-none text-white">{year}</p><h1 className="mt-1 text-xl font-extrabold text-cyan-200">Ternyata ramai juga.</h1>
              <div className="mt-5 grid grid-cols-2 gap-3">{[
                { value: stats.openMicCount, label: 'OPEN MIC', Icon: Mic2 },
                { value: stats.eventCount, label: 'EVENT', Icon: CalendarDays },
                { value: stats.identifiedPerformerCount, label: 'KOMIKA TAMPIL', Icon: Users },
                { value: stats.appearanceCount, label: 'PENAMPILAN', Icon: Star },
              ].map(({ value, label, Icon }) => <div key={label} className="flex min-h-28 flex-col items-center justify-center rounded-2xl bg-white px-2 py-3 text-center text-[#0b1f44] shadow-[0_10px_24px_rgba(2,8,23,0.18)]"><Icon className="h-6 w-6 text-blue-600" strokeWidth={2.4} /><strong className="mt-1 text-3xl font-black leading-none">{formatCount(value)}</strong><span className="mt-1 text-[9px] font-extrabold uppercase">{label}</span></div>)}</div>
              {stats.appearanceCount > stats.identifiedPerformerCount && <p className="mt-3 text-center text-[9px] leading-4 text-blue-100">Komika tampil dihitung dari profil yang dapat diidentifikasi; total penampilan mencakup seluruh kehadiran terverifikasi.</p>}
              <div className="relative mt-auto flex h-24 items-end justify-center overflow-hidden pt-4">{crowdImage && <img src={crowdImage} alt="Suasana panggung komunitas" className="absolute inset-0 h-full w-full object-cover object-center opacity-45" />}<div className="absolute inset-0 bg-gradient-to-t from-[#030b19] via-[#071a35]/45 to-transparent" /><div className="relative flex items-end gap-1" aria-hidden="true">{Array.from({ length: 15 }, (_, personIndex) => <span key={personIndex} className="relative w-5 rounded-t-full bg-[#020918]" style={{ height: `${28 + ((personIndex * 17) % 35)}px` }}><span className="absolute -top-2 left-1 h-4 w-4 rounded-full bg-[#020918]" /></span>)}</div></div>
            </section>}

            {activeSlide === 'people' && <section className="relative flex min-h-full flex-col pb-2">
              <p className="text-[11px] font-black uppercase leading-4 text-cyan-200">MEREKA YANG NAIK KE PANGGUNG</p><div className="mt-2 flex items-end gap-2"><strong className="text-[5.3rem] font-black leading-[0.82] text-white">{formatCount(stats.identifiedPerformerCount)}</strong><span className="pb-1 text-xl font-extrabold text-cyan-300">komika</span></div><p className="mt-2 text-sm font-medium text-blue-100">yang benar-benar tampil sepanjang {year}.</p>
              <div className="mt-6 grid grid-cols-2 gap-3"><div className="rounded-2xl bg-white px-3 py-3 text-[#0b1f44] shadow-lg"><strong className="block text-3xl font-black">{formatCount(stats.firstTimePerformerCount)}</strong><p className="mt-1 text-[10px] leading-4">orang pertama kali tercatat tampil di Standupindo Cilegon tahun ini.</p></div><div className="rounded-2xl bg-white px-3 py-3 text-[#0b1f44] shadow-lg"><strong className="block text-3xl font-black">{formatCount(stats.newMemberCount)}</strong><p className="mt-1 text-[10px] leading-4">member baru bergabung.</p></div></div>
              <div className="mt-auto grid grid-cols-5 items-end gap-1.5 pt-5">{stats.topPerformers.slice(0, 5).map((performer, performerIndex) => <div key={performer.id} className={`relative overflow-hidden rounded-t-[45%] border border-white/20 bg-gradient-to-b ${['from-cyan-300 to-blue-700', 'from-sky-200 to-indigo-700', 'from-blue-300 to-cyan-800', 'from-cyan-200 to-blue-900', 'from-sky-300 to-blue-800'][performerIndex]} ${performerIndex % 2 ? 'h-20' : 'h-24'}`}>{performer.photo ? <img src={performer.photo} alt={performer.name} className="h-full w-full object-cover object-top" /> : <span className="flex h-full items-center justify-center text-xl font-black text-white">{performer.name.slice(0, 1).toUpperCase()}</span>}<span className="absolute inset-x-0 bottom-0 truncate bg-[#031127]/80 px-1 py-1 text-center text-[7px] font-bold text-white">{performer.name}</span></div>)}{stats.topPerformers.length === 0 && <div className="col-span-5 flex h-24 items-center justify-center text-xs text-blue-100">Foto komika belum tersedia.</div>}</div>
            </section>}

            {activeSlide === 'communities' && <section className="relative flex min-h-full flex-col pb-2">
              <p className="max-w-[17rem] text-xl font-black uppercase leading-tight text-cyan-200">KOMUNITAS YANG IKUT MERAMAIKAN</p><div className="mt-5 overflow-hidden rounded-2xl bg-white text-[#0b1f44] shadow-[0_16px_36px_rgba(0,0,0,0.22)]">{stats.topCommunities.slice(0, 3).map((community, communityIndex) => <div key={community.name} className={`flex min-h-[4.5rem] items-center gap-3 px-4 py-3 ${communityIndex ? 'border-t border-slate-200' : ''}`}><span className={`flex h-9 w-9 shrink-0 items-center justify-center rounded-full text-lg font-black ${['bg-amber-300 text-amber-900', 'bg-slate-200 text-slate-600', 'bg-orange-200 text-orange-800'][communityIndex]}`}><Trophy className="h-5 w-5" /></span><span className="min-w-0 flex-1 text-xs font-extrabold">{community.name}</span><strong className="shrink-0 text-right text-xs">{formatCount(community.count)}<span className="block text-[9px] font-medium text-slate-500">penampilan</span></strong></div>)}{stats.topCommunities.length === 0 && <p className="px-4 py-6 text-sm text-slate-500">Belum ada komunitas yang tercatat.</p>}<div className="flex items-start gap-3 border-t border-slate-200 px-4 py-4 text-[11px] leading-5 text-slate-700"><Users className="mt-0.5 h-5 w-5 shrink-0 text-blue-600" /><span>Dan tentu saja, ada juga yang datang sebagai komika independen.{stats.independentAppearanceCount > 0 ? ` ${formatCount(stats.independentAppearanceCount)} penampilan tercatat.` : ''}</span></div></div><div className="mt-auto flex h-20 items-end justify-around overflow-hidden pt-4" aria-hidden="true">{Array.from({ length: 8 }, (_, handIndex) => <span key={handIndex} className="w-7 rounded-t-[50%] bg-[#020918]" style={{ height: `${28 + ((handIndex * 11) % 25)}px` }} />)}</div>
            </section>}

            {activeSlide === 'yearline' && <section className="relative flex min-h-full flex-col pb-2">
              <p className="text-[1.8rem] font-black leading-none">PERJALANAN <span className="text-cyan-300">{year}</span></p><p className="mt-2 text-xs text-blue-100">Bulan demi bulan, panggung terus berjalan.</p><div className="mt-6 space-y-2.5">{MONTHS.map((monthLabel, monthIndex) => {
                const activity = stats.monthlyActivity[monthIndex]?.count ?? 0;
                const normalizedMonth = busiestMonth?.month.toLocaleLowerCase('id-ID').replace('.', '');
                const isBusiest = activity > 0 && [monthLabel.toLocaleLowerCase('id-ID'), `${monthLabel.toLocaleLowerCase('id-ID')}.`].includes(normalizedMonth ?? '');
                const width = largestActivity > 0 ? Math.max(activity ? 12 : 0, (activity / largestActivity) * 100) : 0;
                return <div key={monthLabel} className="relative grid grid-cols-[2.5rem_1fr_1.5rem] items-center gap-2"><span className={`text-[9px] font-bold ${isBusiest ? 'text-cyan-200' : 'text-blue-100'}`}>{monthLabel}</span><div className="h-2.5 overflow-hidden rounded-full bg-blue-950/90 ring-1 ring-white/10"><div className={`h-full rounded-full ${isBusiest ? 'bg-cyan-300 shadow-[0_0_14px_rgba(34,211,238,0.6)]' : 'bg-gradient-to-r from-blue-700 to-sky-400'}`} style={{ width: `${width}%` }} /></div><span className="text-right text-[9px] font-bold text-cyan-100">{activity || ''}</span>{isBusiest && <span className="absolute right-5 top-[-1.7rem] rounded-lg bg-cyan-300 px-2 py-1 text-[9px] font-black leading-tight text-[#071a35] shadow-lg">{busiestMonth?.month}<br />Bulan paling ramai.</span>}</div>;
              })}</div><p className="mt-auto pt-5 text-[10px] text-blue-200">Setiap bar mewakili jumlah Open Mic dan Event yang telah berlangsung.</p>
            </section>}

            {activeSlide === 'spotlight' && <section className="relative flex min-h-full flex-col pb-2">
              <h1 className="max-w-[17rem] text-2xl font-black uppercase leading-tight text-white">PALING RAMAI TAHUN INI</h1><div className="mt-4 grid gap-3">
                <article className="overflow-hidden rounded-2xl bg-white text-[#0b1f44] shadow-lg"><div className="relative h-24 bg-blue-900">{stats.topOpenMics[0]?.poster && <img src={stats.topOpenMics[0].poster} alt={`Artwork Open Mic ${stats.topOpenMics[0].title}`} className="h-full w-full object-cover" />}<span className="absolute left-3 top-3 rounded-full bg-blue-700 px-2.5 py-1 text-[8px] font-black text-white">OPEN MIC</span></div><div className="flex items-center justify-between gap-3 px-4 py-2.5"><span className="min-w-0"><strong className="block truncate text-sm font-black">{stats.topOpenMics[0]?.title ?? 'Open Mic'}</strong><span className="text-[8px] font-bold text-blue-700">KOMIKA TAMPIL</span></span><strong className="text-3xl font-black">{stats.topOpenMics[0] ? formatCount(stats.topOpenMics[0].appearanceCount) : '0'}</strong></div></article>
                <article className="overflow-hidden rounded-2xl bg-white text-[#0b1f44] shadow-lg"><div className="relative h-24 bg-slate-900">{(stats.spotlightEvent?.photo || stats.spotlightEvent?.poster) && <img src={stats.spotlightEvent.photo || stats.spotlightEvent.poster || ''} alt={stats.spotlightEvent.title} className="h-full w-full object-cover" />}<div className="absolute inset-0 bg-gradient-to-r from-[#06142c]/80 via-[#06142c]/20 to-transparent" /><span className="absolute left-3 top-3 rounded-full bg-amber-300 px-2.5 py-1 text-[8px] font-black text-[#0b1f44]">EVENT TERPADAT</span></div><div className="flex items-center justify-between gap-3 px-4 py-2.5"><span className="min-w-0"><strong className="block truncate text-sm font-black">{stats.spotlightEvent?.title ?? 'Event'}</strong><span className="text-[8px] font-bold text-blue-700">PENONTON · TIKET CHECK-IN</span></span><strong className="text-3xl font-black">{stats.spotlightEvent ? formatCount(stats.spotlightEvent.checkedIn) : '—'}</strong></div></article>
              </div><p className="mt-auto pt-3 text-[8px] leading-4 text-blue-200">Angka event menghitung tiket Lunas yang check-in, bukan seluruh pengunjung tanpa tiket.</p>
            </section>}

            {activeSlide === 'open-mics' && <section className="relative flex min-h-full flex-col rounded-2xl bg-slate-50 px-4 py-5 text-[#0b1f44]">
              <p className="text-2xl font-black">3 PANGGUNG</p><h1 className="text-[1.1rem] font-black uppercase leading-tight">YANG PALING RAMAI</h1><div className="mt-4 space-y-3">{stats.topOpenMics.map((openMic, openMicIndex) => <article key={openMic.id} className="flex min-h-[5.2rem] items-center gap-3 overflow-hidden rounded-xl border border-slate-200 bg-white shadow-sm"><div className="relative h-[5.2rem] w-[5.2rem] shrink-0 bg-blue-900">{openMic.poster && <img src={openMic.poster} alt={`Artwork ${openMic.title}`} className="h-full w-full object-cover" />}<span className="absolute left-1 top-1 rounded bg-[#0b1f44]/90 px-1 py-0.5 text-[8px] font-black text-white">0{openMicIndex + 1}</span></div><div className="min-w-0 flex-1 py-2"><h2 className="truncate text-xs font-black">{openMic.title}</h2><p className="mt-1 text-[9px] text-slate-500">komika tampil</p></div><strong className="shrink-0 pr-3 text-2xl font-black">{formatCount(openMic.appearanceCount)}</strong></article>)}{stats.topOpenMics.length === 0 && <p className="py-8 text-center text-sm text-slate-500">Belum ada penampilan terverifikasi.</p>}</div>
            </section>}

            {activeSlide === 'events' && <section className="relative flex min-h-full flex-col rounded-2xl bg-slate-50 p-3 text-[#0b1f44]">
              <p className="text-[1.25rem] font-black">DAN TENTU SAJA...</p><h1 className="text-[0.95rem] font-black uppercase leading-tight">ADA BANYAK PANGGUNG BESAR.</h1><div className="mt-3 grid grid-cols-2 gap-2">{stats.eventPosters.map((event) => <button key={event.id} type="button" onClick={() => setSelectedPhoto(event.poster)} aria-label={`Lihat poster ${event.title}`} className="overflow-hidden rounded-xl bg-white shadow-sm ring-1 ring-slate-200"><img src={event.poster} alt={event.title} className="aspect-[3/4] w-full object-cover" /></button>)}</div>{stats.eventPhotos.length > 0 ? <div className="mt-auto grid grid-cols-3 gap-2 pt-3">{stats.eventPhotos.slice(0, 3).map((photo) => <button key={photo.id} type="button" onClick={() => setSelectedPhoto(photo.url)} aria-label={`Lihat dokumentasi ${photo.eventTitle}`} className="relative overflow-hidden rounded-lg bg-[#0b1f44]"><img src={photo.url} alt={`${photo.eventTitle}, dokumentasi`} className="aspect-[4/3] w-full object-cover" /><span className="absolute bottom-1 right-1 flex h-6 w-6 items-center justify-center rounded-full bg-cyan-300 text-[#0b1f44]"><Play className="ml-0.5 h-3 w-3 fill-current" /></span></button>)}</div> : <p className="mt-auto pt-4 text-center text-[9px] font-semibold text-slate-500">Dokumentasi foto belum tersedia.</p>}
            </section>}

            {activeSlide === 'closing' && <section className="relative flex min-h-full flex-col items-center justify-center overflow-hidden pb-7 text-center">
              <div className="absolute inset-x-[-2rem] bottom-0 flex h-24 items-end justify-center gap-1 opacity-70" aria-hidden="true">{[34, 54, 38, 72, 46, 60, 84, 44, 66, 39, 74, 52, 32].map((height, buildingIndex) => <span key={buildingIndex} className="w-7 bg-[#020918]" style={{ height: `${height}px` }} />)}</div><Sparkles className="mb-4 h-6 w-6 text-cyan-300" /><p className="text-sm font-black uppercase tracking-wide text-white">TERIMA KASIH,</p><h1 className="mt-1 -rotate-2 text-[5.3rem] font-black leading-none text-cyan-300">{year}.</h1><p className="mt-5 max-w-[19rem] text-xs leading-5 text-blue-100">{closingCopy}</p><p className="mt-6 max-w-[17rem] rounded-full bg-cyan-300 px-5 py-3 text-[10px] font-black text-[#0b1f44] shadow-[0_8px_28px_rgba(34,211,238,0.2)]">SAMPAI KETEMU DI PANGGUNG BERIKUTNYA.</p><div className="relative mt-8 flex items-center gap-2 rounded-full bg-white/10 px-4 py-2"><img src={LOGO_URL} alt="" className="h-7 w-7 rounded-full bg-white object-contain p-0.5" /><span className="text-[9px] font-black uppercase text-white">STANDUPINDO CILEGON</span></div>
            </section>}
          </div>
        </main>

        <footer className="relative z-20 flex h-[4.25rem] shrink-0 items-center justify-between border-t border-white/10 bg-[#06152d]/95 px-4 pb-[env(safe-area-inset-bottom)] backdrop-blur-sm">
          <button type="button" onClick={() => goToSlide(index - 1)} disabled={index === 0} aria-label="Slide sebelumnya" className="flex h-10 w-10 items-center justify-center rounded-full text-blue-100 transition hover:bg-white/10 disabled:opacity-30"><ChevronLeft className="h-5 w-5" /></button>
          <div className="flex items-center gap-2"><button type="button" onClick={() => setPaused((current) => !current)} disabled={reducedMotion || index === slides.length - 1} aria-label={reducedMotion ? 'Putar otomatis nonaktif' : paused ? 'Lanjutkan recap otomatis' : 'Jeda recap otomatis'} className="flex h-9 w-9 items-center justify-center rounded-full bg-white/10 text-white disabled:opacity-40">{paused || reducedMotion || index === slides.length - 1 ? <Play className="h-4 w-4" /> : <Pause className="h-4 w-4" />}</button><span className="min-w-[3.2rem] text-center text-[9px] font-bold text-blue-100">{String(index + 1).padStart(2, '0')} / 09</span></div>
          <button type="button" onClick={() => goToSlide(index + 1)} disabled={index === slides.length - 1} aria-label="Slide berikutnya" className="flex h-10 w-10 items-center justify-center rounded-full bg-cyan-300 text-[#071a35] transition hover:translate-x-0.5 disabled:opacity-30"><ChevronRight className="h-5 w-5" /></button>
        </footer>

        {selectedPhoto && <div className="absolute inset-0 z-[60] flex items-center justify-center bg-[#020918]/95 p-5" role="dialog" aria-modal="true" aria-label="Pratinjau media Event" onClick={() => setSelectedPhoto(null)}><button type="button" onClick={() => setSelectedPhoto(null)} aria-label="Tutup pratinjau" className="absolute right-4 top-4 flex h-10 w-10 items-center justify-center rounded-full bg-white/10 text-white"><X className="h-5 w-5" /></button><img src={selectedPhoto} alt="Dokumentasi Annual Recap" className="max-h-full max-w-full rounded-xl object-contain" /></div>}
      </div>
    </div>
  );
}