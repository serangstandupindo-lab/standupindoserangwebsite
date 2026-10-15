GRANT SELECT (karya_url)
  ON TABLE public.komika
  TO anon, authenticated;

NOTIFY pgrst, 'reload schema';
