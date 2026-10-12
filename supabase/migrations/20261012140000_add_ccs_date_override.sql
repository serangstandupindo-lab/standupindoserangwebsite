ALTER TABLE public.ccs_schedules
  ADD COLUMN IF NOT EXISTS date_override boolean NOT NULL DEFAULT false;

DROP POLICY IF EXISTS "public_read_upcoming_ccs_schedules" ON public.ccs_schedules;
CREATE POLICY "public_read_upcoming_ccs_schedules"
  ON public.ccs_schedules FOR SELECT TO anon, authenticated
  USING (is_published = true);
