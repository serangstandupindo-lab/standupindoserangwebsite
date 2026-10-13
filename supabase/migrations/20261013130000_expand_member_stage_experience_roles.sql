ALTER TABLE public.member_stage_experiences
  DROP CONSTRAINT IF EXISTS member_stage_experiences_role_check;

ALTER TABLE public.member_stage_experiences
  ADD CONSTRAINT member_stage_experiences_role_check
  CHECK (role IN (
    'Special Show',
    'Guest Star',
    'Lineup / Penampil',
    'Juri',
    'Opener',
    'MC / Host',
    'Lainnya',
    'Penampil Utama',
    'Solo Show'
  ));