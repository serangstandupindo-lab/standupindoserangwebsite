CREATE TABLE IF NOT EXISTS public.event_lineups (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  event_id uuid NOT NULL REFERENCES public.events(id) ON DELETE CASCADE,
  komika_id uuid REFERENCES public.komika(id) ON DELETE SET NULL,
  performer_name text NOT NULL CHECK (length(trim(performer_name)) BETWEEN 1 AND 160),
  role_category text NOT NULL CHECK (role_category IN ('guest_star', 'opener', 'mc_host', 'other')),
  role_title text CHECK (role_title IS NULL OR length(trim(role_title)) <= 100),
  photo_url text CHECK (photo_url IS NULL OR photo_url ~* '^https://'),
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_event_lineups_event_sort
  ON public.event_lineups(event_id, sort_order, created_at);
CREATE INDEX IF NOT EXISTS idx_event_lineups_komika
  ON public.event_lineups(komika_id) WHERE komika_id IS NOT NULL;
CREATE UNIQUE INDEX IF NOT EXISTS idx_event_lineups_unique_member
  ON public.event_lineups(event_id, komika_id) WHERE komika_id IS NOT NULL;
CREATE UNIQUE INDEX IF NOT EXISTS idx_event_lineups_unique_external_name
  ON public.event_lineups(event_id, lower(trim(performer_name))) WHERE komika_id IS NULL;

ALTER TABLE public.event_lineups ENABLE ROW LEVEL SECURITY;

CREATE POLICY "public_read_published_event_lineups"
  ON public.event_lineups FOR SELECT TO anon, authenticated
  USING (EXISTS (
    SELECT 1 FROM public.events
    WHERE events.id = event_lineups.event_id AND events.published = true
  ));
CREATE POLICY "event_admin_read_all_event_lineups"
  ON public.event_lineups FOR SELECT TO authenticated
  USING (public.jwt_has_role('admin') OR public.jwt_has_role('event_admin'));
CREATE POLICY "event_admin_insert_event_lineups"
  ON public.event_lineups FOR INSERT TO authenticated
  WITH CHECK (public.jwt_has_role('admin') OR public.jwt_has_role('event_admin'));
CREATE POLICY "event_admin_update_event_lineups"
  ON public.event_lineups FOR UPDATE TO authenticated
  USING (public.jwt_has_role('admin') OR public.jwt_has_role('event_admin'))
  WITH CHECK (public.jwt_has_role('admin') OR public.jwt_has_role('event_admin'));
CREATE POLICY "event_admin_delete_event_lineups"
  ON public.event_lineups FOR DELETE TO authenticated
  USING (public.jwt_has_role('admin') OR public.jwt_has_role('event_admin'));

CREATE TABLE IF NOT EXISTS public.member_stage_experiences (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  komika_id uuid NOT NULL REFERENCES public.komika(id) ON DELETE CASCADE,
  event_date date NOT NULL,
  event_name text NOT NULL CHECK (length(trim(event_name)) BETWEEN 1 AND 160),
  event_type text CHECK (event_type IS NULL OR length(trim(event_type)) <= 100),
  role text NOT NULL CHECK (role IN ('Opener', 'Guest Star', 'MC / Host', 'Penampil Utama', 'Solo Show', 'Lineup / Penampil', 'Lainnya')),
  custom_role text CHECK (custom_role IS NULL OR length(trim(custom_role)) <= 100),
  organizer text CHECK (organizer IS NULL OR length(trim(organizer)) <= 160),
  city text NOT NULL CHECK (length(trim(city)) BETWEEN 1 AND 100),
  external_url text CHECK (external_url IS NULL OR external_url ~* '^https://'),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT member_stage_experiences_custom_role_required
    CHECK ((role = 'Lainnya' AND nullif(trim(custom_role), '') IS NOT NULL) OR role <> 'Lainnya')
);

CREATE INDEX IF NOT EXISTS idx_member_stage_experiences_komika_date
  ON public.member_stage_experiences(komika_id, event_date DESC, created_at DESC);

ALTER TABLE public.member_stage_experiences ENABLE ROW LEVEL SECURITY;

CREATE OR REPLACE FUNCTION public.member_owns_komika(p_komika_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.komika
    WHERE id = p_komika_id AND user_id = auth.uid()
  );
$$;
REVOKE ALL ON FUNCTION public.member_owns_komika(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.member_owns_komika(uuid) TO authenticated;

CREATE POLICY "public_read_published_member_stage_experiences"
  ON public.member_stage_experiences FOR SELECT TO anon, authenticated
  USING (EXISTS (SELECT 1 FROM public.komika
    WHERE komika.id = member_stage_experiences.komika_id
      AND komika.published = true AND komika.status = 'active'));
CREATE POLICY "member_read_own_stage_experiences"
  ON public.member_stage_experiences FOR SELECT TO authenticated
  USING (public.member_owns_komika(komika_id));
CREATE POLICY "member_insert_own_stage_experiences"
  ON public.member_stage_experiences FOR INSERT TO authenticated
  WITH CHECK (public.member_owns_komika(komika_id));
CREATE POLICY "member_update_own_stage_experiences"
  ON public.member_stage_experiences FOR UPDATE TO authenticated
  USING (public.member_owns_komika(komika_id))
  WITH CHECK (public.member_owns_komika(komika_id));
CREATE POLICY "member_delete_own_stage_experiences"
  ON public.member_stage_experiences FOR DELETE TO authenticated
  USING (public.member_owns_komika(komika_id));

REVOKE ALL ON public.event_lineups, public.member_stage_experiences FROM PUBLIC, anon, authenticated;
GRANT SELECT ON public.event_lineups TO anon, authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.event_lineups TO authenticated;
GRANT SELECT ON public.member_stage_experiences TO anon, authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.member_stage_experiences TO authenticated;
