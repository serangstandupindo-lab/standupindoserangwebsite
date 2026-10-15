import { useEffect, useState } from 'react';
import { ArrowUpRight, Sparkles } from 'lucide-react';
import type { Router } from '@/lib/router';
import type { Komika } from '@/lib/types';
import { supabase } from '@/lib/supabase';
import { PageHeader } from '@/components/PageHeader';
import { LoadingSkeleton } from '@/components/ui/LoadingSkeleton';
import { EmptyState } from '@/components/ui/EmptyState';
import { SocialIconButton } from '@/components/ui/SocialIconButton';
import { ImageLightbox } from '@/components/ui/ImageLightbox';
import { ShareButton } from '@/components/ui/ShareButton';
import { formatDate, getEventStatus, normalizeSpecialties, safeExternalUrl } from '@/lib/format';

interface OfficialStageHistoryEntry {
  id: string;
  role_category: 'lineup' | 'opener' | 'guest_star' | 'mc_host' | 'judge' | 'special_show' | 'other';
  role_title: string | null;
  event: { id: string; title: string; slug: string; date: string; status: 'upcoming' | 'completed' | 'cancelled'; published: boolean };
}

interface ExternalStageHistoryEntry {
  id: string;
  event_date: string;
  event_name: string;
  event_type: string | null;
  role: string;
  custom_role: string | null;
  organizer: string | null;
  city: string;
  external_url: string | null;
}

interface Props {
  router: Router;
  slug: string;
}

function setOgTags(title: string, description: string, image: string, url: string) {
  const set = (prop: string, val: string) => {
    let el = document.querySelector(`meta[property="${prop}"]`) as HTMLMetaElement | null;
    if (!el) { el = document.createElement('meta'); el.setAttribute('property', prop); document.head.appendChild(el); }
    el.setAttribute('content', val);
  };
  set('og:title', title);
  set('og:description', description);
  set('og:image', image);
  set('og:url', url);
}

export function KomikaDetailPage({ router, slug }: Props) {
  const [loading, setLoading] = useState(true);
  const [komika, setKomika] = useState<Komika | null>(null);
  const [loadError, setLoadError] = useState(false);
  const [lightbox, setLightbox] = useState(false);
  const [officialHistory, setOfficialHistory] = useState<OfficialStageHistoryEntry[]>([]);
  const [externalHistory, setExternalHistory] = useState<ExternalStageHistoryEntry[]>([]);
  const [journeyError, setJourneyError] = useState('');

  useEffect(() => {
    (async () => {
      try {
        const { data: slugData, error: slugError } = await supabase
          .from('komika')
          .select('id, stage_name, slug, photo, bio, karya_url, instagram_url, tiktok_url, youtube_url, specialties, status, published, created_at, updated_at')
          .eq('slug', slug);
        if (slugError) throw slugError;

        let k = (slugData as Komika[] | null)?.find((item) => item.slug === slug) ?? null;

        if (!k) {
          const { data: fallbackData, error: fallbackError } = await supabase
            .from('komika')
            .select('id, stage_name, slug, photo, bio, karya_url, instagram_url, tiktok_url, youtube_url, specialties, status, published, created_at, updated_at')
            .limit(200);
          if (fallbackError) throw fallbackError;

          const rows = (fallbackData as Komika[] | null) ?? [];
          k = rows.find((item) => item.slug === slug && item.published && item.status === 'active') ?? null;
        }

        if (!k || k.published !== true || k.status !== 'active') {
          setKomika(null);
          setLoading(false);
          return;
        }

        setKomika(k);

        const [officialResult, externalResult] = await Promise.all([
          supabase.from('event_lineups')
            .select('id, role_category, role_title, event:events!inner(id, title, slug, date, status, published)')
            .eq('komika_id', k.id)
            .eq('events.published', true),
          supabase.from('member_stage_experiences')
            .select('id, event_date, event_name, event_type, role, custom_role, organizer, city, external_url')
            .eq('komika_id', k.id)
            .order('event_date', { ascending: false })
            .order('created_at', { ascending: false }),
        ]);
        if (officialResult.error || externalResult.error) {
          console.error('Failed to load public stage journey', officialResult.error ?? externalResult.error);
          setJourneyError('Perjalanan panggung belum dapat dimuat. Coba segarkan halaman.');
        } else {
          const completed = ((officialResult.data ?? []) as unknown as OfficialStageHistoryEntry[])
            .filter((entry) => entry.event.published && getEventStatus(entry.event.status, entry.event.date) === 'completed')
            .sort((first, second) => second.event.date.localeCompare(first.event.date));
          setOfficialHistory(completed);
          setExternalHistory((externalResult.data ?? []) as ExternalStageHistoryEntry[]);
          setJourneyError('');
        }

        const pageUrl = `${window.location.origin}/komika/${k.slug}`;
        setOgTags(
          `${k.stage_name} — Standupindo Serang`,
          `Kenali ${k.stage_name}, komika dari Standupindo Serang.`,
          k.photo ?? `${window.location.origin}/assets/images/pwa-public.png`,
          pageUrl,
        );
      } catch (error) {
        console.error('KomikaDetailPage query crashed', error);
        setLoadError(true);
        setKomika(null);
      } finally {
        setLoading(false);
      }
    })();
  }, [slug]);

  if (loading) {
    return (
      <div className="animate-fade-in">
        <PageHeader router={router} />
        <div className="container-app py-8"><LoadingSkeleton count={1} /></div>
      </div>
    );
  }

  if (!komika) {
    return (
      <div className="animate-fade-in">
        <PageHeader router={router} title={loadError ? 'Profil Komika gagal dimuat' : 'Komika tidak ditemukan'} />
        <div className="container-app py-8">
          <EmptyState title={loadError ? 'Profil Komika belum dapat dimuat. Coba segarkan halaman.' : 'Komika tidak ditemukan'} />
        </div>
      </div>
    );
  }

  const pageUrl = `${window.location.origin}/komika/${komika.slug}`;
  const karyaUrl = safeExternalUrl(komika.karya_url);
  const specialties = normalizeSpecialties(komika.specialties);
  const officialRoleLabels: Record<OfficialStageHistoryEntry['role_category'], string> = {
    lineup: 'Lineup / Penampil',
    opener: 'Opener',
    guest_star: 'Guest Star',
    mc_host: 'MC / Host',
    judge: 'Juri',
    special_show: 'Special Show',
    other: 'Lainnya',
  };

  return (
    <div className="animate-fade-in">
      <PageHeader router={router} title={komika.stage_name} />

      <div className="container-app py-6 sm:py-8">
        <div data-scroll-reveal className="scroll-reveal rounded-[28px] border border-slate-200 bg-white p-4 shadow-[0_14px_32px_rgba(11,60,93,0.05)] sm:p-6">
          <div className="grid gap-5 lg:grid-cols-[240px_minmax(0,1fr)] lg:gap-7">
            <div className="max-h-[16rem] overflow-hidden rounded-[22px] bg-slate-100 ring-1 ring-slate-200 sm:max-h-[20rem] lg:max-h-none">
              {komika.photo ? (
                <button onClick={() => setLightbox(true)} aria-label={`Lihat foto ${komika.stage_name}`} className="block h-full w-full">
                  <img src={komika.photo} alt={komika.stage_name} className="aspect-[4/3] max-h-[16rem] w-full object-contain bg-slate-100 transition-transform duration-500 hover:scale-105 sm:aspect-[4/4.5] sm:max-h-[20rem] lg:max-h-none" />
                </button>
              ) : (
                <div className="flex aspect-[4/3] w-full items-center justify-center bg-gradient-to-br from-blue-100 to-blue-50 text-5xl font-extrabold text-blue-600 sm:aspect-[4/4.5]">
                  {komika.stage_name.charAt(0)}
                </div>
              )}
            </div>

            <div className="space-y-4">
              <div className="flex items-start justify-between gap-3">
                <div>
                  <p className="text-xs font-bold uppercase tracking-[0.14em] text-blue-700">Komika</p>
                  <h1 className="mt-2 text-2xl font-extrabold tracking-[-0.04em] text-slate-900 sm:text-3xl">{komika.stage_name}</h1>
                </div>
                <ShareButton
                  title={`${komika.stage_name} — Standupindo Serang`}
                  text={`Kenali ${komika.stage_name}, komika dari Standupindo Serang.`}
                  url={pageUrl}
                  image={komika.photo}
                  className="!rounded-full"
                />
              </div>

              <div className="flex flex-wrap items-center gap-3">
                <SocialIconButton instagram={komika.instagram_url} tiktok={komika.tiktok_url} youtube={komika.youtube_url} />
              </div>

              {specialties.length > 0 && (
                <div className="flex flex-wrap gap-2">
                  {specialties.map((s) => <span key={s} className="chip">{s}</span>)}
                </div>
              )}

              {komika.bio && (
                <div className="rounded-2xl border border-slate-200 bg-slate-50 p-4">
                  <h2 className="text-base font-bold text-slate-900 sm:text-lg">Tentang</h2>
                  <p className="mt-2 text-sm leading-relaxed text-slate-600 whitespace-pre-line sm:text-base">{komika.bio}</p>
                </div>
              )}

              {karyaUrl && (
                <a
                  href={karyaUrl}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="group flex items-center justify-between gap-4 rounded-2xl border border-blue-200 bg-gradient-to-r from-blue-50 via-white to-indigo-50 p-3.5 shadow-[0_8px_20px_rgba(215,25,32,0.08)] transition hover:-translate-y-0.5 hover:border-blue-300 hover:shadow-[0_12px_24px_rgba(215,25,32,0.14)] sm:p-4"
                >
                  <span className="flex min-w-0 items-center gap-3">
                    <span className="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl bg-blue-600 text-white shadow-[0_6px_14px_rgba(215,25,32,0.25)]">
                      <Sparkles className="h-5 w-5" />
                    </span>
                    <span className="min-w-0">
                      <span className="block text-[10px] font-extrabold uppercase tracking-[0.14em] text-blue-600">Karya Saya</span>
                      <span className="mt-0.5 block truncate text-sm font-extrabold text-slate-900 sm:text-base">Lihat Karyaku</span>
                    </span>
                  </span>
                  <ArrowUpRight className="h-5 w-5 shrink-0 text-blue-600 transition-transform group-hover:-translate-y-0.5 group-hover:translate-x-0.5" />
                </a>
              )}
            </div>
          </div>
        </div>

        {(journeyError || officialHistory.length > 0 || externalHistory.length > 0) && (
          <section data-scroll-reveal className="scroll-reveal mt-6 rounded-2xl border border-blue-200/80 bg-gradient-to-br from-blue-50/70 via-white to-slate-50 p-3.5 shadow-[0_10px_24px_rgba(181,18,27,0.06)] sm:p-4">
            <div className="flex items-start gap-3">
              <span className="mt-0.5 h-7 w-1 shrink-0 rounded-full bg-gradient-to-b from-blue-600 to-indigo-500" />
              <div className="min-w-0 flex-1">
                <p className="text-[10px] font-extrabold uppercase tracking-[0.16em] text-blue-700">Pengalaman Tampil</p>
                <h2 className="mt-0.5 text-base font-extrabold tracking-tight text-slate-900 sm:text-lg">Perjalanan Panggung</h2>
              </div>
            </div>
            {journeyError && <p role="alert" className="mt-3 rounded-xl border border-blue-200 bg-blue-50 px-3 py-2 text-sm font-semibold text-blue-900">{journeyError}</p>}
            <div className="mt-4 grid gap-3.5">
              {!journeyError && officialHistory.length > 0 && <div className="rounded-xl border border-blue-100 bg-white/90 p-3 shadow-sm sm:p-3.5">
                <h3 className="mb-2.5 flex items-center gap-2 text-[11px] font-extrabold uppercase tracking-[0.1em] text-blue-800">
                  <span className="h-2 w-2 rounded-full bg-blue-600" />
                  Standupindo Serang
                  <span className="ml-auto rounded-full bg-blue-50 px-2 py-0.5 text-[10px] font-bold text-blue-800">{officialHistory.length}</span>
                </h3>
                <ul className="divide-y divide-slate-100">
                  {officialHistory.map((entry) => <li key={entry.id}>
                    <button
                      type="button"
                      onClick={() => router.navigate(`/event/${encodeURIComponent(entry.event.slug)}`)}
                      aria-label={`Buka event selesai ${entry.event.title}`}
                      className="group grid w-full grid-cols-[5rem_minmax(0,1fr)_auto] items-center gap-2 rounded-lg px-2 py-2.5 text-left transition hover:bg-blue-50/70 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-inset focus-visible:ring-blue-500 sm:grid-cols-[6.5rem_minmax(0,1fr)_auto] sm:gap-3 sm:px-2.5"
                    >
                      <span className="text-[10px] font-semibold leading-4 text-slate-500 sm:text-xs">{formatDate(entry.event.date)}</span>
                      <span className="truncate text-xs font-extrabold text-slate-900 transition-colors group-hover:text-blue-800 sm:text-sm">{entry.event.title}</span>
                      <span className="inline-flex max-w-24 truncate rounded-full bg-blue-50 px-2 py-1 text-[9px] font-bold text-blue-800 ring-1 ring-blue-100 sm:max-w-32 sm:px-2.5 sm:text-[10px]">
                          {entry.role_category === 'other' && entry.role_title ? entry.role_title : officialRoleLabels[entry.role_category]}
                      </span>
                    </button>
                  </li>)}
                </ul>
              </div>}
              {!journeyError && externalHistory.length > 0 && <div className="rounded-xl border border-slate-200 bg-white/90 p-3 shadow-sm sm:p-3.5">
                <h3 className="mb-2.5 flex items-center gap-2 text-[11px] font-extrabold uppercase tracking-[0.1em] text-slate-700">
                  <span className="h-2 w-2 rounded-full bg-slate-500" />
                  Perjalanan Lainnya
                  <span className="ml-auto rounded-full bg-slate-100 px-2 py-0.5 text-[10px] font-bold text-slate-700">{externalHistory.length}</span>
                </h3>
                <ul className="divide-y divide-slate-100">
                  {externalHistory.map((entry) => {
                    const url = safeExternalUrl(entry.external_url);
                    return <li key={entry.id}>
                      <div className="grid grid-cols-[5rem_minmax(0,1fr)_auto] items-center gap-2 px-2 py-2.5 sm:grid-cols-[6.5rem_minmax(0,1fr)_auto] sm:gap-3 sm:px-2.5">
                      <p className="text-[10px] font-semibold leading-4 text-slate-500 sm:text-xs">{formatDate(entry.event_date)}</p>
                      <span className="min-w-0">
                        {url
                          ? <a href={url} target="_blank" rel="noopener noreferrer" className="block truncate text-xs font-extrabold text-slate-900 transition hover:text-blue-800 sm:text-sm">{entry.event_name}</a>
                          : <span className="block truncate text-xs font-extrabold text-slate-900 sm:text-sm">{entry.event_name}</span>}
                        {(entry.organizer || entry.city) && <span className="mt-0.5 block truncate text-[10px] leading-4 text-slate-500 sm:text-[11px]">{[entry.organizer, entry.city].filter(Boolean).join(' · ')}</span>}
                      </span>
                      <span className="inline-flex max-w-24 truncate rounded-full bg-slate-100 px-2 py-1 text-[9px] font-bold text-slate-700 sm:max-w-32 sm:px-2.5 sm:text-[10px]">{entry.role === 'Lainnya' ? entry.custom_role : entry.role}</span>
                      </div>
                    </li>;
                  })}
                </ul>
              </div>}
            </div>
          </section>
        )}
      </div>

      {komika.photo && (
        <ImageLightbox src={komika.photo} alt={komika.stage_name} open={lightbox} onClose={() => setLightbox(false)} />
      )}
    </div>
  );
}
