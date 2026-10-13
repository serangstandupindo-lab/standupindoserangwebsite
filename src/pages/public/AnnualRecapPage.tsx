import { useEffect, useState } from 'react';
import type { Router } from '@/lib/router';
import { loadAnnualRecapStats, type AnnualRecapRecord, type AnnualRecapStats } from '@/lib/annual-recap';
import { supabase } from '@/lib/supabase';
import { EmptyState } from '@/components/ui/EmptyState';
import { AnnualRecapStory } from '@/pages/public/AnnualRecapStoryView';

export function AnnualRecapPage({ router, year }: { router: Router; year: string }) {
  const [record, setRecord] = useState<AnnualRecapRecord | null>(null);
  const [stats, setStats] = useState<AnnualRecapStats | null>(null);
  const [loading, setLoading] = useState(true);
  const [loadError, setLoadError] = useState(false);
  const yearNumber = Number(year);
  const validYear = /^\d{4}$/.test(year) && Number.isInteger(yearNumber) && yearNumber >= 1900;

  useEffect(() => {
    let active = true;
    setLoading(true);
    setRecord(null);
    setStats(null);
    setLoadError(false);

    if (!validYear) {
      setLoading(false);
      return () => { active = false; };
    }

    void (async () => {
      const { data, error } = await supabase
        .from('annual_recaps')
        .select('id, year, published, closing_narrative')
        .eq('year', yearNumber)
        .eq('published', true)
        .maybeSingle();

      if (!active) return;
      if (error) {
        setLoadError(true);
        setLoading(false);
        return;
      }

      const recap = (data as AnnualRecapRecord | null) ?? null;
      setRecord(recap);
      if (!recap) {
        setLoading(false);
        return;
      }

      try {
        const nextStats = await loadAnnualRecapStats(yearNumber);
        if (active) setStats(nextStats);
      } catch {
        if (active) setLoadError(true);
      }
      if (active) setLoading(false);
    })();

    return () => { active = false; };
  }, [validYear, yearNumber]);

  if (loading) {
    return <div className="flex min-h-screen items-center justify-center bg-slate-950 text-sm text-slate-300">Memuat Annual Recap...</div>;
  }

  if (loadError || !record || !stats) {
    return (
      <div className="min-h-screen bg-slate-950 px-4 py-10 text-white">
        <div className="mx-auto max-w-md pt-20">
          <EmptyState
            title={loadError ? 'Annual Recap gagal dimuat' : 'Recap tidak tersedia'}
            description={loadError ? 'Periksa koneksi lalu coba kembali.' : `Annual Recap ${year} belum dipublikasikan atau belum dibuat.`}
            noSmokeArea
          />
          <button type="button" onClick={() => router.navigate('/')} className="mx-auto mt-5 block text-sm font-semibold text-cyan-200">Kembali ke beranda</button>
        </div>
      </div>
    );
  }

  return (
    <AnnualRecapStory
      year={record.year}
      stats={stats}
      closingNarrative={record.closing_narrative}
      onClose={() => router.navigate('/')}
    />
  );
}