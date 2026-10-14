import { useEffect, useState } from 'react';
import type { SiteSettings } from './types';
import { supabase } from './supabase';

const FALLBACK_SETTINGS: SiteSettings = {
  id: 1,
  site_name: 'Standupindo Serang',
  site_short_name: 'STANDUPINDO SERANG',
  logo_url: '/assets/images/pwa-public.png',
  brand_primary: '#D71920',
  brand_hover: '#B5121B',
  brand_accent: '#FFC928',
  whatsapp_admin: '',
  whatsapp_admin_name: '',
  whatsapp_registration: '',
  whatsapp_registration_name: '',
  whatsapp_partnership: '',
  whatsapp_partnership_name: '',
  whatsapp_ticket: '',
  whatsapp_ticket_name: '',
  instagram_url: '',
  tiktok_url: '',
  youtube_url: '',
  address: 'Serang, Banten',
  short_description: 'Menjadi ruang berkumpulnya komika, penikmat komedi, dan insan kreatif untuk berbagi tawa, mengasah kemampuan, serta saling mendukung dalam berkarya. Bersama-sama membangun ekosistem stand-up comedy yang aktif, inklusif, dan terus berkembang di Serang.',
  affiliation_name: 'Standupindo',
  affiliation_website: 'https://standupindo.id/',
  affiliation_logo_url: '/assets/images/image.png',
};

export function useSiteSettings() {
  const [settings, setSettings] = useState<SiteSettings>(FALLBACK_SETTINGS);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    let active = true;
    (async () => {
      const { data } = await supabase.from('site_settings').select('*').eq('id', 1).maybeSingle();
      if (active && data) setSettings({ ...FALLBACK_SETTINGS, ...(data as Partial<SiteSettings>) });
      if (active) setLoading(false);
    })();
    return () => { active = false; };
  }, []);

  useEffect(() => {
    document.documentElement.style.setProperty('--brand-primary', settings.brand_primary);
    document.documentElement.style.setProperty('--brand-hover', settings.brand_hover);
    document.documentElement.style.setProperty('--brand-accent', settings.brand_accent);
  }, [settings.brand_primary, settings.brand_hover, settings.brand_accent]);

  return { settings, loading };
}
