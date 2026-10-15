import { Instagram } from 'lucide-react';
import { useSiteSettings } from '@/lib/useSiteSettings';
import { getSocialProfileHandle, getSocialProfileUrl } from '@/lib/social-profile';

export function InstagramFollowLink() {
  const { settings } = useSiteSettings();
  const instagramUrl = getSocialProfileUrl(settings.instagram_url, 'instagram');
  if (!instagramUrl) return null;
  const username = getSocialProfileHandle(settings.instagram_url, 'instagram');

  return (
    <a
      href={instagramUrl}
      target="_blank"
      rel="noopener noreferrer"
      className="group inline-flex w-fit items-center gap-2 rounded-full border border-slate-200 bg-white px-3 py-2 text-xs font-bold text-slate-600 shadow-sm transition hover:border-pink-200 hover:bg-pink-50 hover:text-pink-700 focus:outline-none focus:ring-2 focus:ring-pink-200 focus:ring-offset-2"
      title={`Buka Instagram ${settings.site_name}`}
    >
      <Instagram className="h-4 w-4 text-pink-500 transition group-hover:text-pink-600" />
      <span>{username ? `@${username}` : settings.site_name}</span>
    </a>
  );
}
