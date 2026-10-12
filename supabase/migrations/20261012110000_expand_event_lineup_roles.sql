ALTER TABLE public.event_lineups
  DROP CONSTRAINT IF EXISTS event_lineups_role_category_check;

ALTER TABLE public.event_lineups
  ADD CONSTRAINT event_lineups_role_category_check
  CHECK (role_category IN (
    'lineup',
    'opener',
    'guest_star',
    'mc_host',
    'judge',
    'special_show',
    'other'
  ));
