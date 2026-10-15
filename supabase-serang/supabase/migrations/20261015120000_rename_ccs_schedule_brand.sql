ALTER TABLE public.ccs_schedules
  ALTER COLUMN title SET DEFAULT 'Serang Sharing';

UPDATE public.ccs_schedules
SET title = 'Serang Sharing',
    updated_at = now()
WHERE lower(btrim(title)) IN (
  'serang comedy sharing',
  'serang comedy sharing (ccs)',
  'cilegon comedy sharing',
  'cilegon comedy sharing (ccs)'
);
