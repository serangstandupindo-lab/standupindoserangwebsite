DROP POLICY IF EXISTS "media_admin_insert" ON storage.objects;
DROP POLICY IF EXISTS "media_admin_update" ON storage.objects;
DROP POLICY IF EXISTS "media_admin_delete" ON storage.objects;
DROP POLICY IF EXISTS "serang_media_insert_scoped" ON storage.objects;
DROP POLICY IF EXISTS "serang_media_update_scoped" ON storage.objects;
DROP POLICY IF EXISTS "serang_media_delete_scoped" ON storage.objects;

CREATE POLICY "serang_media_insert_scoped"
ON storage.objects FOR INSERT TO authenticated
WITH CHECK (
  bucket_id = 'standupindo-media'
  AND (
    public.jwt_has_role('admin')
    OR (
      public.jwt_has_role('open_mic_admin')
      AND (storage.foldername(name))[1] IN ('open-mic', 'ccs-schedules', 'komika', 'open-mic-history')
    )
    OR (
      public.jwt_has_role('event_admin')
      AND (storage.foldername(name))[1] IN ('events', 'event-lineups', 'partners')
    )
    OR (
      public.jwt_has_role('member')
      AND (storage.foldername(name))[1] IN ('komika', 'open-mic-history')
      AND (storage.foldername(name))[2] = auth.uid()::text
    )
    OR (
      (storage.foldername(name))[1] = 'admin-profiles'
      AND (
        public.jwt_has_role('event_admin')
        OR public.jwt_has_role('open_mic_admin')
        OR public.jwt_has_role('admin_ticket')
        OR public.jwt_has_role('admin_qr')
      )
    )
  )
);

CREATE POLICY "serang_media_update_scoped"
ON storage.objects FOR UPDATE TO authenticated
USING (
  bucket_id = 'standupindo-media'
  AND (
    public.jwt_has_role('admin')
    OR (public.jwt_has_role('open_mic_admin') AND (storage.foldername(name))[1] IN ('open-mic', 'ccs-schedules', 'komika', 'open-mic-history'))
    OR (public.jwt_has_role('event_admin') AND (storage.foldername(name))[1] IN ('events', 'event-lineups', 'partners'))
    OR (
      (storage.foldername(name))[1] = 'admin-profiles'
      AND (
        public.jwt_has_role('event_admin')
        OR public.jwt_has_role('open_mic_admin')
        OR public.jwt_has_role('admin_ticket')
        OR public.jwt_has_role('admin_qr')
      )
    )
  )
)
WITH CHECK (
  bucket_id = 'standupindo-media'
  AND (
    public.jwt_has_role('admin')
    OR (public.jwt_has_role('open_mic_admin') AND (storage.foldername(name))[1] IN ('open-mic', 'ccs-schedules', 'komika', 'open-mic-history'))
    OR (public.jwt_has_role('event_admin') AND (storage.foldername(name))[1] IN ('events', 'event-lineups', 'partners'))
    OR (
      (storage.foldername(name))[1] = 'admin-profiles'
      AND (
        public.jwt_has_role('event_admin')
        OR public.jwt_has_role('open_mic_admin')
        OR public.jwt_has_role('admin_ticket')
        OR public.jwt_has_role('admin_qr')
      )
    )
  )
);

CREATE POLICY "serang_media_delete_scoped"
ON storage.objects FOR DELETE TO authenticated
USING (
  bucket_id = 'standupindo-media'
  AND (
    public.jwt_has_role('admin')
    OR (public.jwt_has_role('open_mic_admin') AND (storage.foldername(name))[1] IN ('open-mic', 'ccs-schedules', 'komika', 'open-mic-history'))
    OR (public.jwt_has_role('event_admin') AND (storage.foldername(name))[1] IN ('events', 'event-lineups', 'partners'))
    OR (
      (storage.foldername(name))[1] = 'admin-profiles'
      AND (
        public.jwt_has_role('event_admin')
        OR public.jwt_has_role('open_mic_admin')
        OR public.jwt_has_role('admin_ticket')
        OR public.jwt_has_role('admin_qr')
      )
    )
  )
);
