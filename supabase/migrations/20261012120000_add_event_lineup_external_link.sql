ALTER TABLE public.event_lineups
  ADD COLUMN IF NOT EXISTS external_url text;

ALTER TABLE public.event_lineups
  DROP CONSTRAINT IF EXISTS event_lineups_external_url_check;

ALTER TABLE public.event_lineups
  ADD CONSTRAINT event_lineups_external_url_check
  CHECK (external_url IS NULL OR external_url ~* '^https://');
