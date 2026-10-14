REVOKE SELECT (full_name, whatsapp) ON TABLE public.komika FROM anon;
GRANT SELECT (photo_card) ON TABLE public.komika TO anon;

NOTIFY pgrst, 'reload schema';