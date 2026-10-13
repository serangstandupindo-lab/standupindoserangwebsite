ALTER TABLE public.annual_recaps
  ADD COLUMN IF NOT EXISTS music_url text;

INSERT INTO storage.buckets (id, name, public, allowed_mime_types, file_size_limit)
VALUES (
  'annual-recap-audio',
  'annual-recap-audio',
  true,
  ARRAY['audio/mpeg', 'audio/mp3', 'audio/mp4', 'audio/m4a', 'audio/aac', 'audio/ogg', 'audio/wav', 'audio/x-wav', 'audio/webm'],
  26214400
)
ON CONFLICT (id) DO UPDATE
SET public = EXCLUDED.public,
    allowed_mime_types = EXCLUDED.allowed_mime_types,
    file_size_limit = EXCLUDED.file_size_limit;

DROP POLICY IF EXISTS "annual_recap_audio_public_read" ON storage.objects;
CREATE POLICY "annual_recap_audio_public_read"
ON storage.objects FOR SELECT
TO anon, authenticated
USING (bucket_id = 'annual-recap-audio');

DROP POLICY IF EXISTS "annual_recap_audio_admin_insert" ON storage.objects;
CREATE POLICY "annual_recap_audio_admin_insert"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'annual-recap-audio' AND public.jwt_has_role('admin'));

DROP POLICY IF EXISTS "annual_recap_audio_admin_update" ON storage.objects;
CREATE POLICY "annual_recap_audio_admin_update"
ON storage.objects FOR UPDATE
TO authenticated
USING (bucket_id = 'annual-recap-audio' AND public.jwt_has_role('admin'))
WITH CHECK (bucket_id = 'annual-recap-audio' AND public.jwt_has_role('admin'));

DROP POLICY IF EXISTS "annual_recap_audio_admin_delete" ON storage.objects;
CREATE POLICY "annual_recap_audio_admin_delete"
ON storage.objects FOR DELETE
TO authenticated
USING (bucket_id = 'annual-recap-audio' AND public.jwt_has_role('admin'));

NOTIFY pgrst, 'reload schema';
