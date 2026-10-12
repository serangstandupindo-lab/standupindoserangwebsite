CREATE TABLE IF NOT EXISTS public.ccs_schedules (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title text NOT NULL DEFAULT 'Cilegon Comedy Sharing (CCS)'
    CHECK (length(trim(title)) BETWEEN 1 AND 160),
  event_date date NOT NULL,
  start_time time without time zone NOT NULL,
  venue text CHECK (venue IS NULL OR length(trim(venue)) <= 180),
  address text CHECK (address IS NULL OR length(trim(address)) <= 300),
  maps_url text CHECK (maps_url IS NULL OR maps_url ~* '^https://'),
  latitude double precision,
  longitude double precision,
  poster_url text CHECK (poster_url IS NULL OR poster_url ~* '^https://'),
  notes text CHECK (notes IS NULL OR length(trim(notes)) <= 1000),
  is_published boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT ccs_schedules_valid_coordinates
    CHECK (
      (latitude IS NULL AND longitude IS NULL)
      OR (
        latitude IS NOT NULL AND longitude IS NOT NULL
        AND latitude BETWEEN -90 AND 90
        AND longitude BETWEEN -180 AND 180
      )
    )
);

CREATE INDEX IF NOT EXISTS idx_ccs_schedules_published_date_time
  ON public.ccs_schedules(is_published, event_date, start_time);

ALTER TABLE public.ccs_schedules ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "public_read_upcoming_ccs_schedules" ON public.ccs_schedules;
CREATE POLICY "public_read_upcoming_ccs_schedules"
  ON public.ccs_schedules FOR SELECT TO anon, authenticated
  USING (
    is_published = true
    AND event_date >= (now() AT TIME ZONE 'Asia/Jakarta')::date
  );

DROP POLICY IF EXISTS "ccs_admin_read_all_schedules" ON public.ccs_schedules;
CREATE POLICY "ccs_admin_read_all_schedules"
  ON public.ccs_schedules FOR SELECT TO authenticated
  USING (public.jwt_has_role('admin') OR public.jwt_has_role('open_mic_admin'));

DROP POLICY IF EXISTS "ccs_admin_insert_schedules" ON public.ccs_schedules;
CREATE POLICY "ccs_admin_insert_schedules"
  ON public.ccs_schedules FOR INSERT TO authenticated
  WITH CHECK (public.jwt_has_role('admin') OR public.jwt_has_role('open_mic_admin'));

DROP POLICY IF EXISTS "ccs_admin_update_schedules" ON public.ccs_schedules;
CREATE POLICY "ccs_admin_update_schedules"
  ON public.ccs_schedules FOR UPDATE TO authenticated
  USING (public.jwt_has_role('admin') OR public.jwt_has_role('open_mic_admin'))
  WITH CHECK (public.jwt_has_role('admin') OR public.jwt_has_role('open_mic_admin'));

DROP POLICY IF EXISTS "ccs_admin_delete_schedules" ON public.ccs_schedules;
CREATE POLICY "ccs_admin_delete_schedules"
  ON public.ccs_schedules FOR DELETE TO authenticated
  USING (public.jwt_has_role('admin') OR public.jwt_has_role('open_mic_admin'));

REVOKE ALL ON public.ccs_schedules FROM PUBLIC, anon, authenticated;
GRANT SELECT ON public.ccs_schedules TO anon, authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.ccs_schedules TO authenticated;
