import { useEffect, useRef, useState, type ChangeEvent } from 'react';
import { CheckCircle2, Eye, EyeOff, FileText, Music2, Save, Sparkles, Trash2, Upload } from 'lucide-react';
import { AnnualRecapStory } from '@/pages/public/AnnualRecapStoryView';
import { DEFAULT_RECAP_CLOSING, loadAnnualRecapStats, type AnnualRecapRecord, type AnnualRecapStats } from '@/lib/annual-recap';
import { supabase } from '@/lib/supabase';

const AUDIO_CONTENT_TYPES: Record<string, string> = {
  mp3: 'audio/mpeg',
  m4a: 'audio/mp4',
  aac: 'audio/aac',
  ogg: 'audio/ogg',
  wav: 'audio/wav',
  webm: 'audio/webm',
};

export function AnnualRecapAdminPage({ onNotice, onBack }: { onNotice: (message: string) => void; onBack?: () => void }) {
  const currentYear = new Date().getFullYear();
  const [selectedYear, setSelectedYear] = useState(currentYear);
  const [yearInput, setYearInput] = useState(String(currentYear));
  const [records, setRecords] = useState<AnnualRecapRecord[]>([]);
  const [record, setRecord] = useState<AnnualRecapRecord | null>(null);
  const [closingNarrative, setClosingNarrative] = useState(DEFAULT_RECAP_CLOSING);
  const [musicUrl, setMusicUrl] = useState('');
  const [stats, setStats] = useState<AnnualRecapStats | null>(null);
  const [loading, setLoading] = useState(true);
  const [recordsLoading, setRecordsLoading] = useState(true);
  const [loadError, setLoadError] = useState(false);
  const [statsError, setStatsError] = useState(false);
  const [saving, setSaving] = useState(false);
  const [publishing, setPublishing] = useState(false);
  const [previewOpen, setPreviewOpen] = useState(false);
  const [musicUploading, setMusicUploading] = useState(false);
  const musicInputRef = useRef<HTMLInputElement>(null);

  const validYearInput = /^\d{4}$/.test(yearInput)
    && Number(yearInput) >= 1900
    && Number(yearInput) <= currentYear;

  useEffect(() => {
    let active = true;

    void (async () => {
      const { data, error } = await supabase.from('annual_recaps').select('*').order('year', { ascending: false });
      if (!active) return;
      if (error) {
        onNotice('Daftar Annual Recap gagal dimuat. Pastikan database Annual Recap sudah disiapkan.');
      } else {
        setRecords((data as AnnualRecapRecord[]) ?? []);
      }
      setRecordsLoading(false);
    })();

    return () => { active = false; };
  }, [onNotice]);

  useEffect(() => {
    let active = true;

    (async () => {
      setLoading(true);
      setLoadError(false);
      setStatsError(false);
      setRecord(null);
      setStats(null);
      setMusicUrl('');

      const { data, error } = await supabase
        .from('annual_recaps')
        .select('*')
        .eq('year', selectedYear)
        .maybeSingle();

      if (!active) return;
      if (error) {
        setLoadError(true);
        setLoading(false);
        return;
      }
      const nextRecord = (data as AnnualRecapRecord | null) ?? null;
      setRecord(nextRecord);
      setClosingNarrative(nextRecord?.closing_narrative?.trim() || DEFAULT_RECAP_CLOSING);
      setMusicUrl(nextRecord?.music_url ?? '');

      try {
        const nextStats = await loadAnnualRecapStats(selectedYear);
        if (active) setStats(nextStats);
      } catch {
        if (active) setStatsError(true);
      }
      setLoading(false);
    })();

    return () => {
      active = false;
    };
  }, [selectedYear]);

  function updateRecordList(nextRecord: AnnualRecapRecord) {
    setRecords((current) => [nextRecord, ...current.filter((item) => item.year !== nextRecord.year)]
      .sort((first, second) => second.year - first.year));
  }

  async function saveRecord(nextPublished?: boolean) {
    if (!validYearInput || saving || musicUploading) return;
    setSaving(true);

    const payload: { closing_narrative: string | null; music_url?: string | null; updated_at: string; published?: boolean } = {
      closing_narrative: closingNarrative.trim() || null,
      updated_at: new Date().toISOString(),
    };
    if ((record && 'music_url' in record) || musicUrl.trim()) payload.music_url = musicUrl.trim() || null;
    if (nextPublished !== undefined) payload.published = nextPublished;

    if (record?.id) {
      const { data, error } = await supabase.from('annual_recaps').update(payload).eq('id', record.id).select('*').single();
      setSaving(false);
      if (error) {
        onNotice('Gagal menyimpan Annual Recap.');
        return;
      }
      const savedRecord = data as AnnualRecapRecord;
      setRecord(savedRecord);
      updateRecordList(savedRecord);
      onNotice(nextPublished ? 'Annual Recap berhasil dipublikasikan.' : 'Perubahan Annual Recap berhasil disimpan.');
      return;
    }

    const { data, error } = await supabase.from('annual_recaps').insert({
      year: selectedYear,
      published: nextPublished ?? false,
      closing_narrative: payload.closing_narrative,
      music_url: payload.music_url,
    }).select('*').single();
    setSaving(false);
    if (error) {
      onNotice('Gagal menambahkan Annual Recap.');
      return;
    }

    const createdRecord = data as AnnualRecapRecord;
    setRecord(createdRecord);
    updateRecordList(createdRecord);
    onNotice(nextPublished ? 'Annual Recap berhasil dibuat dan dipublikasikan.' : 'Draft Annual Recap berhasil dibuat.');
  }

  async function handleMusicUpload(event: ChangeEvent<HTMLInputElement>) {
    const file = event.target.files?.[0];
    event.target.value = '';
    if (!file) return;

    const extension = file.name.split('.').pop()?.toLowerCase() ?? '';
    const contentType = AUDIO_CONTENT_TYPES[extension];
    if (!contentType) {
      onNotice('Format musik harus MP3, M4A, AAC, OGG, WAV, atau WebM.');
      return;
    }
    if (file.size > 25 * 1024 * 1024) {
      onNotice('Ukuran musik maksimal 25 MB.');
      return;
    }

    setMusicUploading(true);
    try {
      const path = `${selectedYear}/${crypto.randomUUID()}.${extension}`;
      const { error } = await supabase.storage.from('annual-recap-audio').upload(path, file, {
        cacheControl: '3600',
        upsert: false,
        contentType,
      });
      if (error) throw error;
      setMusicUrl(supabase.storage.from('annual-recap-audio').getPublicUrl(path).data.publicUrl);
      onNotice('Musik berhasil diunggah. Simpan perubahan untuk menerapkannya.');
    } catch {
      onNotice('Musik gagal diunggah. Pastikan bucket audio Annual Recap sudah disiapkan.');
    } finally {
      setMusicUploading(false);
    }
  }

  async function handlePublish() {
    if (statsError) {
      onNotice('Data Annual Recap belum dapat diverifikasi. Coba lagi sebelum publish.');
      return;
    }
    setPublishing(true);
    await saveRecord(true);
    setPublishing(false);
  }

  async function handleUnpublish() {
    setPublishing(true);
    if (!record?.id) {
      setPublishing(false);
      onNotice('Recap belum dibuat untuk tahun ini.');
      return;
    }

    const { error } = await supabase.from('annual_recaps').update({ published: false, updated_at: new Date().toISOString() }).eq('id', record.id);
    setPublishing(false);
    if (error) {
      onNotice('Gagal membatalkan publikasi Annual Recap.');
      return;
    }

    const updatedRecord = { ...record, published: false, updated_at: new Date().toISOString() };
    setRecord(updatedRecord);
    updateRecordList(updatedRecord);
    onNotice('Publikasi Annual Recap dibatalkan.');
  }

  function openSelectedYear() {
    if (!validYearInput) return;
    setSelectedYear(Number(yearInput));
  }

  if (previewOpen && stats) {
    return (
      <div className="fixed inset-0 z-[100] bg-slate-950">
        <AnnualRecapStory
          year={selectedYear}
          stats={stats}
          closingNarrative={closingNarrative}
          musicUrl={musicUrl || null}
          onClose={() => setPreviewOpen(false)}
        />
      </div>
    );
  }

  return (
    <div className="space-y-5">
      <div className="flex items-center justify-between gap-3">
        <div>
          <p className="text-[10px] font-black uppercase tracking-[0.18em] text-blue-600">Admin Penuh</p>
          <h1 className="mt-1 text-2xl font-extrabold text-slate-900">Annual Recap</h1>
        </div>
        {onBack && (
          <button type="button" onClick={onBack} className="btn-secondary">Kembali</button>
        )}
      </div>

      <section className="space-y-4 border-y border-slate-200 py-5">
        <div className="grid gap-4 lg:grid-cols-[minmax(0,1fr)_minmax(0,1fr)]">
          <div className="space-y-2">
            <label htmlFor="annual-recap-year" className="text-sm font-semibold text-slate-700">Tahun recap</label>
            <div className="flex gap-2">
              <input id="annual-recap-year" type="number" inputMode="numeric" min="1900" max={currentYear} value={yearInput} onChange={(event) => setYearInput(event.target.value)} className="input-field max-w-36" />
              <button type="button" onClick={openSelectedYear} disabled={!validYearInput || loading} className="btn-secondary">Buka tahun</button>
            </div>
          </div>

          <label className="space-y-2 text-sm font-semibold text-slate-700">
            <span>Recap tersimpan</span>
            <select value={selectedYear} onChange={(event) => { const year = Number(event.target.value); setSelectedYear(year); setYearInput(String(year)); }} className="input-field">
              {[...new Set([currentYear, selectedYear, ...records.map((item) => item.year)])]
                .sort((first, second) => second - first)
                .map((year) => <option key={year} value={year}>{year}{records.some((item) => item.year === year) ? ` · ${records.find((item) => item.year === year)?.published ? 'Published' : 'Draft'}` : ' · Belum dibuat'}</option>)}
            </select>
          </label>
        </div>

        <div className="flex flex-wrap gap-2 border-t border-slate-200 pt-4">
          <button type="button" onClick={() => void saveRecord()} disabled={saving || publishing || musicUploading || loading || !validYearInput} className="btn-secondary">
            <Save className="h-4 w-4" /> {saving ? 'Menyimpan...' : record?.published ? 'Simpan perubahan' : 'Simpan draft'}
          </button>
          <button type="button" onClick={() => void handlePublish()} disabled={saving || publishing || musicUploading || loading || statsError || !validYearInput} className="btn-primary">
            <CheckCircle2 className="h-4 w-4" /> {publishing ? 'Memproses...' : 'Publish'}
          </button>
          <button type="button" onClick={() => void handleUnpublish()} disabled={saving || publishing || loading || !record?.published} className="btn-secondary">
            <EyeOff className="h-4 w-4" /> Unpublish
          </button>
          <button type="button" onClick={() => setPreviewOpen(true)} disabled={loading || statsError || !stats} className="btn-secondary">
            <Eye className="h-4 w-4" /> Preview
          </button>
        </div>
        {(loadError || statsError) && <p role="alert" className="text-sm text-red-700">{loadError ? 'Data database Annual Recap gagal dimuat.' : 'Sumber statistik gagal dibaca; preview dan publish dinonaktifkan.'}</p>}
      </section>

      <section className="space-y-3 border-b border-slate-200 pb-5" aria-label="Musik Annual Recap">
        <div className="flex items-center gap-2 text-slate-700"><Music2 className="h-4 w-4 text-blue-600" /><h2 className="text-xs font-black uppercase tracking-[0.18em]">Musik Story</h2></div>
        <p className="text-xs text-slate-500">MP3, M4A, AAC, OGG, WAV, atau WebM · Maks. 25 MB · musik berhenti setelah Story selesai.</p>
        <input ref={musicInputRef} type="file" accept=".mp3,.m4a,.aac,.ogg,.wav,.webm,audio/mpeg,audio/mp4,audio/aac,audio/ogg,audio/wav,audio/webm" onChange={(event) => void handleMusicUpload(event)} className="hidden" />
        <div className="flex flex-wrap items-center gap-2">
          <button type="button" onClick={() => musicInputRef.current?.click()} disabled={loading || musicUploading} className="btn-secondary"><Upload className="h-4 w-4" />{musicUploading ? 'Mengunggah musik...' : musicUrl ? 'Ganti musik' : 'Upload musik'}</button>
          {musicUrl && <button type="button" onClick={() => { setMusicUrl(''); onNotice('Musik dihapus dari perubahan. Simpan untuk menerapkan.'); }} disabled={musicUploading} className="btn-secondary"><Trash2 className="h-4 w-4" />Hapus musik</button>}
        </div>
        {musicUrl && <audio controls preload="metadata" src={musicUrl} className="h-10 w-full max-w-md" />}
      </section>

      <div className="grid gap-5 lg:grid-cols-[1.2fr_0.8fr]">
        <div className="rounded-3xl border border-slate-200 bg-white p-4 shadow-sm sm:p-6">
          <div className="mb-3 flex items-center gap-2 text-blue-700">
            <Sparkles className="h-4 w-4" />
            <span className="text-xs font-black uppercase tracking-[0.18em]">Narasi Penutup</span>
          </div>
          <textarea value={closingNarrative} onChange={(event) => setClosingNarrative(event.target.value)} disabled={loading || loadError} className="input-field min-h-[160px]" placeholder="Tulis narasi penutup jika ingin mengganti default." />
          <p className="mt-2 text-xs text-slate-500">Kosongkan untuk menggunakan default narasi standar.</p>
        </div>

        <div className="rounded-3xl border border-slate-200 bg-white p-4 shadow-sm sm:p-6">
          <div className="mb-4 flex items-center gap-2 text-slate-700">
            <FileText className="h-4 w-4 text-blue-600" />
            <span className="text-xs font-black uppercase tracking-[0.18em]">Status</span>
          </div>

          <div className="space-y-3 text-sm text-slate-600">
            <div className="flex items-center justify-between rounded-2xl bg-slate-50 px-3 py-2">
              <span>Tahun</span>
              <strong className="text-slate-900">{selectedYear}</strong>
            </div>
            <div className="flex items-center justify-between rounded-2xl bg-slate-50 px-3 py-2">
              <span>Publikasi</span>
              <strong className={record?.published ? 'text-emerald-700' : 'text-slate-500'}>{record?.published ? 'Published' : 'Draft'}</strong>
            </div>
            <div className="flex items-center justify-between rounded-2xl bg-slate-50 px-3 py-2">
              <span>Penampilan terverifikasi</span>
              <strong className="text-slate-900">{stats?.appearanceCount.toLocaleString('id-ID') ?? '—'}</strong>
            </div>
            <div className="rounded-2xl border border-dashed border-slate-200 bg-slate-50 px-3 py-4 text-xs leading-5 text-slate-500">
              Hanya Admin Penuh dapat mengelola recap. Simpan perubahan mempertahankan status publikasi; publish dan unpublish dilakukan lewat aksi terpisah.
            </div>
          </div>
        </div>
      </div>

      <section className="space-y-3" aria-label="Semua Annual Recap">
        <div className="flex items-center justify-between">
          <h2 className="text-sm font-bold text-slate-800">Semua tahun</h2>
          {recordsLoading && <span className="text-xs text-slate-500">Memuat...</span>}
        </div>
        {records.length > 0 ? (
          <div className="divide-y divide-slate-200 border-y border-slate-200">
            {records.map((item) => (
              <button key={item.id ?? item.year} type="button" onClick={() => { setSelectedYear(item.year); setYearInput(String(item.year)); }} className={`flex w-full items-center justify-between gap-3 py-3 text-left ${selectedYear === item.year ? 'text-blue-800' : 'text-slate-700'}`}>
                <span className="font-semibold">{item.year}</span>
                <span className={`text-xs font-semibold ${item.published ? 'text-emerald-700' : 'text-slate-500'}`}>{item.published ? 'Published' : 'Draft'}</span>
              </button>
            ))}
          </div>
        ) : !recordsLoading && !loadError ? (
          <p className="text-sm text-slate-500">Belum ada Annual Recap tersimpan.</p>
        ) : null}
      </section>
    </div>
  );
}
