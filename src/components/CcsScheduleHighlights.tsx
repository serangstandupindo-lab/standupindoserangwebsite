import { useEffect, useState } from 'react';
import { ArrowRight, CalendarDays, Clock3, MapPin } from 'lucide-react';
import { supabase } from '@/lib/supabase';
import { formatCcsDate, formatCcsTime, getCcsMapsUrl, getCcsOccurrenceDate, getCcsRecurrenceLabel, isUpcomingCcsSchedule } from '@/lib/ccs';
import type { CcsSchedule } from '@/lib/types';
import { SectionHeader } from '@/components/ui/SectionHeader';
import { ImageLightbox } from '@/components/ui/ImageLightbox';

export function CcsScheduleHighlights({ compact = false }: { compact?: boolean }) {
  const [schedules, setSchedules] = useState<CcsSchedule[]>([]);
  const [loaded, setLoaded] = useState(false);
  const [posterToView, setPosterToView] = useState<{ src: string; alt: string } | null>(null);

  useEffect(() => {
    let active = true;
    void (async () => {
      const { data, error } = await supabase
        .from('ccs_schedules')
        .select('id, title, event_date, start_time, venue, maps_url, poster_url, is_published, created_at, updated_at')
        .eq('is_published', true)
        .order('event_date', { ascending: true })
        .order('start_time', { ascending: true, nullsFirst: false })
        .limit(1);

      if (!active) return;
      if (error) {
        console.error('Jadwal CCS gagal dimuat.', error);
      } else {
        setSchedules(((data ?? []) as CcsSchedule[]).filter((schedule) => isUpcomingCcsSchedule(schedule)).slice(0, 3));
      }
      setLoaded(true);
    })();
    return () => {
      active = false;
    };
  }, []);

  if (!loaded || schedules.length === 0) return null;

  return (
    <section className="space-y-5">
      <div className="flex items-center justify-between gap-3 rounded-2xl border border-blue-100 bg-white p-3 shadow-sm sm:p-4">
        <div className="min-w-0 flex-1 border-l-4 border-l-blue-700 pl-3 sm:pl-4">
          <SectionHeader title="Jadwal CCS" subtitle="Serang Comedy Sharing berikutnya." />
        </div>
        <span className="shrink-0 rounded-full bg-blue-50 px-3 py-1 text-[10px] font-extrabold uppercase tracking-[0.12em] text-blue-700">CCS</span>
      </div>
      <div className={compact ? 'grid gap-3 sm:grid-cols-2' : 'grid gap-4 lg:grid-cols-3'}>
        {schedules.map((schedule) => {
          const mapsUrl = getCcsMapsUrl(schedule);
          const time = formatCcsTime(schedule.start_time);
          return (
            <article key={schedule.id} className="overflow-hidden rounded-2xl border border-blue-100 bg-white shadow-[0_10px_26px_rgba(15,23,42,0.06)]">
              {schedule.poster_url && (
                <div className="relative isolate flex aspect-[4/3] items-center justify-center overflow-hidden bg-gradient-to-br from-blue-50 via-slate-50 to-indigo-100 p-3 sm:p-4">
                  <div aria-hidden="true" className="absolute inset-0 -z-10 opacity-60" style={{ backgroundImage: 'radial-gradient(circle at 20% 20%, rgba(59,130,246,0.16), transparent 45%), radial-gradient(circle at 80% 80%, rgba(181,18,27,0.12), transparent 45%)' }} />
                  <button
                    type="button"
                    onClick={() => setPosterToView({ src: schedule.poster_url!, alt: `Poster ${schedule.title}` })}
                    aria-label={`Lihat poster ${schedule.title} ukuran penuh`}
                    className="group/poster relative flex h-full w-full items-center justify-center rounded-lg focus:outline-none focus-visible:ring-2 focus-visible:ring-blue-500 focus-visible:ring-offset-2"
                  >
                    <img src={schedule.poster_url} alt={`Poster ${schedule.title}`} loading="lazy" className="h-full w-full rounded-lg object-contain drop-shadow-[0_8px_14px_rgba(15,23,42,0.18)]" />
                  </button>
                </div>
              )}
              <div className="p-4 sm:p-5">
                <p className="text-[10px] font-extrabold uppercase tracking-[0.16em] text-blue-700">Serang Comedy Sharing</p>
                <h3 className="mt-1 text-base font-black leading-snug text-slate-950">{schedule.title}</h3>
                <p className="mt-2 inline-flex items-center rounded-full bg-blue-50 px-2.5 py-1 text-[10px] font-extrabold uppercase tracking-wide text-blue-700">{getCcsRecurrenceLabel(schedule)}</p>
                <div className="mt-3 flex flex-wrap gap-x-4 gap-y-2 text-xs font-semibold text-slate-600">
                  <span className="inline-flex items-center gap-1.5"><CalendarDays className="h-4 w-4 text-blue-600" />{formatCcsDate(getCcsOccurrenceDate(schedule))}</span>
                  {time && <span className="inline-flex items-center gap-1.5"><Clock3 className="h-4 w-4 text-blue-600" />{time}</span>}
                </div>
                {schedule.venue && (
                  mapsUrl ? (
                    <a href={mapsUrl} target="_blank" rel="noopener noreferrer" className="mt-3 inline-flex max-w-full items-start gap-2 text-sm font-bold text-slate-800 transition hover:text-blue-700">
                      <MapPin className="mt-0.5 h-4 w-4 shrink-0 text-blue-600" />
                      <span className="truncate">{schedule.venue}</span>
                      <ArrowRight className="mt-0.5 h-3.5 w-3.5 shrink-0" />
                    </a>
                  ) : (
                    <p className="mt-3 flex items-start gap-2 text-sm font-bold text-slate-800">
                      <MapPin className="mt-0.5 h-4 w-4 shrink-0 text-blue-600" />
                      <span>{schedule.venue}</span>
                    </p>
                  )
                )}
              </div>
            </article>
          );
        })}
      </div>
      {posterToView && (
        <ImageLightbox
          src={posterToView.src}
          alt={posterToView.alt}
          open
          onClose={() => setPosterToView(null)}
        />
      )}
    </section>
  );
}
