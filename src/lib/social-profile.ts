export type SocialPlatform = 'instagram' | 'tiktok' | 'youtube';

const PROFILE_BASES: Record<SocialPlatform, string> = {
  instagram: 'https://www.instagram.com/',
  tiktok: 'https://www.tiktok.com/@',
  youtube: 'https://www.youtube.com/@',
};

const PLATFORM_HOSTS: Record<SocialPlatform, string[]> = {
  instagram: ['instagram.com', 'www.instagram.com'],
  tiktok: ['tiktok.com', 'www.tiktok.com'],
  youtube: ['youtube.com', 'www.youtube.com', 'm.youtube.com'],
};

export function getSocialProfileUrl(value: string | null | undefined, platform: SocialPlatform): string | null {
  const input = value?.trim();
  if (!input) return null;

  const hasScheme = /^https?:\/\//i.test(input);
  const looksLikeUrl = hasScheme || PLATFORM_HOSTS[platform].some((host) => input.toLowerCase().startsWith(`${host}/`) || input.toLowerCase() === host);
  if (looksLikeUrl) {
    try {
      const url = new URL(hasScheme ? input : `https://${input}`);
      if (url.protocol !== 'https:' || !PLATFORM_HOSTS[platform].includes(url.hostname.toLowerCase())) return null;
      return url.toString();
    } catch {
      return null;
    }
  }

  const handle = input.replace(/^@/, '');
  if (!/^[a-zA-Z0-9._-]+$/.test(handle)) return null;
  return `${PROFILE_BASES[platform]}${encodeURIComponent(handle)}`;
}

export function getSocialProfileHandle(value: string | null | undefined, platform: SocialPlatform): string | null {
  const url = getSocialProfileUrl(value, platform);
  if (!url) return null;
  const segments = new URL(url).pathname.split('/').filter(Boolean);
  const lastSegment = segments[segments.length - 1];
  if (!lastSegment || ['channel', 'c', 'user'].includes(lastSegment.toLowerCase())) return null;
  const handle = lastSegment.replace(/^@/, '');
  return /^[a-zA-Z0-9._-]+$/.test(handle) ? `@${handle}` : null;
}
