-- Standupindo Serang baseline generated for isolated staging validation.
-- Do not apply to production until all staging security and feature tests pass.

-- Source migration: 20260903035848 core schema (tenant-neutralized)
-- Extensions
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ============================================================
-- open_mics
-- ============================================================
CREATE TABLE IF NOT EXISTS open_mics (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title text NOT NULL,
  slug text NOT NULL UNIQUE,
  poster text,
  date date NOT NULL,
  time text NOT NULL,
  venue text NOT NULL,
  location text NOT NULL,
  description text,
  capacity int NOT NULL DEFAULT 10,
  status text NOT NULL DEFAULT 'upcoming',
  registration_status text NOT NULL DEFAULT 'open',
  published boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE open_mics ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "public_read_open_mics" ON open_mics;
CREATE POLICY "public_read_open_mics" ON open_mics FOR SELECT
  TO anon, authenticated USING (published = true);

DROP POLICY IF EXISTS "admin_all_open_mics" ON open_mics;
CREATE POLICY "admin_all_open_mics" ON open_mics FOR ALL
  TO authenticated USING (true) WITH CHECK (true);

-- ============================================================
-- open_mic_registrations
-- ============================================================
CREATE TABLE IF NOT EXISTS open_mic_registrations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  registration_id text NOT NULL UNIQUE,
  open_mic_id uuid NOT NULL REFERENCES open_mics(id) ON DELETE CASCADE,
  full_name text NOT NULL,
  stage_name text NOT NULL,
  community text,
  instagram text,
  whatsapp text,
  notes text,
  status text NOT NULL DEFAULT 'pending',
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE open_mic_registrations ENABLE ROW LEVEL SECURITY;

CREATE SEQUENCE IF NOT EXISTS open_mic_reg_seq;

DROP POLICY IF EXISTS "public_insert_registrations" ON open_mic_registrations;
CREATE POLICY "public_insert_registrations" ON open_mic_registrations FOR INSERT
  TO anon, authenticated WITH CHECK (true);

DROP POLICY IF EXISTS "admin_all_registrations" ON open_mic_registrations;
CREATE POLICY "admin_all_registrations" ON open_mic_registrations FOR ALL
  TO authenticated USING (true) WITH CHECK (true);

-- ============================================================
-- events
-- ============================================================
CREATE TABLE IF NOT EXISTS events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title text NOT NULL,
  slug text NOT NULL UNIQUE,
  poster text,
  date date NOT NULL,
  time text NOT NULL,
  venue text NOT NULL,
  location text NOT NULL,
  description text,
  status text NOT NULL DEFAULT 'upcoming',
  published boolean NOT NULL DEFAULT false,
  whatsapp_number text NOT NULL,
  whatsapp_message text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE events ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "public_read_events" ON events;
CREATE POLICY "public_read_events" ON events FOR SELECT
  TO anon, authenticated USING (published = true);

DROP POLICY IF EXISTS "admin_all_events" ON events;
CREATE POLICY "admin_all_events" ON events FOR ALL
  TO authenticated USING (true) WITH CHECK (true);

-- ============================================================
-- event_tickets
-- ============================================================
CREATE TABLE IF NOT EXISTS event_tickets (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  event_id uuid NOT NULL REFERENCES events(id) ON DELETE CASCADE,
  name text NOT NULL,
  price int NOT NULL,
  description text,
  created_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE event_tickets ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "public_read_event_tickets" ON event_tickets;
CREATE POLICY "public_read_event_tickets" ON event_tickets FOR SELECT
  TO anon, authenticated USING (true);

DROP POLICY IF EXISTS "admin_all_event_tickets" ON event_tickets;
CREATE POLICY "admin_all_event_tickets" ON event_tickets FOR ALL
  TO authenticated USING (true) WITH CHECK (true);

-- ============================================================
-- komika
-- ============================================================
CREATE TABLE IF NOT EXISTS komika (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  stage_name text NOT NULL,
  slug text NOT NULL UNIQUE,
  photo text,
  bio text,
  instagram_url text,
  tiktok_url text,
  youtube_url text,
  specialties text[] NOT NULL DEFAULT '{}',
  status text NOT NULL DEFAULT 'active',
  published boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE komika ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "public_read_komika" ON komika;
CREATE POLICY "public_read_komika" ON komika FOR SELECT
  TO anon, authenticated USING (published = true);

DROP POLICY IF EXISTS "admin_all_komika" ON komika;
CREATE POLICY "admin_all_komika" ON komika FOR ALL
  TO authenticated USING (true) WITH CHECK (true);

-- ============================================================
-- site_settings (single row)
-- ============================================================
CREATE TABLE IF NOT EXISTS site_settings (
  id int PRIMARY KEY DEFAULT 1,
  whatsapp_admin text NOT NULL DEFAULT '',
  instagram_url text NOT NULL DEFAULT '',
  tiktok_url text NOT NULL DEFAULT '',
  youtube_url text NOT NULL DEFAULT '',
  address text NOT NULL DEFAULT 'Serang, Banten',
  short_description text NOT NULL DEFAULT 'Menjadi ruang berkumpulnya komika, penikmat komedi, dan insan kreatif untuk berbagi tawa, mengasah kemampuan, serta saling mendukung dalam berkarya. Bersama-sama membangun ekosistem stand-up comedy yang aktif, inklusif, dan terus berkembang di Serang.',
  CONSTRAINT single_row CHECK (id = 1)
);
ALTER TABLE site_settings ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "public_read_site_settings" ON site_settings;
CREATE POLICY "public_read_site_settings" ON site_settings FOR SELECT
  TO anon, authenticated USING (true);

DROP POLICY IF EXISTS "admin_all_site_settings" ON site_settings;
CREATE POLICY "admin_all_site_settings" ON site_settings FOR ALL
  TO authenticated USING (true) WITH CHECK (true);

-- ============================================================
-- Indexes
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_open_mics_date ON open_mics(date);
CREATE INDEX IF NOT EXISTS idx_open_mic_reg_open_mic_id ON open_mic_registrations(open_mic_id);
CREATE INDEX IF NOT EXISTS idx_open_mic_reg_status ON open_mic_registrations(status);
CREATE INDEX IF NOT EXISTS idx_events_date ON events(date);
CREATE INDEX IF NOT EXISTS idx_event_tickets_event_id ON event_tickets(event_id);

-- ============================================================
-- Seed only the empty tenant settings row; community content is added by Serang admins.
INSERT INTO site_settings (id) VALUES (1) ON CONFLICT (id) DO NOTHING;


-- Source migration: 20260903035853_add_registration_seq_rpc.sql
CREATE OR REPLACE FUNCTION next_open_mic_reg_seq()
RETURNS bigint
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  next_val bigint;
BEGIN
  next_val := nextval('open_mic_reg_seq');
  RETURN next_val;
END;
$$;

GRANT EXECUTE ON FUNCTION next_open_mic_reg_seq() TO anon, authenticated;
GRANT USAGE ON SEQUENCE open_mic_reg_seq TO anon, authenticated;

-- Source migration: 20260903035858_add_maps_url_and_contacts.sql
ALTER TABLE open_mics
  ADD COLUMN IF NOT EXISTS maps_url text;

ALTER TABLE events
  ADD COLUMN IF NOT EXISTS maps_url text;

UPDATE site_settings
SET whatsapp_admin = '', instagram_url = '', tiktok_url = '', youtube_url = '', address = 'Serang, Banten'
WHERE id = 1;

-- Source migration: 20260903035903_add_social_affiliation_settings.sql
ALTER TABLE site_settings
  ADD COLUMN IF NOT EXISTS affiliation_name text,
  ADD COLUMN IF NOT EXISTS affiliation_website text,
  ADD COLUMN IF NOT EXISTS affiliation_logo_url text;

UPDATE site_settings
SET
  whatsapp_admin = '082240154499',
  affiliation_name = 'Standup Indo',
  affiliation_website = 'https://standupindo.id/',
  affiliation_logo_url = '/assets/images/image.png'
WHERE id = 1;

UPDATE events
SET whatsapp_number = '082240154499'
WHERE whatsapp_number IS DISTINCT FROM '082240154499';

-- Source migration: 20260903035907_add_ticket_price_to_events.sql
ALTER TABLE events ADD COLUMN IF NOT EXISTS ticket_price integer NOT NULL DEFAULT 0;

-- Source migration: 20260903035912_extend_event_tickets_with_url_status_sort.sql
ALTER TABLE event_tickets ADD COLUMN IF NOT EXISTS ticket_url text;
ALTER TABLE event_tickets ADD COLUMN IF NOT EXISTS status text NOT NULL DEFAULT 'active';
ALTER TABLE event_tickets ADD COLUMN IF NOT EXISTS sort_order integer NOT NULL DEFAULT 0;
ALTER TABLE event_tickets ADD COLUMN IF NOT EXISTS updated_at timestamptz NOT NULL DEFAULT now();

-- Drop old policies
DROP POLICY IF EXISTS "public_read_event_tickets" ON event_tickets;
DROP POLICY IF EXISTS "admin_all_event_tickets" ON event_tickets;

-- Public: only read active tickets
CREATE POLICY "public_read_active_event_tickets" ON event_tickets
  FOR SELECT TO anon, authenticated
  USING (status = 'active');

-- Admin: full CRUD (authenticated only)
CREATE POLICY "admin_insert_event_tickets" ON event_tickets
  FOR INSERT TO authenticated WITH CHECK (true);

CREATE POLICY "admin_update_event_tickets" ON event_tickets
  FOR UPDATE TO authenticated USING (true) WITH CHECK (true);

CREATE POLICY "admin_delete_event_tickets" ON event_tickets
  FOR DELETE TO authenticated USING (true);

-- Source migration: 20260903035918_fix_open_mic_registrations_rls_protect_whatsapp.sql
-- Drop old policies
DROP POLICY IF EXISTS "admin_all_registrations" ON open_mic_registrations;
DROP POLICY IF EXISTS "public_insert_registrations" ON open_mic_registrations;

-- Admin: full CRUD (authenticated only)
CREATE POLICY "admin_select_registrations" ON open_mic_registrations
  FOR SELECT TO authenticated USING (true);

CREATE POLICY "admin_insert_registrations" ON open_mic_registrations
  FOR INSERT TO authenticated WITH CHECK (true);

CREATE POLICY "admin_update_registrations" ON open_mic_registrations
  FOR UPDATE TO authenticated USING (true) WITH CHECK (true);

CREATE POLICY "admin_delete_registrations" ON open_mic_registrations
  FOR DELETE TO authenticated USING (true);

-- Public: can read only confirmed registrations (for lineup)
CREATE POLICY "public_read_confirmed_registrations" ON open_mic_registrations
  FOR SELECT TO anon, authenticated
  USING (status = 'confirmed');

-- Public: can insert registrations (for signup)
CREATE POLICY "public_insert_registrations" ON open_mic_registrations
  FOR INSERT TO anon, authenticated WITH CHECK (true);

-- Column-level: protect sensitive columns from anon
REVOKE SELECT ON open_mic_registrations FROM anon;
GRANT SELECT (id, registration_id, open_mic_id, stage_name, community, instagram, status, created_at, updated_at) ON open_mic_registrations TO anon;

-- Source migration: 20260903035924_create_media_storage_bucket.sql
INSERT INTO storage.buckets (id, name, public, allowed_mime_types, file_size_limit)
VALUES (
  'standupindo-media',
  'standupindo-media',
  true,
  ARRAY['image/jpeg', 'image/png', 'image/webp'],
  5242880
) ON CONFLICT (id) DO NOTHING;

DROP POLICY IF EXISTS "media_public_read" ON storage.objects;
CREATE POLICY "media_public_read"
ON storage.objects FOR SELECT
TO anon, authenticated
USING (bucket_id = 'standupindo-media');

DROP POLICY IF EXISTS "media_admin_insert" ON storage.objects;
CREATE POLICY "media_admin_insert"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'standupindo-media');

DROP POLICY IF EXISTS "media_admin_update" ON storage.objects;
CREATE POLICY "media_admin_update"
ON storage.objects FOR UPDATE
TO authenticated
USING (bucket_id = 'standupindo-media')
WITH CHECK (bucket_id = 'standupindo-media');

DROP POLICY IF EXISTS "media_admin_delete" ON storage.objects;
CREATE POLICY "media_admin_delete"
ON storage.objects FOR DELETE
TO authenticated
USING (bucket_id = 'standupindo-media');

-- Source migration: 20260903050000_add_branding_settings.sql
ALTER TABLE site_settings
  ADD COLUMN IF NOT EXISTS site_name text NOT NULL DEFAULT 'Standupindo Serang',
  ADD COLUMN IF NOT EXISTS site_short_name text NOT NULL DEFAULT 'STANDUPINDO SERANG',
  ADD COLUMN IF NOT EXISTS logo_url text,
  ADD COLUMN IF NOT EXISTS brand_primary text NOT NULL DEFAULT '#D71920',
  ADD COLUMN IF NOT EXISTS brand_hover text NOT NULL DEFAULT '#B5121B',
  ADD COLUMN IF NOT EXISTS brand_accent text NOT NULL DEFAULT '#FFC928';

UPDATE site_settings
SET
  site_name = COALESCE(NULLIF(site_name, ''), 'Standupindo Serang'),
  site_short_name = COALESCE(NULLIF(site_short_name, ''), 'STANDUPINDO SERANG'),
  logo_url = COALESCE(NULLIF(logo_url, ''), '/assets/images/pwa-public.png'),
  brand_primary = COALESCE(NULLIF(brand_primary, ''), '#D71920'),
  brand_hover = COALESCE(NULLIF(brand_hover, ''), '#B5121B'),
  brand_accent = COALESCE(NULLIF(brand_accent, ''), '#FFC928')
WHERE id = 1;


-- Source migration: 20260904090000_add_open_mic_attendance_status.sql
ALTER TABLE open_mic_registrations
  ADD COLUMN IF NOT EXISTS attendance_status text NOT NULL DEFAULT 'unmarked'
  CHECK (attendance_status IN ('unmarked', 'attended', 'absent'));

CREATE INDEX IF NOT EXISTS idx_open_mic_reg_attendance_status
  ON open_mic_registrations(attendance_status);

GRANT SELECT (attendance_status) ON open_mic_registrations TO anon;


-- Source migration: 20260904100000_add_komika_joined_at.sql
ALTER TABLE komika
  ADD COLUMN IF NOT EXISTS joined_at text;


-- Source migration: 20260904110000_add_context_whatsapp_settings.sql
ALTER TABLE site_settings
  ADD COLUMN IF NOT EXISTS whatsapp_registration text,
  ADD COLUMN IF NOT EXISTS whatsapp_partnership text,
  ADD COLUMN IF NOT EXISTS whatsapp_ticket text;

UPDATE site_settings
SET
  whatsapp_registration = COALESCE(NULLIF(whatsapp_registration, ''), whatsapp_admin),
  whatsapp_partnership = COALESCE(NULLIF(whatsapp_partnership, ''), whatsapp_admin),
  whatsapp_ticket = COALESCE(NULLIF(whatsapp_ticket, ''), whatsapp_admin)
WHERE id = 1;


-- Source migration: 20260904120000_add_whatsapp_contact_names.sql
ALTER TABLE site_settings
  ADD COLUMN IF NOT EXISTS whatsapp_admin_name text,
  ADD COLUMN IF NOT EXISTS whatsapp_registration_name text,
  ADD COLUMN IF NOT EXISTS whatsapp_partnership_name text,
  ADD COLUMN IF NOT EXISTS whatsapp_ticket_name text;


-- Source migration: 20260909100000_add_community_and_event_participants.sql
-- Public applications for joining the community and participating in events.
ALTER TABLE events ADD COLUMN IF NOT EXISTS registration_status text NOT NULL DEFAULT 'closed' CHECK (registration_status IN ('open', 'closed'));

CREATE TABLE IF NOT EXISTS community_applications (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  full_name text NOT NULL,
  whatsapp text NOT NULL,
  instagram text,
  city text,
  interests text[] NOT NULL DEFAULT '{}',
  notes text,
  status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE community_applications ENABLE ROW LEVEL SECURITY;
ALTER TABLE community_applications DROP CONSTRAINT IF EXISTS community_applications_whatsapp_digits;
ALTER TABLE community_applications ADD CONSTRAINT community_applications_whatsapp_digits CHECK (whatsapp ~ '^[0-9]+$');

DROP POLICY IF EXISTS "public_insert_community_applications" ON community_applications;
CREATE POLICY "public_insert_community_applications" ON community_applications
  FOR INSERT TO anon, authenticated WITH CHECK (status = 'pending');
DROP POLICY IF EXISTS "admin_select_community_applications" ON community_applications;
CREATE POLICY "admin_select_community_applications" ON community_applications
  FOR SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS "admin_update_community_applications" ON community_applications;
CREATE POLICY "admin_update_community_applications" ON community_applications
  FOR UPDATE TO authenticated USING (true) WITH CHECK (true);
DROP POLICY IF EXISTS "admin_delete_community_applications" ON community_applications;
CREATE POLICY "admin_delete_community_applications" ON community_applications
  FOR DELETE TO authenticated USING (true);

CREATE TABLE IF NOT EXISTS event_participants (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  registration_id text,
  event_id uuid NOT NULL REFERENCES events(id) ON DELETE CASCADE,
  full_name text NOT NULL,
  stage_name text,
  community text,
  whatsapp text NOT NULL,
  instagram text,
  notes text,
  status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE event_participants ENABLE ROW LEVEL SECURITY;
ALTER TABLE event_participants ADD COLUMN IF NOT EXISTS registration_id text;
ALTER TABLE event_participants ADD COLUMN IF NOT EXISTS community text;
CREATE SEQUENCE IF NOT EXISTS event_participant_reg_seq;
UPDATE event_participants SET registration_id = 'EP-' || lpad(nextval('event_participant_reg_seq')::text, 4, '0') WHERE registration_id IS NULL;
ALTER TABLE event_participants ALTER COLUMN registration_id SET DEFAULT 'EP-' || lpad(nextval('event_participant_reg_seq')::text, 4, '0');
ALTER TABLE event_participants ALTER COLUMN registration_id SET NOT NULL;
CREATE UNIQUE INDEX IF NOT EXISTS idx_event_participants_registration_id ON event_participants(registration_id);
UPDATE event_participants SET stage_name = '' WHERE stage_name IS NULL;
ALTER TABLE event_participants ALTER COLUMN stage_name SET NOT NULL;
ALTER TABLE event_participants DROP CONSTRAINT IF EXISTS event_participants_whatsapp_digits;
ALTER TABLE event_participants ADD CONSTRAINT event_participants_whatsapp_digits CHECK (whatsapp ~ '^[0-9]+$');

DROP POLICY IF EXISTS "public_insert_event_participants" ON event_participants;
CREATE POLICY "public_insert_event_participants" ON event_participants
  FOR INSERT TO anon, authenticated WITH CHECK (status = 'pending');
DROP POLICY IF EXISTS "admin_select_event_participants" ON event_participants;
CREATE POLICY "admin_select_event_participants" ON event_participants
  FOR SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS "admin_update_event_participants" ON event_participants;
CREATE POLICY "admin_update_event_participants" ON event_participants
  FOR UPDATE TO authenticated USING (true) WITH CHECK (true);
DROP POLICY IF EXISTS "admin_delete_event_participants" ON event_participants;
CREATE POLICY "admin_delete_event_participants" ON event_participants
  FOR DELETE TO authenticated USING (true);

CREATE INDEX IF NOT EXISTS idx_community_applications_status ON community_applications(status);
CREATE INDEX IF NOT EXISTS idx_event_participants_event_id ON event_participants(event_id);
CREATE INDEX IF NOT EXISTS idx_event_participants_status ON event_participants(status);

-- Tighten the existing public Open Mic insert path: public requests can only
-- create pending registrations for currently published, open Open Mics.
DROP POLICY IF EXISTS "public_insert_registrations" ON open_mic_registrations;
CREATE POLICY "public_insert_registrations" ON open_mic_registrations
  FOR INSERT TO anon, authenticated
  WITH CHECK (
    status = 'pending'
    AND EXISTS (
      SELECT 1 FROM open_mics
      WHERE open_mics.id = open_mic_registrations.open_mic_id
        AND open_mics.published = true
        AND open_mics.status = 'upcoming'
        AND open_mics.registration_status = 'open'
    )
  );


-- Source migration: 20260910100000_add_full_name_to_komika.sql
ALTER TABLE komika
  ADD COLUMN IF NOT EXISTS full_name text;

UPDATE komika
SET full_name = stage_name
WHERE full_name IS NULL OR btrim(full_name) = '';

ALTER TABLE komika
  ALTER COLUMN full_name SET NOT NULL;

ALTER TABLE komika
  ADD COLUMN IF NOT EXISTS whatsapp text;

REVOKE SELECT ON TABLE komika FROM anon;

GRANT SELECT (
  id,
  full_name,
  stage_name,
  slug,
  photo,
  bio,
  instagram_url,
  tiktok_url,
  youtube_url,
  specialties,
  joined_at,
  status,
  published,
  created_at,
  updated_at
) ON TABLE komika TO anon;


-- Source migration: 20260910110000_link_open_mic_registrations_to_komika.sql
ALTER TABLE open_mic_registrations
  ADD COLUMN IF NOT EXISTS komika_id uuid REFERENCES komika(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_open_mic_registrations_komika_id
  ON open_mic_registrations(komika_id);

DROP POLICY IF EXISTS "public_insert_registrations" ON open_mic_registrations;
CREATE POLICY "public_insert_registrations" ON open_mic_registrations
  FOR INSERT TO anon, authenticated
  WITH CHECK (
    status = 'pending'
    AND komika_id IS NULL
    AND EXISTS (
      SELECT 1 FROM open_mics
      WHERE open_mics.id = open_mic_registrations.open_mic_id
        AND open_mics.published = true
        AND open_mics.status = 'upcoming'
        AND open_mics.registration_status = 'open'
    )
  );


-- Source migration: 20260910120000_restrict_komika_private_columns.sql
REVOKE SELECT (full_name, whatsapp)
  ON TABLE komika
  FROM anon;


-- Source migration: 20260910130000_public_event_lineup.sql
DROP POLICY IF EXISTS "public_read_approved_event_participants" ON event_participants;
CREATE POLICY "public_read_approved_event_participants" ON event_participants
  FOR SELECT TO anon
  USING (
    status = 'approved'
    AND EXISTS (
      SELECT 1 FROM events
      WHERE events.id = event_participants.event_id
        AND events.published = true
    )
  );

GRANT SELECT (id, event_id, stage_name, community, instagram, status, created_at)
  ON TABLE event_participants TO anon;

-- Source migration: 20260912010000_add_komika_featured_order.sql
-- Add manual featured ordering for komika cards.
ALTER TABLE komika
  ADD COLUMN IF NOT EXISTS featured_order integer;

CREATE INDEX IF NOT EXISTS idx_komika_featured_order
  ON komika(featured_order);


-- Source migration: 20260912000000_restore_public_select_grants.sql
-- Restore public read grants for the public website.
-- Some deployments only applied the RLS policies but did not restore or preserve
-- the role grants needed for anon/authenticated to read public data through Supabase.

GRANT SELECT ON TABLE open_mics TO anon, authenticated;
GRANT SELECT ON TABLE events TO anon, authenticated;
GRANT SELECT ON TABLE event_tickets TO anon, authenticated;
GRANT SELECT ON TABLE site_settings TO anon, authenticated;

-- Komika public read must stay column-scoped to avoid exposing private admin-only
-- fields such as whatsapp while still restoring the missing public access.
GRANT SELECT (
  id,
  full_name,
  stage_name,
  slug,
  photo,
  bio,
  instagram_url,
  tiktok_url,
  youtube_url,
  specialties,
  joined_at,
  featured_order,
  status,
  published,
  created_at,
  updated_at
) ON TABLE komika TO anon;

-- Public lineup / approved participants need explicit column access in addition to
-- row-level policies.
GRANT SELECT (
  id,
  registration_id,
  open_mic_id,
  komika_id,
  stage_name,
  community,
  instagram,
  status,
  attendance_status,
  created_at,
  updated_at
) ON TABLE open_mic_registrations TO anon;

GRANT SELECT (
  id,
  event_id,
  stage_name,
  community,
  instagram,
  status,
  created_at
) ON TABLE event_participants TO anon;


-- Source migration: 20260912020000_add_event_rules_to_events.sql
-- Add editable event rules / peraturan column for public event detail pages.

ALTER TABLE public.events
  ADD COLUMN IF NOT EXISTS event_rules text;


-- Source migration: 20260913000000_add_partners_and_event_partnerships.sql
-- Create partner master data and event-specific partnership history.

CREATE TABLE IF NOT EXISTS public.partners (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  logo_url text,
  website_url text,
  contact_name text,
  contact_phone text,
  notes text,
  category text NOT NULL CHECK (category IN ('sponsor', 'support', 'media_partner')),
  is_published boolean NOT NULL DEFAULT true,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.event_partnerships (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  event_id uuid NOT NULL REFERENCES public.events(id) ON DELETE CASCADE,
  partner_id uuid NOT NULL REFERENCES public.partners(id) ON DELETE RESTRICT,
  role text NOT NULL CHECK (role IN ('sponsor', 'support', 'media_partner')),
  notes text,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS set_partners_updated_at ON public.partners;
CREATE TRIGGER set_partners_updated_at
BEFORE UPDATE ON public.partners
FOR EACH ROW
EXECUTE FUNCTION public.set_updated_at();

DROP TRIGGER IF EXISTS set_event_partnerships_updated_at ON public.event_partnerships;
CREATE TRIGGER set_event_partnerships_updated_at
BEFORE UPDATE ON public.event_partnerships
FOR EACH ROW
EXECUTE FUNCTION public.set_updated_at();

CREATE INDEX IF NOT EXISTS idx_partners_category_published
ON public.partners(category, is_published, sort_order);

CREATE INDEX IF NOT EXISTS idx_partners_published
ON public.partners(is_published);

CREATE INDEX IF NOT EXISTS idx_event_partnerships_event_id
ON public.event_partnerships(event_id);

CREATE INDEX IF NOT EXISTS idx_event_partnerships_partner_id
ON public.event_partnerships(partner_id);

CREATE INDEX IF NOT EXISTS idx_event_partnerships_role
ON public.event_partnerships(role);

ALTER TABLE public.partners ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.event_partnerships ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "public_read_published_partners" ON public.partners;
CREATE POLICY "public_read_published_partners"
ON public.partners
FOR SELECT
TO anon
USING (is_published = true);

DROP POLICY IF EXISTS "admin_manage_partners" ON public.partners;
CREATE POLICY "admin_manage_partners"
ON public.partners
FOR ALL
TO authenticated
USING (true)
WITH CHECK (true);

DROP POLICY IF EXISTS "public_read_event_partnerships" ON public.event_partnerships;
CREATE POLICY "public_read_event_partnerships"
ON public.event_partnerships
FOR SELECT
TO anon
USING (
  EXISTS (
    SELECT 1
    FROM public.partners p
    WHERE p.id = event_partnerships.partner_id
      AND p.is_published = true
  )
);

DROP POLICY IF EXISTS "admin_manage_event_partnerships" ON public.event_partnerships;
CREATE POLICY "admin_manage_event_partnerships"
ON public.event_partnerships
FOR ALL
TO authenticated
USING (true)
WITH CHECK (true);

GRANT SELECT (
  id,
  name,
  logo_url,
  website_url,
  category,
  is_published,
  sort_order,
  created_at,
  updated_at
) ON public.partners TO anon;

GRANT SELECT ON TABLE public.partners TO authenticated;

GRANT SELECT (
  id,
  event_id,
  partner_id,
  role,
  sort_order,
  created_at,
  updated_at
) ON public.event_partnerships TO anon;

GRANT SELECT ON TABLE public.event_partnerships TO authenticated;


-- Source migration: 20260913010000_add_partner_event_pic_columns.sql
-- Add PIC fields for partner-event relationships so admin can store who the contact is per event.

ALTER TABLE public.event_partnerships
  ADD COLUMN IF NOT EXISTS pic_name text,
  ADD COLUMN IF NOT EXISTS pic_phone text;


-- Source migration: 20260913110000_create_ticket_orders.sql
-- Ticket orders submitted from the public event ticket form.
-- Run this migration in Supabase SQL Editor before enabling local ticket checkout.

CREATE TABLE IF NOT EXISTS public.ticket_orders (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  event_id uuid NOT NULL REFERENCES public.events(id) ON DELETE CASCADE,
  ticket_id uuid REFERENCES public.event_tickets(id) ON DELETE SET NULL,
  ticket_category text NOT NULL,
  full_name text NOT NULL,
  whatsapp text NOT NULL,
  quantity integer NOT NULL DEFAULT 1 CHECK (quantity > 0 AND quantity <= 20),
  unit_price integer NOT NULL CHECK (unit_price >= 0),
  total_price integer NOT NULL CHECK (total_price >= 0),
  notes text,
  status text NOT NULL DEFAULT 'Menunggu Pembayaran' CHECK (status IN ('Menunggu Pembayaran', 'Sudah Bayar', 'Terverifikasi', 'Selesai', 'Dibatalkan')),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.ticket_orders ENABLE ROW LEVEL SECURITY;

CREATE INDEX IF NOT EXISTS idx_ticket_orders_event_id ON public.ticket_orders(event_id);
CREATE INDEX IF NOT EXISTS idx_ticket_orders_created_at ON public.ticket_orders(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_ticket_orders_status ON public.ticket_orders(status);

CREATE OR REPLACE FUNCTION public.prepare_ticket_order()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  selected_ticket public.event_tickets%ROWTYPE;
BEGIN
  SELECT * INTO selected_ticket
  FROM public.event_tickets
  WHERE id = NEW.ticket_id
    AND event_id = NEW.event_id
    AND status = 'active';

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Ticket tidak tersedia untuk event ini';
  END IF;

  NEW.ticket_category := selected_ticket.name;
  NEW.unit_price := selected_ticket.price;
  NEW.total_price := selected_ticket.price * NEW.quantity;
  NEW.status := 'Menunggu Pembayaran';
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS prepare_ticket_order_before_insert ON public.ticket_orders;
CREATE TRIGGER prepare_ticket_order_before_insert
  BEFORE INSERT ON public.ticket_orders
  FOR EACH ROW
  EXECUTE FUNCTION public.prepare_ticket_order();

DROP POLICY IF EXISTS "public_insert_ticket_orders" ON public.ticket_orders;
CREATE POLICY "public_insert_ticket_orders"
  ON public.ticket_orders
  FOR INSERT
  TO anon, authenticated
  WITH CHECK (status = 'Menunggu Pembayaran');

DROP POLICY IF EXISTS "admin_read_ticket_orders" ON public.ticket_orders;
CREATE POLICY "admin_read_ticket_orders"
  ON public.ticket_orders
  FOR SELECT
  TO authenticated
  USING ((auth.jwt() -> 'app_metadata' ->> 'role') = 'admin');

DROP POLICY IF EXISTS "admin_update_ticket_orders" ON public.ticket_orders;
CREATE POLICY "admin_update_ticket_orders"
  ON public.ticket_orders
  FOR UPDATE
  TO authenticated
  USING ((auth.jwt() -> 'app_metadata' ->> 'role') = 'admin')
  WITH CHECK ((auth.jwt() -> 'app_metadata' ->> 'role') = 'admin');

DROP POLICY IF EXISTS "admin_delete_ticket_orders" ON public.ticket_orders;
CREATE POLICY "admin_delete_ticket_orders"
  ON public.ticket_orders
  FOR DELETE
  TO authenticated
  USING ((auth.jwt() -> 'app_metadata' ->> 'role') = 'admin');


-- Source migration: 20260913120000_add_email_to_ticket_orders.sql
-- Add customer email to public ticket orders.
ALTER TABLE public.ticket_orders
  ADD COLUMN IF NOT EXISTS email text;

ALTER TABLE public.ticket_orders
  DROP CONSTRAINT IF EXISTS ticket_orders_email_format;

ALTER TABLE public.ticket_orders
  ADD CONSTRAINT ticket_orders_email_format
  CHECK (email IS NULL OR email ~* '^[^[:space:]@]+@[^[:space:]@]+\.[^[:space:]@]+$');


-- Source migration: 20260913130000_add_order_number_to_ticket_orders.sql
-- Add a short, human-friendly order number for ticket orders.
ALTER TABLE public.ticket_orders
  ADD COLUMN IF NOT EXISTS order_number text;

CREATE UNIQUE INDEX IF NOT EXISTS idx_ticket_orders_order_number
  ON public.ticket_orders(order_number)
  WHERE order_number IS NOT NULL;

ALTER TABLE public.ticket_orders
  DROP CONSTRAINT IF EXISTS ticket_orders_order_number_format;

ALTER TABLE public.ticket_orders
  ADD CONSTRAINT ticket_orders_order_number_format
  CHECK (order_number IS NULL OR order_number ~ '^[A-Z]{3}-[A-Z0-9]{6}$');


-- Source migration: 20260915000000_add_evaluator_assignment_and_evaluation.sql
CREATE TABLE IF NOT EXISTS evaluator_assignments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  open_mic_id uuid NOT NULL REFERENCES open_mics(id) ON DELETE CASCADE,
  evaluator_user_id uuid NOT NULL,
  assigned_by uuid,
  status text NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'inactive')),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_evaluator_assignments_open_mic_id
  ON evaluator_assignments(open_mic_id);
CREATE INDEX IF NOT EXISTS idx_evaluator_assignments_evaluator_user_id
  ON evaluator_assignments(evaluator_user_id);

CREATE TABLE IF NOT EXISTS evaluations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  open_mic_id uuid NOT NULL REFERENCES open_mics(id) ON DELETE CASCADE,
  evaluator_user_id uuid NOT NULL,
  performer_registration_id uuid NOT NULL REFERENCES open_mic_registrations(id) ON DELETE CASCADE,
  performer_komika_id uuid REFERENCES komika(id) ON DELETE SET NULL,
  material_score numeric(3,1) CHECK (material_score BETWEEN 0 AND 10),
  punchline_score numeric(3,1) CHECK (punchline_score BETWEEN 0 AND 10),
  delivery_score numeric(3,1) CHECK (delivery_score BETWEEN 0 AND 10),
  timing_score numeric(3,1) CHECK (timing_score BETWEEN 0 AND 10),
  stage_presence_score numeric(3,1) CHECK (stage_presence_score BETWEEN 0 AND 10),
  crowd_interaction_score numeric(3,1) CHECK (crowd_interaction_score BETWEEN 0 AND 10),
  strengths text,
  improvements text,
  notes text,
  status text NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'submitted')),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE komika ADD COLUMN IF NOT EXISTS user_id uuid;
CREATE INDEX IF NOT EXISTS idx_komika_user_id ON komika(user_id);

CREATE INDEX IF NOT EXISTS idx_evaluations_open_mic_id
  ON evaluations(open_mic_id);
CREATE INDEX IF NOT EXISTS idx_evaluations_evaluator_user_id
  ON evaluations(evaluator_user_id);
CREATE INDEX IF NOT EXISTS idx_evaluations_performer_registration_id
  ON evaluations(performer_registration_id);

ALTER TABLE evaluator_assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE evaluations ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "admin_all_evaluator_assignments" ON evaluator_assignments;
CREATE POLICY "admin_all_evaluator_assignments" ON evaluator_assignments
  FOR ALL TO authenticated
  USING ((auth.jwt() -> 'app_metadata' ->> 'role') = 'admin')
  WITH CHECK ((auth.jwt() -> 'app_metadata' ->> 'role') = 'admin');

DROP POLICY IF EXISTS "evaluator_read_own_assignments" ON evaluator_assignments;
CREATE POLICY "evaluator_read_own_assignments" ON evaluator_assignments
  FOR SELECT TO authenticated
  USING (evaluator_user_id = auth.uid() OR (auth.jwt() -> 'app_metadata' ->> 'role') = 'admin');

DROP POLICY IF EXISTS "admin_all_evaluations" ON evaluations;
CREATE POLICY "admin_all_evaluations" ON evaluations
  FOR ALL TO authenticated
  USING ((auth.jwt() -> 'app_metadata' ->> 'role') = 'admin')
  WITH CHECK ((auth.jwt() -> 'app_metadata' ->> 'role') = 'admin');

DROP POLICY IF EXISTS "evaluator_manage_own_evaluations" ON evaluations;
CREATE POLICY "evaluator_manage_own_evaluations" ON evaluations
  FOR INSERT TO authenticated
  WITH CHECK (
    evaluator_user_id = auth.uid()
    AND EXISTS (
      SELECT 1
      FROM evaluator_assignments ea
      WHERE ea.open_mic_id = evaluations.open_mic_id
        AND ea.evaluator_user_id = auth.uid()
        AND ea.status = 'active'
    )
    AND EXISTS (
      SELECT 1
      FROM open_mic_registrations r
      WHERE r.id = evaluations.performer_registration_id
        AND r.open_mic_id = evaluations.open_mic_id
    )
  );

CREATE POLICY "evaluator_update_own_evaluations" ON evaluations
  FOR UPDATE TO authenticated
  USING (
    evaluator_user_id = auth.uid()
    AND EXISTS (
      SELECT 1
      FROM evaluator_assignments ea
      WHERE ea.open_mic_id = evaluations.open_mic_id
        AND ea.evaluator_user_id = auth.uid()
        AND ea.status = 'active'
    )
  )
  WITH CHECK (
    evaluator_user_id = auth.uid()
    AND EXISTS (
      SELECT 1
      FROM evaluator_assignments ea
      WHERE ea.open_mic_id = evaluations.open_mic_id
        AND ea.evaluator_user_id = auth.uid()
        AND ea.status = 'active'
    )
  );

CREATE POLICY "evaluator_read_own_evaluations" ON evaluations
  FOR SELECT TO authenticated
  USING (
    evaluator_user_id = auth.uid()
    OR (auth.jwt() -> 'app_metadata' ->> 'role') = 'admin'
  );

CREATE POLICY "member_read_own_evaluations" ON evaluations
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1
      FROM open_mic_registrations r
      JOIN komika k ON k.id = r.komika_id
      WHERE r.id = evaluations.performer_registration_id
        AND (k.user_id = auth.uid() OR k.id = auth.uid())
    )
    OR (auth.jwt() -> 'app_metadata' ->> 'role') = 'admin'
  );


-- Source migration: 20260915100000_extend_member_profile_and_notifications.sql
ALTER TABLE event_participants
  ADD COLUMN IF NOT EXISTS komika_id uuid REFERENCES komika(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_event_participants_komika_id
  ON event_participants(komika_id);

DROP POLICY IF EXISTS "member_read_own_open_mic_registrations" ON open_mic_registrations;
DROP POLICY IF EXISTS "admin_select_registrations" ON open_mic_registrations;
DROP POLICY IF EXISTS "admin_insert_registrations" ON open_mic_registrations;
DROP POLICY IF EXISTS "admin_update_registrations" ON open_mic_registrations;
DROP POLICY IF EXISTS "admin_delete_registrations" ON open_mic_registrations;
CREATE POLICY "admin_select_registrations" ON open_mic_registrations
  FOR SELECT TO authenticated USING ((auth.jwt() -> 'app_metadata' ->> 'role') = 'admin');
CREATE POLICY "admin_insert_registrations" ON open_mic_registrations
  FOR INSERT TO authenticated WITH CHECK ((auth.jwt() -> 'app_metadata' ->> 'role') = 'admin');
CREATE POLICY "admin_update_registrations" ON open_mic_registrations
  FOR UPDATE TO authenticated USING ((auth.jwt() -> 'app_metadata' ->> 'role') = 'admin') WITH CHECK ((auth.jwt() -> 'app_metadata' ->> 'role') = 'admin');
CREATE POLICY "admin_delete_registrations" ON open_mic_registrations
  FOR DELETE TO authenticated USING ((auth.jwt() -> 'app_metadata' ->> 'role') = 'admin');

CREATE POLICY "member_read_own_open_mic_registrations" ON open_mic_registrations
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM komika k
      WHERE k.id = open_mic_registrations.komika_id
        AND k.user_id = auth.uid()
    )
    OR (auth.jwt() -> 'app_metadata' ->> 'role') = 'admin'
  );

DROP POLICY IF EXISTS "member_insert_own_open_mic_registration" ON open_mic_registrations;
CREATE POLICY "member_insert_own_open_mic_registration" ON open_mic_registrations
  FOR INSERT TO authenticated
  WITH CHECK (
    status = 'pending'
    AND EXISTS (
      SELECT 1 FROM komika k
      WHERE k.id = open_mic_registrations.komika_id
        AND k.user_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "member_read_own_event_participants" ON event_participants;
DROP POLICY IF EXISTS "admin_select_event_participants" ON event_participants;
DROP POLICY IF EXISTS "admin_update_event_participants" ON event_participants;
DROP POLICY IF EXISTS "admin_delete_event_participants" ON event_participants;
CREATE POLICY "admin_select_event_participants" ON event_participants
  FOR SELECT TO authenticated USING ((auth.jwt() -> 'app_metadata' ->> 'role') = 'admin');
CREATE POLICY "admin_update_event_participants" ON event_participants
  FOR UPDATE TO authenticated USING ((auth.jwt() -> 'app_metadata' ->> 'role') = 'admin') WITH CHECK ((auth.jwt() -> 'app_metadata' ->> 'role') = 'admin');
CREATE POLICY "admin_delete_event_participants" ON event_participants
  FOR DELETE TO authenticated USING ((auth.jwt() -> 'app_metadata' ->> 'role') = 'admin');

CREATE POLICY "member_read_own_event_participants" ON event_participants
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM komika k
      WHERE k.id = event_participants.komika_id
        AND k.user_id = auth.uid()
    )
    OR (auth.jwt() -> 'app_metadata' ->> 'role') = 'admin'
  );

DROP POLICY IF EXISTS "member_update_own_profile" ON komika;
CREATE POLICY "member_update_own_profile" ON komika
  FOR UPDATE TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());


-- Source migration: 20260915110000_harden_member_rls_and_profile_updates.sql
-- Admin CRUD must be role-gated. Never trust the frontend route or hidden controls.
DROP POLICY IF EXISTS "admin_all_open_mics" ON open_mics;
DROP POLICY IF EXISTS "admin_all_events" ON events;
DROP POLICY IF EXISTS "admin_all_event_tickets" ON event_tickets;
DROP POLICY IF EXISTS "admin_all_komika" ON komika;
DROP POLICY IF EXISTS "admin_all_site_settings" ON site_settings;
DROP POLICY IF EXISTS "admin_insert_event_tickets" ON event_tickets;
DROP POLICY IF EXISTS "admin_update_event_tickets" ON event_tickets;
DROP POLICY IF EXISTS "admin_delete_event_tickets" ON event_tickets;

CREATE POLICY "admin_select_open_mics" ON open_mics FOR SELECT TO authenticated
  USING ((auth.jwt() -> 'app_metadata' ->> 'role') = 'admin');
CREATE POLICY "admin_insert_open_mics" ON open_mics FOR INSERT TO authenticated
  WITH CHECK ((auth.jwt() -> 'app_metadata' ->> 'role') = 'admin');
CREATE POLICY "admin_update_open_mics" ON open_mics FOR UPDATE TO authenticated
  USING ((auth.jwt() -> 'app_metadata' ->> 'role') = 'admin')
  WITH CHECK ((auth.jwt() -> 'app_metadata' ->> 'role') = 'admin');
CREATE POLICY "admin_delete_open_mics" ON open_mics FOR DELETE TO authenticated
  USING ((auth.jwt() -> 'app_metadata' ->> 'role') = 'admin');

CREATE POLICY "admin_select_events" ON events FOR SELECT TO authenticated
  USING ((auth.jwt() -> 'app_metadata' ->> 'role') = 'admin');
CREATE POLICY "admin_insert_events" ON events FOR INSERT TO authenticated
  WITH CHECK ((auth.jwt() -> 'app_metadata' ->> 'role') = 'admin');
CREATE POLICY "admin_update_events" ON events FOR UPDATE TO authenticated
  USING ((auth.jwt() -> 'app_metadata' ->> 'role') = 'admin')
  WITH CHECK ((auth.jwt() -> 'app_metadata' ->> 'role') = 'admin');
CREATE POLICY "admin_delete_events" ON events FOR DELETE TO authenticated
  USING ((auth.jwt() -> 'app_metadata' ->> 'role') = 'admin');

CREATE POLICY "admin_select_event_tickets" ON event_tickets FOR SELECT TO authenticated
  USING ((auth.jwt() -> 'app_metadata' ->> 'role') = 'admin');
CREATE POLICY "admin_insert_event_tickets" ON event_tickets FOR INSERT TO authenticated
  WITH CHECK ((auth.jwt() -> 'app_metadata' ->> 'role') = 'admin');
CREATE POLICY "admin_update_event_tickets" ON event_tickets FOR UPDATE TO authenticated
  USING ((auth.jwt() -> 'app_metadata' ->> 'role') = 'admin')
  WITH CHECK ((auth.jwt() -> 'app_metadata' ->> 'role') = 'admin');
CREATE POLICY "admin_delete_event_tickets" ON event_tickets FOR DELETE TO authenticated
  USING ((auth.jwt() -> 'app_metadata' ->> 'role') = 'admin');

CREATE POLICY "admin_select_komika" ON komika FOR SELECT TO authenticated
  USING ((auth.jwt() -> 'app_metadata' ->> 'role') = 'admin');
CREATE POLICY "admin_insert_komika" ON komika FOR INSERT TO authenticated
  WITH CHECK ((auth.jwt() -> 'app_metadata' ->> 'role') = 'admin');
CREATE POLICY "admin_update_komika" ON komika FOR UPDATE TO authenticated
  USING ((auth.jwt() -> 'app_metadata' ->> 'role') = 'admin')
  WITH CHECK ((auth.jwt() -> 'app_metadata' ->> 'role') = 'admin');
CREATE POLICY "admin_delete_komika" ON komika FOR DELETE TO authenticated
  USING ((auth.jwt() -> 'app_metadata' ->> 'role') = 'admin');

CREATE POLICY "admin_select_site_settings" ON site_settings FOR SELECT TO authenticated
  USING ((auth.jwt() -> 'app_metadata' ->> 'role') = 'admin');
CREATE POLICY "admin_update_site_settings" ON site_settings FOR UPDATE TO authenticated
  USING ((auth.jwt() -> 'app_metadata' ->> 'role') = 'admin')
  WITH CHECK ((auth.jwt() -> 'app_metadata' ->> 'role') = 'admin');

CREATE OR REPLACE FUNCTION public.prevent_member_komika_protected_changes()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF (auth.jwt() -> 'app_metadata' ->> 'role') IS DISTINCT FROM 'admin' THEN
    IF NEW.id IS DISTINCT FROM OLD.id
      OR NEW.user_id IS DISTINCT FROM OLD.user_id
      OR NEW.full_name IS DISTINCT FROM OLD.full_name
      OR NEW.slug IS DISTINCT FROM OLD.slug
      OR NEW.specialties IS DISTINCT FROM OLD.specialties
      OR NEW.joined_at IS DISTINCT FROM OLD.joined_at
      OR NEW.featured_order IS DISTINCT FROM OLD.featured_order
      OR NEW.status IS DISTINCT FROM OLD.status
      OR NEW.published IS DISTINCT FROM OLD.published
      OR NEW.created_at IS DISTINCT FROM OLD.created_at
    THEN
      RAISE EXCEPTION 'Member hanya dapat mengubah data profil publik yang diizinkan';
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS protect_member_komika_fields ON komika;
CREATE TRIGGER protect_member_komika_fields
  BEFORE UPDATE ON komika
  FOR EACH ROW
  EXECUTE FUNCTION public.prevent_member_komika_protected_changes();


-- Source migration: 20260915120000_close_authenticated_public_registration.sql
CREATE OR REPLACE FUNCTION public.jwt_has_role(required_role text)
RETURNS boolean
LANGUAGE sql
STABLE
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM jsonb_array_elements_text(
      CASE
        WHEN jsonb_typeof(auth.jwt() -> 'app_metadata' -> 'roles') = 'array' THEN auth.jwt() -> 'app_metadata' -> 'roles'
        WHEN jsonb_typeof(auth.jwt() -> 'app_metadata' -> 'user_roles') = 'array' THEN auth.jwt() -> 'app_metadata' -> 'user_roles'
        ELSE jsonb_build_array(auth.jwt() -> 'app_metadata' ->> 'role')
      END
    ) AS role_value
    WHERE lower(trim(role_value)) = lower(trim(required_role))
  );
$$;

DROP POLICY IF EXISTS "public_insert_registrations" ON open_mic_registrations;
CREATE POLICY "public_insert_registrations" ON open_mic_registrations
  FOR INSERT TO anon
  WITH CHECK (
    status = 'pending'
    AND komika_id IS NULL
    AND EXISTS (
      SELECT 1 FROM open_mics
      WHERE open_mics.id = open_mic_registrations.open_mic_id
        AND open_mics.published = true
        AND open_mics.status = 'upcoming'
        AND open_mics.registration_status = 'open'
    )
  );

DROP POLICY IF EXISTS "admin_select_registrations" ON open_mic_registrations;
DROP POLICY IF EXISTS "admin_insert_registrations" ON open_mic_registrations;
DROP POLICY IF EXISTS "admin_update_registrations" ON open_mic_registrations;
DROP POLICY IF EXISTS "admin_delete_registrations" ON open_mic_registrations;
CREATE POLICY "admin_select_registrations" ON open_mic_registrations FOR SELECT TO authenticated USING (public.jwt_has_role('admin'));
CREATE POLICY "admin_insert_registrations" ON open_mic_registrations FOR INSERT TO authenticated WITH CHECK (public.jwt_has_role('admin'));
CREATE POLICY "admin_update_registrations" ON open_mic_registrations FOR UPDATE TO authenticated USING (public.jwt_has_role('admin')) WITH CHECK (public.jwt_has_role('admin'));
CREATE POLICY "admin_delete_registrations" ON open_mic_registrations FOR DELETE TO authenticated USING (public.jwt_has_role('admin'));

DROP POLICY IF EXISTS "public_read_confirmed_registrations" ON open_mic_registrations;
CREATE POLICY "public_read_confirmed_registrations" ON open_mic_registrations
  FOR SELECT TO anon
  USING (status = 'confirmed');

DROP POLICY IF EXISTS "member_read_own_open_mic_registrations" ON open_mic_registrations;
CREATE POLICY "member_read_own_open_mic_registrations" ON open_mic_registrations
  FOR SELECT TO authenticated
  USING (
    public.jwt_has_role('admin')
    OR EXISTS (
      SELECT 1 FROM komika k
      WHERE k.id = open_mic_registrations.komika_id
        AND k.user_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "member_insert_own_open_mic_registration" ON open_mic_registrations;
CREATE POLICY "member_insert_own_open_mic_registration" ON open_mic_registrations
  FOR INSERT TO authenticated
  WITH CHECK (
    status = 'pending'
    AND EXISTS (
      SELECT 1 FROM komika k
      WHERE k.id = open_mic_registrations.komika_id
        AND k.user_id = auth.uid()
    )
  );

CREATE OR REPLACE FUNCTION public.prevent_member_komika_protected_changes()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT public.jwt_has_role('admin') THEN
    IF NEW.id IS DISTINCT FROM OLD.id
      OR NEW.user_id IS DISTINCT FROM OLD.user_id
      OR NEW.full_name IS DISTINCT FROM OLD.full_name
      OR NEW.slug IS DISTINCT FROM OLD.slug
      OR NEW.specialties IS DISTINCT FROM OLD.specialties
      OR NEW.joined_at IS DISTINCT FROM OLD.joined_at
      OR NEW.featured_order IS DISTINCT FROM OLD.featured_order
      OR NEW.status IS DISTINCT FROM OLD.status
      OR NEW.published IS DISTINCT FROM OLD.published
      OR NEW.created_at IS DISTINCT FROM OLD.created_at
    THEN
      RAISE EXCEPTION 'Member hanya dapat mengubah data profil publik yang diizinkan';
    END IF;
  END IF;
  RETURN NEW;
END;
$$;


-- Source migration: 20260915130000_support_global_evaluator_assignments.sql
ALTER TABLE evaluator_assignments
  ALTER COLUMN open_mic_id DROP NOT NULL;

-- Source migration: 20260915140000_allow_global_evaluator_assignments.sql
DROP POLICY IF EXISTS "evaluator_manage_own_evaluations" ON evaluations;
CREATE POLICY "evaluator_manage_own_evaluations" ON evaluations
  FOR INSERT TO authenticated
  WITH CHECK (
    evaluator_user_id = auth.uid()
    AND EXISTS (
      SELECT 1
      FROM evaluator_assignments ea
      WHERE (ea.open_mic_id = evaluations.open_mic_id OR ea.open_mic_id IS NULL)
        AND ea.evaluator_user_id = auth.uid()
        AND ea.status = 'active'
    )
    AND EXISTS (
      SELECT 1
      FROM open_mic_registrations r
      WHERE r.id = evaluations.performer_registration_id
        AND r.open_mic_id = evaluations.open_mic_id
    )
  );

DROP POLICY IF EXISTS "evaluator_update_own_evaluations" ON evaluations;
CREATE POLICY "evaluator_update_own_evaluations" ON evaluations
  FOR UPDATE TO authenticated
  USING (
    evaluator_user_id = auth.uid()
    AND evaluations.status = 'draft'
    AND EXISTS (
      SELECT 1
      FROM evaluator_assignments ea
      WHERE (ea.open_mic_id = evaluations.open_mic_id OR ea.open_mic_id IS NULL)
        AND ea.evaluator_user_id = auth.uid()
        AND ea.status = 'active'
    )
  )
  WITH CHECK (
    evaluator_user_id = auth.uid()
    AND evaluations.status = 'draft'
    AND EXISTS (
      SELECT 1
      FROM evaluator_assignments ea
      WHERE (ea.open_mic_id = evaluations.open_mic_id OR ea.open_mic_id IS NULL)
        AND ea.evaluator_user_id = auth.uid()
        AND ea.status = 'active'
    )
  );

-- Source migration: 20260915150000_member_read_evaluations_by_profile.sql
DROP POLICY IF EXISTS "member_read_own_evaluations" ON evaluations;
CREATE POLICY "member_read_own_evaluations" ON evaluations
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1
      FROM komika k
      WHERE k.id = evaluations.performer_komika_id
        AND k.user_id = auth.uid()
    )
    OR EXISTS (
      SELECT 1
      FROM open_mic_registrations r
      JOIN komika k ON k.id = r.komika_id
      WHERE r.id = evaluations.performer_registration_id
        AND (k.user_id = auth.uid() OR k.id = auth.uid())
    )
    OR (auth.jwt() -> 'app_metadata' ->> 'role') = 'admin'
  );

-- Source migration: 20260916100000_add_operational_admin_roles.sql
-- Operational admin roles share the existing Admin login but receive scoped database access.
-- Keep this migration safe to run independently from the SQL Editor as well as via db push.

CREATE OR REPLACE FUNCTION public.jwt_has_role(required_role text)
RETURNS boolean
LANGUAGE sql
STABLE
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM jsonb_array_elements_text(
      CASE
        WHEN jsonb_typeof(auth.jwt() -> 'app_metadata' -> 'roles') = 'array' THEN auth.jwt() -> 'app_metadata' -> 'roles'
        WHEN jsonb_typeof(auth.jwt() -> 'app_metadata' -> 'user_roles') = 'array' THEN auth.jwt() -> 'app_metadata' -> 'user_roles'
        ELSE jsonb_build_array(auth.jwt() -> 'app_metadata' ->> 'role')
      END
    ) AS role_value
    WHERE lower(trim(role_value)) = lower(trim(required_role))
  );
$$;

DROP POLICY IF EXISTS "admin_select_open_mics" ON open_mics;
DROP POLICY IF EXISTS "admin_insert_open_mics" ON open_mics;
DROP POLICY IF EXISTS "admin_update_open_mics" ON open_mics;
DROP POLICY IF EXISTS "admin_delete_open_mics" ON open_mics;
DROP POLICY IF EXISTS "operational_admin_select_open_mics" ON open_mics;
DROP POLICY IF EXISTS "operational_admin_insert_open_mics" ON open_mics;
DROP POLICY IF EXISTS "operational_admin_update_open_mics" ON open_mics;
DROP POLICY IF EXISTS "operational_admin_delete_open_mics" ON open_mics;
CREATE POLICY "operational_admin_select_open_mics" ON open_mics FOR SELECT TO authenticated
  USING (public.jwt_has_role('admin') OR public.jwt_has_role('open_mic_admin'));
CREATE POLICY "operational_admin_insert_open_mics" ON open_mics FOR INSERT TO authenticated
  WITH CHECK (public.jwt_has_role('admin') OR public.jwt_has_role('open_mic_admin'));
CREATE POLICY "operational_admin_update_open_mics" ON open_mics FOR UPDATE TO authenticated
  USING (public.jwt_has_role('admin') OR public.jwt_has_role('open_mic_admin'))
  WITH CHECK (public.jwt_has_role('admin') OR public.jwt_has_role('open_mic_admin'));
CREATE POLICY "operational_admin_delete_open_mics" ON open_mics FOR DELETE TO authenticated
  USING (public.jwt_has_role('admin') OR public.jwt_has_role('open_mic_admin'));

DROP POLICY IF EXISTS "admin_select_events" ON events;
DROP POLICY IF EXISTS "admin_insert_events" ON events;
DROP POLICY IF EXISTS "admin_update_events" ON events;
DROP POLICY IF EXISTS "admin_delete_events" ON events;
DROP POLICY IF EXISTS "operational_admin_select_events" ON events;
DROP POLICY IF EXISTS "operational_admin_insert_events" ON events;
DROP POLICY IF EXISTS "operational_admin_update_events" ON events;
DROP POLICY IF EXISTS "operational_admin_delete_events" ON events;
CREATE POLICY "operational_admin_select_events" ON events FOR SELECT TO authenticated
  USING (public.jwt_has_role('admin') OR public.jwt_has_role('event_admin'));
CREATE POLICY "operational_admin_insert_events" ON events FOR INSERT TO authenticated
  WITH CHECK (public.jwt_has_role('admin') OR public.jwt_has_role('event_admin'));
CREATE POLICY "operational_admin_update_events" ON events FOR UPDATE TO authenticated
  USING (public.jwt_has_role('admin') OR public.jwt_has_role('event_admin'))
  WITH CHECK (public.jwt_has_role('admin') OR public.jwt_has_role('event_admin'));
CREATE POLICY "operational_admin_delete_events" ON events FOR DELETE TO authenticated
  USING (public.jwt_has_role('admin') OR public.jwt_has_role('event_admin'));

DROP POLICY IF EXISTS "admin_select_event_tickets" ON event_tickets;
DROP POLICY IF EXISTS "admin_insert_event_tickets" ON event_tickets;
DROP POLICY IF EXISTS "admin_update_event_tickets" ON event_tickets;
DROP POLICY IF EXISTS "admin_delete_event_tickets" ON event_tickets;
DROP POLICY IF EXISTS "operational_admin_select_event_tickets" ON event_tickets;
DROP POLICY IF EXISTS "operational_admin_insert_event_tickets" ON event_tickets;
DROP POLICY IF EXISTS "operational_admin_update_event_tickets" ON event_tickets;
DROP POLICY IF EXISTS "operational_admin_delete_event_tickets" ON event_tickets;
CREATE POLICY "operational_admin_select_event_tickets" ON event_tickets FOR SELECT TO authenticated
  USING (public.jwt_has_role('admin') OR public.jwt_has_role('event_admin'));
CREATE POLICY "operational_admin_insert_event_tickets" ON event_tickets FOR INSERT TO authenticated
  WITH CHECK (public.jwt_has_role('admin') OR public.jwt_has_role('event_admin'));
CREATE POLICY "operational_admin_update_event_tickets" ON event_tickets FOR UPDATE TO authenticated
  USING (public.jwt_has_role('admin') OR public.jwt_has_role('event_admin'))
  WITH CHECK (public.jwt_has_role('admin') OR public.jwt_has_role('event_admin'));
CREATE POLICY "operational_admin_delete_event_tickets" ON event_tickets FOR DELETE TO authenticated
  USING (public.jwt_has_role('admin') OR public.jwt_has_role('event_admin'));

DROP POLICY IF EXISTS "admin_select_registrations" ON open_mic_registrations;
DROP POLICY IF EXISTS "admin_insert_registrations" ON open_mic_registrations;
DROP POLICY IF EXISTS "admin_update_registrations" ON open_mic_registrations;
DROP POLICY IF EXISTS "admin_delete_registrations" ON open_mic_registrations;
DROP POLICY IF EXISTS "operational_admin_select_registrations" ON open_mic_registrations;
DROP POLICY IF EXISTS "operational_admin_insert_registrations" ON open_mic_registrations;
DROP POLICY IF EXISTS "operational_admin_update_registrations" ON open_mic_registrations;
DROP POLICY IF EXISTS "operational_admin_delete_registrations" ON open_mic_registrations;
CREATE POLICY "operational_admin_select_registrations" ON open_mic_registrations FOR SELECT TO authenticated
  USING (public.jwt_has_role('admin') OR public.jwt_has_role('open_mic_admin'));
CREATE POLICY "operational_admin_insert_registrations" ON open_mic_registrations FOR INSERT TO authenticated
  WITH CHECK (public.jwt_has_role('admin') OR public.jwt_has_role('open_mic_admin'));
CREATE POLICY "operational_admin_update_registrations" ON open_mic_registrations FOR UPDATE TO authenticated
  USING (public.jwt_has_role('admin') OR public.jwt_has_role('open_mic_admin'))
  WITH CHECK (public.jwt_has_role('admin') OR public.jwt_has_role('open_mic_admin'));
CREATE POLICY "operational_admin_delete_registrations" ON open_mic_registrations FOR DELETE TO authenticated
  USING (public.jwt_has_role('admin') OR public.jwt_has_role('open_mic_admin'));

DROP POLICY IF EXISTS "admin_select_event_participants" ON event_participants;
DROP POLICY IF EXISTS "admin_update_event_participants" ON event_participants;
DROP POLICY IF EXISTS "admin_delete_event_participants" ON event_participants;
DROP POLICY IF EXISTS "operational_admin_select_event_participants" ON event_participants;
DROP POLICY IF EXISTS "operational_admin_update_event_participants" ON event_participants;
DROP POLICY IF EXISTS "operational_admin_delete_event_participants" ON event_participants;
CREATE POLICY "operational_admin_select_event_participants" ON event_participants FOR SELECT TO authenticated
  USING (public.jwt_has_role('admin') OR public.jwt_has_role('event_admin'));
CREATE POLICY "operational_admin_update_event_participants" ON event_participants FOR UPDATE TO authenticated
  USING (public.jwt_has_role('admin') OR public.jwt_has_role('event_admin'))
  WITH CHECK (public.jwt_has_role('admin') OR public.jwt_has_role('event_admin'));
CREATE POLICY "operational_admin_delete_event_participants" ON event_participants FOR DELETE TO authenticated
  USING (public.jwt_has_role('admin') OR public.jwt_has_role('event_admin'));

DROP POLICY IF EXISTS "admin_read_ticket_orders" ON public.ticket_orders;
DROP POLICY IF EXISTS "admin_update_ticket_orders" ON public.ticket_orders;
DROP POLICY IF EXISTS "admin_delete_ticket_orders" ON public.ticket_orders;
DROP POLICY IF EXISTS "operational_admin_read_ticket_orders" ON public.ticket_orders;
DROP POLICY IF EXISTS "operational_admin_update_ticket_orders" ON public.ticket_orders;
DROP POLICY IF EXISTS "operational_admin_delete_ticket_orders" ON public.ticket_orders;
CREATE POLICY "operational_admin_read_ticket_orders" ON public.ticket_orders FOR SELECT TO authenticated
  USING (public.jwt_has_role('admin') OR public.jwt_has_role('event_admin'));
CREATE POLICY "operational_admin_update_ticket_orders" ON public.ticket_orders FOR UPDATE TO authenticated
  USING (public.jwt_has_role('admin') OR public.jwt_has_role('event_admin'))
  WITH CHECK (public.jwt_has_role('admin') OR public.jwt_has_role('event_admin'));
CREATE POLICY "operational_admin_delete_ticket_orders" ON public.ticket_orders FOR DELETE TO authenticated
  USING (public.jwt_has_role('admin') OR public.jwt_has_role('event_admin'));

DROP POLICY IF EXISTS "admin_select_community_applications" ON community_applications;
DROP POLICY IF EXISTS "admin_update_community_applications" ON community_applications;
DROP POLICY IF EXISTS "admin_delete_community_applications" ON community_applications;
CREATE POLICY "admin_select_community_applications" ON community_applications FOR SELECT TO authenticated USING (public.jwt_has_role('admin'));
CREATE POLICY "admin_update_community_applications" ON community_applications FOR UPDATE TO authenticated USING (public.jwt_has_role('admin')) WITH CHECK (public.jwt_has_role('admin'));
CREATE POLICY "admin_delete_community_applications" ON community_applications FOR DELETE TO authenticated USING (public.jwt_has_role('admin'));

DROP POLICY IF EXISTS "admin_manage_partners" ON public.partners;
DROP POLICY IF EXISTS "operational_admin_manage_partners" ON public.partners;
CREATE POLICY "operational_admin_manage_partners" ON public.partners FOR ALL TO authenticated
  USING (public.jwt_has_role('admin') OR public.jwt_has_role('event_admin'))
  WITH CHECK (public.jwt_has_role('admin') OR public.jwt_has_role('event_admin'));

DROP POLICY IF EXISTS "admin_manage_event_partnerships" ON public.event_partnerships;
DROP POLICY IF EXISTS "operational_admin_manage_event_partnerships" ON public.event_partnerships;
CREATE POLICY "operational_admin_manage_event_partnerships" ON public.event_partnerships FOR ALL TO authenticated
  USING (public.jwt_has_role('admin') OR public.jwt_has_role('event_admin'))
  WITH CHECK (public.jwt_has_role('admin') OR public.jwt_has_role('event_admin'));


-- Source migration: 20260917100000_register_member_open_mic_rpc.sql
CREATE OR REPLACE FUNCTION public.register_member_open_mic(
  p_open_mic_id uuid,
  p_notes text DEFAULT NULL
)
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  member_record komika%ROWTYPE;
  mic_record open_mics%ROWTYPE;
  next_number bigint;
  registration_code text;
  mic_number text;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Akun member wajib login';
  END IF;

  SELECT * INTO member_record
  FROM komika
  WHERE user_id = auth.uid()
  LIMIT 1;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Profil member belum tersedia';
  END IF;

  SELECT * INTO mic_record
  FROM open_mics
  WHERE id = p_open_mic_id
    AND published = true
    AND status = 'upcoming'
    AND registration_status = 'open';

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Pendaftaran Open Mic sudah ditutup';
  END IF;

  IF EXISTS (
    SELECT 1
    FROM open_mic_registrations
    WHERE open_mic_id = p_open_mic_id
      AND komika_id = member_record.id
      AND status IN ('pending', 'confirmed')
  ) THEN
    RAISE EXCEPTION 'Kamu sudah terdaftar di Open Mic ini';
  END IF;

  next_number := nextval('open_mic_reg_seq');
  mic_number := COALESCE((regexp_match(mic_record.title, '#?([0-9]+)'))[1], '00');
  registration_code := 'OM' || mic_number || '-' || lpad(next_number::text, 4, '0');

  INSERT INTO open_mic_registrations (
    registration_id,
    open_mic_id,
    full_name,
    stage_name,
    community,
    instagram,
    whatsapp,
    notes,
    komika_id,
    status,
    attendance_status
  ) VALUES (
    registration_code,
    mic_record.id,
    member_record.full_name,
    member_record.stage_name,
    'Standupindo Serang',
    member_record.instagram_url,
    member_record.whatsapp,
    NULLIF(trim(p_notes), ''),
    member_record.id,
    'pending',
    'unmarked'
  );

  RETURN registration_code;
END;
$$;

REVOKE ALL ON FUNCTION public.register_member_open_mic(uuid, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.register_member_open_mic(uuid, text) TO authenticated;

-- Source migration: 20260917110000_prevent_duplicate_member_open_mic_registration.sql
CREATE UNIQUE INDEX IF NOT EXISTS uq_open_mic_registrations_active_member
  ON open_mic_registrations (open_mic_id, komika_id)
  WHERE komika_id IS NOT NULL
    AND status IN ('pending', 'confirmed');


-- Source migration: 20260917120000_register_public_open_mic_rpc.sql
CREATE OR REPLACE FUNCTION public.register_public_open_mic(
  p_open_mic_id uuid,
  p_full_name text,
  p_stage_name text,
  p_community text DEFAULT NULL,
  p_instagram text DEFAULT NULL,
  p_whatsapp text DEFAULT NULL,
  p_notes text DEFAULT NULL
)
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  mic_record open_mics%ROWTYPE;
  next_number bigint;
  registration_code text;
  mic_number text;
  normalized_whatsapp text;
  normalized_instagram text;
BEGIN
  IF NULLIF(trim(p_full_name), '') IS NULL OR NULLIF(trim(p_stage_name), '') IS NULL THEN
    RAISE EXCEPTION 'Nama lengkap dan nama panggung wajib diisi';
  END IF;

  SELECT * INTO mic_record
  FROM open_mics
  WHERE id = p_open_mic_id
    AND published = true
    AND status = 'upcoming'
    AND registration_status = 'open';

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Pendaftaran Open Mic sudah ditutup';
  END IF;

  normalized_whatsapp := NULLIF(regexp_replace(trim(COALESCE(p_whatsapp, '')), '[^0-9]', '', 'g'), '');
  normalized_instagram := NULLIF(lower(trim(COALESCE(p_instagram, ''))), '');

  IF EXISTS (
    SELECT 1
    FROM open_mic_registrations
    WHERE open_mic_id = p_open_mic_id
      AND status IN ('pending', 'confirmed')
      AND lower(trim(full_name)) = lower(trim(p_full_name))
      AND lower(trim(stage_name)) = lower(trim(p_stage_name))
      AND (
        (normalized_whatsapp IS NOT NULL AND regexp_replace(COALESCE(whatsapp, ''), '[^0-9]', '', 'g') = normalized_whatsapp)
        OR (normalized_instagram IS NOT NULL AND lower(trim(COALESCE(instagram, ''))) = normalized_instagram)
        OR (normalized_whatsapp IS NULL AND normalized_instagram IS NULL AND whatsapp IS NULL AND instagram IS NULL)
      )
  ) THEN
    RAISE EXCEPTION 'Kamu sudah terdaftar di Open Mic ini';
  END IF;

  next_number := nextval('open_mic_reg_seq');
  mic_number := COALESCE((regexp_match(mic_record.title, '#?([0-9]+)'))[1], '00');
  registration_code := 'OM' || mic_number || '-' || lpad(next_number::text, 4, '0');

  INSERT INTO open_mic_registrations (
    registration_id,
    open_mic_id,
    full_name,
    stage_name,
    community,
    instagram,
    whatsapp,
    notes,
    komika_id,
    status,
    attendance_status
  ) VALUES (
    registration_code,
    mic_record.id,
    trim(p_full_name),
    trim(p_stage_name),
    NULLIF(trim(p_community), ''),
    NULLIF(trim(p_instagram), ''),
    NULLIF(trim(p_whatsapp), ''),
    NULLIF(trim(p_notes), ''),
    NULL,
    'pending',
    'unmarked'
  );

  RETURN registration_code;
END;
$$;

REVOKE ALL ON FUNCTION public.register_public_open_mic(uuid, text, text, text, text, text, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.register_public_open_mic(uuid, text, text, text, text, text, text) TO anon, authenticated;

CREATE UNIQUE INDEX IF NOT EXISTS uq_open_mic_registrations_active_identity
  ON open_mic_registrations (
    open_mic_id,
    lower(trim(full_name)),
    lower(trim(stage_name)),
    COALESCE(regexp_replace(whatsapp, '[^0-9]', '', 'g'), ''),
    COALESCE(lower(trim(instagram)), '')
  )
  WHERE status IN ('pending', 'confirmed');


-- Source migration: 20260917130000_allow_open_mic_admin_read_komika.sql
DROP POLICY IF EXISTS "operational_admin_select_komika" ON komika;
CREATE POLICY "operational_admin_select_komika" ON komika
  FOR SELECT TO authenticated
  USING (public.jwt_has_role('admin') OR public.jwt_has_role('open_mic_admin'));


-- Source migration: 20260918000000_add_member_notification_reads.sql
CREATE TABLE IF NOT EXISTS member_notification_reads (
  user_id uuid NOT NULL,
  notification_key text NOT NULL,
  read_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, notification_key)
);

ALTER TABLE member_notification_reads ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "member_manage_own_notification_reads" ON member_notification_reads;
CREATE POLICY "member_manage_own_notification_reads" ON member_notification_reads
  FOR ALL TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());


-- Source migration: 20260921150000_allow_open_mic_admin_manage_evaluator_assignments.sql
-- Allow the Open Mic operational admin to manage evaluator assignments
-- without granting access to the full Admin workspace.

DROP POLICY IF EXISTS "open_mic_admin_manage_evaluator_assignments" ON evaluator_assignments;
CREATE POLICY "open_mic_admin_manage_evaluator_assignments" ON evaluator_assignments
  FOR ALL TO authenticated
  USING (public.jwt_has_role('admin') OR public.jwt_has_role('open_mic_admin'))
  WITH CHECK (public.jwt_has_role('admin') OR public.jwt_has_role('open_mic_admin'));


-- Source migration: 20260921152000_add_karya_url_to_komika.sql
ALTER TABLE public.komika
  ADD COLUMN IF NOT EXISTS karya_url text;


-- Source migration: 20260921153000_create_private_materials.sql
CREATE TABLE IF NOT EXISTS public.materials (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  title text NOT NULL,
  theme text NOT NULL,
  estimated_duration integer NOT NULL CHECK (estimated_duration > 0),
  content text NOT NULL,
  previous_content text,
  previous_updated_at timestamptz,
  rating integer CHECK (rating IS NULL OR (rating BETWEEN 1 AND 5)),
  personal_note text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.materials ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "members_manage_own_materials" ON public.materials;
CREATE POLICY "members_manage_own_materials"
  ON public.materials
  FOR ALL
  TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

CREATE INDEX IF NOT EXISTS idx_materials_user_updated
  ON public.materials(user_id, updated_at DESC);


-- Source migration: 20260921154000_create_private_material_nodes.sql
CREATE TABLE IF NOT EXISTS public.material_nodes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  material_id uuid NOT NULL REFERENCES public.materials(id) ON DELETE CASCADE,
  parent_id uuid REFERENCES public.material_nodes(id) ON DELETE CASCADE,
  type text NOT NULL DEFAULT 'Ide',
  title text NOT NULL,
  content text,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.material_nodes ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "members_manage_own_material_nodes" ON public.material_nodes;
CREATE POLICY "members_manage_own_material_nodes"
  ON public.material_nodes
  FOR ALL
  TO authenticated
  USING (EXISTS (
    SELECT 1 FROM public.materials
    WHERE materials.id = material_nodes.material_id
      AND materials.user_id = auth.uid()
  ))
  WITH CHECK (EXISTS (
    SELECT 1 FROM public.materials
    WHERE materials.id = material_nodes.material_id
      AND materials.user_id = auth.uid()
  ));

CREATE INDEX IF NOT EXISTS idx_material_nodes_material_parent
  ON public.material_nodes(material_id, parent_id, sort_order);


-- Source migration: 20260921155000_create_private_material_setlists.sql
CREATE TABLE IF NOT EXISTS public.material_setlists (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.material_setlist_items (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  setlist_id uuid NOT NULL REFERENCES public.material_setlists(id) ON DELETE CASCADE,
  material_id uuid NOT NULL REFERENCES public.materials(id) ON DELETE CASCADE,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (setlist_id, material_id)
);

ALTER TABLE public.material_setlists ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.material_setlist_items ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "members_manage_own_material_setlists" ON public.material_setlists;
CREATE POLICY "members_manage_own_material_setlists"
  ON public.material_setlists
  FOR ALL TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "members_manage_own_material_setlist_items" ON public.material_setlist_items;
CREATE POLICY "members_manage_own_material_setlist_items"
  ON public.material_setlist_items
  FOR ALL TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.material_setlists
      WHERE material_setlists.id = material_setlist_items.setlist_id
        AND material_setlists.user_id = auth.uid()
    )
    AND EXISTS (
      SELECT 1 FROM public.materials
      WHERE materials.id = material_setlist_items.material_id
        AND materials.user_id = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.material_setlists
      WHERE material_setlists.id = material_setlist_items.setlist_id
        AND material_setlists.user_id = auth.uid()
    )
    AND EXISTS (
      SELECT 1 FROM public.materials
      WHERE materials.id = material_setlist_items.material_id
        AND materials.user_id = auth.uid()
    )
  );

CREATE INDEX IF NOT EXISTS idx_material_setlists_user_updated
  ON public.material_setlists(user_id, updated_at DESC);

CREATE INDEX IF NOT EXISTS idx_material_setlist_items_setlist_order
  ON public.material_setlist_items(setlist_id, sort_order);


-- Source migration: 20260921160000_create_member_open_mic_history_submissions.sql
CREATE TABLE IF NOT EXISTS member_open_mic_history_submissions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  komika_id uuid NOT NULL REFERENCES komika(id) ON DELETE CASCADE,
  title text NOT NULL CHECK (char_length(trim(title)) BETWEEN 2 AND 160),
  organizer_name text NOT NULL CHECK (char_length(trim(organizer_name)) BETWEEN 2 AND 160),
  event_date date NOT NULL,
  venue text NOT NULL CHECK (char_length(trim(venue)) BETWEEN 2 AND 160),
  city text,
  notes text,
  proof_url text,
  status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
  admin_note text,
  reviewed_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  reviewed_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT member_open_mic_history_review_fields_consistent
    CHECK ((status = 'pending' AND reviewed_by IS NULL AND reviewed_at IS NULL) OR status IN ('approved', 'rejected'))
);

CREATE INDEX IF NOT EXISTS idx_member_open_mic_history_user_id
  ON member_open_mic_history_submissions(user_id);

CREATE INDEX IF NOT EXISTS idx_member_open_mic_history_komika_id
  ON member_open_mic_history_submissions(komika_id);

CREATE INDEX IF NOT EXISTS idx_member_open_mic_history_status
  ON member_open_mic_history_submissions(status);

CREATE UNIQUE INDEX IF NOT EXISTS uq_member_open_mic_history_duplicate
  ON member_open_mic_history_submissions (
    user_id,
    lower(trim(title)),
    event_date,
    lower(trim(venue))
  );

ALTER TABLE member_open_mic_history_submissions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "member_read_own_open_mic_history" ON member_open_mic_history_submissions;
CREATE POLICY "member_read_own_open_mic_history"
  ON member_open_mic_history_submissions
  FOR SELECT TO authenticated
  USING (
    user_id = auth.uid()
    OR public.jwt_has_role('admin')
    OR public.jwt_has_role('open_mic_admin')
  );

DROP POLICY IF EXISTS "member_insert_own_open_mic_history" ON member_open_mic_history_submissions;
CREATE POLICY "member_insert_own_open_mic_history"
  ON member_open_mic_history_submissions
  FOR INSERT TO authenticated
  WITH CHECK (
    user_id = auth.uid()
    AND status = 'pending'
    AND reviewed_by IS NULL
    AND reviewed_at IS NULL
    AND EXISTS (
      SELECT 1
      FROM komika
      WHERE komika.id = member_open_mic_history_submissions.komika_id
        AND komika.user_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "member_update_pending_open_mic_history" ON member_open_mic_history_submissions;
CREATE POLICY "member_update_pending_open_mic_history"
  ON member_open_mic_history_submissions
  FOR UPDATE TO authenticated
  USING (
    user_id = auth.uid()
    AND status = 'pending'
  )
  WITH CHECK (
    user_id = auth.uid()
    AND status = 'pending'
    AND reviewed_by IS NULL
    AND reviewed_at IS NULL
    AND EXISTS (
      SELECT 1
      FROM komika
      WHERE komika.id = member_open_mic_history_submissions.komika_id
        AND komika.user_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "admin_manage_open_mic_history" ON member_open_mic_history_submissions;
CREATE POLICY "admin_manage_open_mic_history"
  ON member_open_mic_history_submissions
  FOR ALL TO authenticated
  USING (public.jwt_has_role('admin') OR public.jwt_has_role('open_mic_admin'))
  WITH CHECK (public.jwt_has_role('admin') OR public.jwt_has_role('open_mic_admin'));


-- Source migration: 20260921170000_fix_public_open_mic_lineup_access.sql
/*
  Keep the public lineup query limited to confirmed registrations while
  allowing it to read attendance_status for completed Open Mic archives.
*/

DROP POLICY IF EXISTS "public_read_confirmed_registrations" ON public.open_mic_registrations;

CREATE POLICY "public_read_confirmed_registrations"
  ON public.open_mic_registrations
  FOR SELECT
  TO anon, authenticated
  USING (status = 'confirmed');

GRANT SELECT (attendance_status)
  ON public.open_mic_registrations
  TO anon, authenticated;


-- Source migration: 20260922000000_restore_public_komika_read_access.sql
DROP POLICY IF EXISTS "public_read_komika" ON public.komika;

CREATE POLICY "public_read_komika" ON public.komika
  FOR SELECT TO anon, authenticated
  USING (published = true AND status = 'active');


-- Source migration: 20260923100000_allow_members_delete_rejected_open_mic_history.sql
DROP POLICY IF EXISTS "member_delete_rejected_open_mic_history" ON member_open_mic_history_submissions;
CREATE POLICY "member_delete_rejected_open_mic_history"
  ON member_open_mic_history_submissions
  FOR DELETE TO authenticated
  USING (
    user_id = auth.uid()
    AND status = 'rejected'
  );


-- Source migration: 20261001090000_add_material_premis.sql
ALTER TABLE public.materials
  ADD COLUMN IF NOT EXISTS premis text;

-- Source migration: 20261002100000_ticketing_v1_access_foundation.sql
-- Ticketing V1 access foundation. Additive only; do not apply until the
-- production migration ledger and local schema drift have been reconciled.

CREATE TABLE IF NOT EXISTS public.admin_event_scopes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  role text NOT NULL CHECK (role IN ('admin_ticket', 'admin_qr')),
  event_id uuid REFERENCES public.events(id) ON DELETE CASCADE,
  scope_all boolean NOT NULL DEFAULT false,
  granted_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT admin_event_scopes_scope_shape CHECK (
    (scope_all AND event_id IS NULL) OR (NOT scope_all AND event_id IS NOT NULL)
  )
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_admin_event_scopes_all
  ON public.admin_event_scopes(user_id, role)
  WHERE scope_all;

CREATE UNIQUE INDEX IF NOT EXISTS idx_admin_event_scopes_event
  ON public.admin_event_scopes(user_id, role, event_id)
  WHERE NOT scope_all;

CREATE INDEX IF NOT EXISTS idx_admin_event_scopes_event_role
  ON public.admin_event_scopes(event_id, role)
  WHERE event_id IS NOT NULL;

ALTER TABLE public.admin_event_scopes ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "admin_manage_event_scopes" ON public.admin_event_scopes;
CREATE POLICY "admin_manage_event_scopes"
  ON public.admin_event_scopes
  FOR ALL
  TO authenticated
  USING (public.jwt_has_role('admin'))
  WITH CHECK (public.jwt_has_role('admin'));

DROP POLICY IF EXISTS "users_read_own_event_scopes" ON public.admin_event_scopes;
CREATE POLICY "users_read_own_event_scopes"
  ON public.admin_event_scopes
  FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

CREATE OR REPLACE FUNCTION public.user_has_ticket_event_scope(
  target_event_id uuid,
  required_role text
)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT public.jwt_has_role('admin')
    OR EXISTS (
      SELECT 1
      FROM public.admin_event_scopes scope
      WHERE scope.user_id = auth.uid()
        AND scope.role = required_role
        AND (
          scope.scope_all
          OR scope.event_id = target_event_id
        )
        AND public.jwt_has_role(required_role)
    );
$$;

REVOKE ALL ON FUNCTION public.user_has_ticket_event_scope(uuid, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.user_has_ticket_event_scope(uuid, text) TO authenticated;

-- The legacy permissive policy would otherwise OR with role-scoped policies.
DROP POLICY IF EXISTS "admin_all_events" ON public.events;
DROP POLICY IF EXISTS "admin_select_events" ON public.events;
DROP POLICY IF EXISTS "admin_insert_events" ON public.events;
DROP POLICY IF EXISTS "admin_update_events" ON public.events;
DROP POLICY IF EXISTS "admin_delete_events" ON public.events;
DROP POLICY IF EXISTS "operational_admin_select_events" ON public.events;
DROP POLICY IF EXISTS "operational_admin_insert_events" ON public.events;
DROP POLICY IF EXISTS "operational_admin_update_events" ON public.events;
DROP POLICY IF EXISTS "operational_admin_delete_events" ON public.events;
DROP POLICY IF EXISTS "public_read_events" ON public.events;
DROP POLICY IF EXISTS "public_read_published_events_anon" ON public.events;
DROP POLICY IF EXISTS "public_read_published_events_authenticated" ON public.events;

CREATE POLICY "public_read_published_events_anon"
  ON public.events
  FOR SELECT
  TO anon
  USING (published = true);

CREATE POLICY "public_read_published_events_authenticated"
  ON public.events
  FOR SELECT
  TO authenticated
  USING (
    published = true
    AND NOT public.jwt_has_role('admin_ticket')
    AND NOT public.jwt_has_role('admin_qr')
  );

CREATE POLICY "ticketing_select_scoped_events"
  ON public.events
  FOR SELECT
  TO authenticated
  USING (
    public.jwt_has_role('admin')
    OR public.jwt_has_role('event_admin')
    OR public.user_has_ticket_event_scope(id, 'admin_ticket')
    OR public.user_has_ticket_event_scope(id, 'admin_qr')
  );

CREATE POLICY "event_admin_insert_events"
  ON public.events
  FOR INSERT
  TO authenticated
  WITH CHECK (public.jwt_has_role('admin') OR public.jwt_has_role('event_admin'));

CREATE POLICY "event_admin_update_events"
  ON public.events
  FOR UPDATE
  TO authenticated
  USING (public.jwt_has_role('admin') OR public.jwt_has_role('event_admin'))
  WITH CHECK (public.jwt_has_role('admin') OR public.jwt_has_role('event_admin'));

CREATE POLICY "event_admin_delete_events"
  ON public.events
  FOR DELETE
  TO authenticated
  USING (public.jwt_has_role('admin') OR public.jwt_has_role('event_admin'));

-- Ticket/scanner roles can read tiers for assigned Events, but cannot edit tiers.
DROP POLICY IF EXISTS "admin_all_event_tickets" ON public.event_tickets;
DROP POLICY IF EXISTS "admin_select_event_tickets" ON public.event_tickets;
DROP POLICY IF EXISTS "admin_insert_event_tickets" ON public.event_tickets;
DROP POLICY IF EXISTS "admin_update_event_tickets" ON public.event_tickets;
DROP POLICY IF EXISTS "admin_delete_event_tickets" ON public.event_tickets;
DROP POLICY IF EXISTS "operational_admin_select_event_tickets" ON public.event_tickets;
DROP POLICY IF EXISTS "operational_admin_insert_event_tickets" ON public.event_tickets;
DROP POLICY IF EXISTS "operational_admin_update_event_tickets" ON public.event_tickets;
DROP POLICY IF EXISTS "operational_admin_delete_event_tickets" ON public.event_tickets;
DROP POLICY IF EXISTS "public_read_active_event_tickets" ON public.event_tickets;
DROP POLICY IF EXISTS "public_read_active_event_tickets_anon" ON public.event_tickets;
DROP POLICY IF EXISTS "public_read_active_event_tickets_authenticated" ON public.event_tickets;

CREATE POLICY "public_read_active_event_tickets_anon"
  ON public.event_tickets
  FOR SELECT
  TO anon
  USING (status = 'active');

CREATE POLICY "public_read_active_event_tickets_authenticated"
  ON public.event_tickets
  FOR SELECT
  TO authenticated
  USING (
    status = 'active'
    AND NOT public.jwt_has_role('admin_ticket')
    AND NOT public.jwt_has_role('admin_qr')
  );

CREATE POLICY "ticketing_select_scoped_event_tickets"
  ON public.event_tickets
  FOR SELECT
  TO authenticated
  USING (
    public.jwt_has_role('admin')
    OR public.jwt_has_role('event_admin')
    OR public.user_has_ticket_event_scope(event_id, 'admin_ticket')
    OR public.user_has_ticket_event_scope(event_id, 'admin_qr')
  );

CREATE POLICY "event_admin_insert_event_tickets"
  ON public.event_tickets
  FOR INSERT
  TO authenticated
  WITH CHECK (public.jwt_has_role('admin') OR public.jwt_has_role('event_admin'));

CREATE POLICY "event_admin_update_event_tickets"
  ON public.event_tickets
  FOR UPDATE
  TO authenticated
  USING (public.jwt_has_role('admin') OR public.jwt_has_role('event_admin'))
  WITH CHECK (public.jwt_has_role('admin') OR public.jwt_has_role('event_admin'));

CREATE POLICY "event_admin_delete_event_tickets"
  ON public.event_tickets
  FOR DELETE
  TO authenticated
  USING (public.jwt_has_role('admin') OR public.jwt_has_role('event_admin'));

-- Event Admin is audience-read-only. Payment changes belong to Admin Tiket.
DROP POLICY IF EXISTS "admin_read_ticket_orders" ON public.ticket_orders;
DROP POLICY IF EXISTS "admin_update_ticket_orders" ON public.ticket_orders;
DROP POLICY IF EXISTS "admin_delete_ticket_orders" ON public.ticket_orders;
DROP POLICY IF EXISTS "operational_admin_read_ticket_orders" ON public.ticket_orders;
DROP POLICY IF EXISTS "operational_admin_update_ticket_orders" ON public.ticket_orders;
DROP POLICY IF EXISTS "operational_admin_delete_ticket_orders" ON public.ticket_orders;

CREATE POLICY "ticket_admin_read_scoped_ticket_orders"
  ON public.ticket_orders
  FOR SELECT
  TO authenticated
  USING (
    public.jwt_has_role('admin')
    OR public.user_has_ticket_event_scope(event_id, 'admin_ticket')
  );

CREATE POLICY "event_admin_read_paid_audience"
  ON public.ticket_orders
  FOR SELECT
  TO authenticated
  USING (
    public.jwt_has_role('event_admin')
    AND status = 'Lunas'
  );

-- Status changes and deletion are not granted directly to browser clients.
-- Payment review and expiry use service-only RPCs; order history is retained.
DROP POLICY IF EXISTS "ticket_admin_update_scoped_ticket_orders" ON public.ticket_orders;
DROP POLICY IF EXISTS "admin_update_ticket_orders" ON public.ticket_orders;
DROP POLICY IF EXISTS "admin_delete_ticket_orders" ON public.ticket_orders;

CREATE POLICY "admin_delete_ticket_orders"
  ON public.ticket_orders
  FOR DELETE
  TO authenticated
  USING (public.jwt_has_role('admin'));

-- Source migration: 20261002110000_ticketing_v1_core_schema.sql
-- Ticketing V1 data structures. Depends on the access foundation migration.
-- Do not apply until production migration drift is resolved and staging-tested.

ALTER TABLE public.event_tickets
  ADD COLUMN IF NOT EXISTS quota integer;

ALTER TABLE public.event_tickets
  DROP CONSTRAINT IF EXISTS event_tickets_quota_nonnegative;
ALTER TABLE public.event_tickets
  ADD CONSTRAINT event_tickets_quota_nonnegative CHECK (quota IS NULL OR quota >= 0);

CREATE TABLE IF NOT EXISTS public.event_payment_methods (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  event_id uuid NOT NULL REFERENCES public.events(id) ON DELETE RESTRICT,
  recipient_name text NOT NULL,
  bank_name text,
  account_number text,
  qris_storage_path text,
  note text,
  is_active boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT event_payment_methods_destination CHECK (
    nullif(trim(account_number), '') IS NOT NULL
    OR nullif(trim(qris_storage_path), '') IS NOT NULL
  )
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_event_payment_methods_one_active
  ON public.event_payment_methods(event_id)
  WHERE is_active;

CREATE INDEX IF NOT EXISTS idx_event_payment_methods_event
  ON public.event_payment_methods(event_id, is_active);

ALTER TABLE public.ticket_orders
  ADD COLUMN IF NOT EXISTS expires_at timestamptz,
  ADD COLUMN IF NOT EXISTS payment_amount integer,
  ADD COLUMN IF NOT EXISTS payment_proof_path text,
  ADD COLUMN IF NOT EXISTS payment_submitted_at timestamptz,
  ADD COLUMN IF NOT EXISTS payment_method_id uuid REFERENCES public.event_payment_methods(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS payment_method_snapshot jsonb,
  ADD COLUMN IF NOT EXISTS reviewed_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS reviewed_at timestamptz,
  ADD COLUMN IF NOT EXISTS review_note text,
  ADD COLUMN IF NOT EXISTS access_code_id uuid;

ALTER TABLE public.ticket_orders
  DROP CONSTRAINT IF EXISTS ticket_orders_event_id_fkey;
ALTER TABLE public.ticket_orders
  ADD CONSTRAINT ticket_orders_event_id_fkey
  FOREIGN KEY (event_id) REFERENCES public.events(id) ON DELETE RESTRICT;

ALTER TABLE public.ticket_orders
  DROP CONSTRAINT IF EXISTS ticket_orders_payment_amount_nonnegative;
ALTER TABLE public.ticket_orders
  ADD CONSTRAINT ticket_orders_payment_amount_nonnegative
  CHECK (payment_amount IS NULL OR payment_amount >= 0);

ALTER TABLE public.ticket_orders
  DROP CONSTRAINT IF EXISTS ticket_orders_status_check;
ALTER TABLE public.ticket_orders
  ADD CONSTRAINT ticket_orders_status_check CHECK (
    status IN (
      'Menunggu Pembayaran',
      'Menunggu Verifikasi',
      'Lunas',
      'Ditolak',
      'Expired',
      'Sudah Bayar',
      'Terverifikasi',
      'Selesai',
      'Dibatalkan'
    )
  );

CREATE INDEX IF NOT EXISTS idx_ticket_orders_event_status
  ON public.ticket_orders(event_id, status, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_ticket_orders_expiring
  ON public.ticket_orders(expires_at)
  WHERE status IN ('Menunggu Pembayaran', 'Menunggu Verifikasi', 'Sudah Bayar');

CREATE TABLE IF NOT EXISTS public.ticket_access_codes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  event_id uuid NOT NULL REFERENCES public.events(id) ON DELETE RESTRICT,
  whatsapp_normalized text NOT NULL CHECK (whatsapp_normalized ~ '^[0-9]{10,15}$'),
  access_code_hash text NOT NULL UNIQUE,
  whatsapp_code_hash text NOT NULL UNIQUE,
  access_code_ciphertext text NOT NULL,
  status text NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'revoked')),
  last_sent_at timestamptz,
  last_sent_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  send_count integer NOT NULL DEFAULT 0 CHECK (send_count >= 0),
  issued_at timestamptz NOT NULL DEFAULT now(),
  revoked_at timestamptz,
  revoke_reason text CHECK (revoke_reason IS NULL OR revoke_reason IN ('event_completed', 'admin_revoked')),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT ticket_access_codes_revocation_state CHECK (
    (status = 'active' AND revoked_at IS NULL AND revoke_reason IS NULL)
    OR (status = 'revoked' AND revoked_at IS NOT NULL AND revoke_reason IS NOT NULL)
  )
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_ticket_access_codes_active_event_whatsapp
  ON public.ticket_access_codes(event_id, whatsapp_normalized)
  WHERE status = 'active';

CREATE TABLE IF NOT EXISTS public.ticket_access_sessions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  access_code_id uuid NOT NULL REFERENCES public.ticket_access_codes(id) ON DELETE CASCADE,
  session_token_hash text NOT NULL UNIQUE,
  device_tag_hash text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  last_seen_at timestamptz NOT NULL DEFAULT now(),
  idle_expires_at timestamptz NOT NULL,
  revoked_at timestamptz,
  revoke_reason text CHECK (revoke_reason IS NULL OR revoke_reason IN ('logout', 'replaced', 'idle_timeout', 'event_completed', 'admin_revoked')),
  CONSTRAINT ticket_access_sessions_revocation_state CHECK (
    (revoked_at IS NULL AND revoke_reason IS NULL)
    OR (revoked_at IS NOT NULL AND revoke_reason IS NOT NULL)
  )
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_ticket_access_sessions_one_active
  ON public.ticket_access_sessions(access_code_id)
  WHERE revoked_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_ticket_access_sessions_idle_expiry
  ON public.ticket_access_sessions(idle_expires_at)
  WHERE revoked_at IS NULL;

CREATE TABLE IF NOT EXISTS public.ticket_access_login_attempts (
  attempt_key_hash text PRIMARY KEY,
  attempt_count integer NOT NULL DEFAULT 0 CHECK (attempt_count >= 0),
  window_started_at timestamptz NOT NULL DEFAULT now(),
  blocked_until timestamptz,
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.ticket_access_login_attempts ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.ticket_access_login_attempts FROM anon, authenticated;

ALTER TABLE public.ticket_orders
  ADD CONSTRAINT ticket_orders_access_code_id_fkey
  FOREIGN KEY (access_code_id) REFERENCES public.ticket_access_codes(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_ticket_orders_access_code
  ON public.ticket_orders(access_code_id, created_at DESC)
  WHERE access_code_id IS NOT NULL;

CREATE TABLE IF NOT EXISTS public.ticket_instances (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  ticket_order_id uuid NOT NULL REFERENCES public.ticket_orders(id) ON DELETE RESTRICT,
  event_id uuid NOT NULL REFERENCES public.events(id) ON DELETE RESTRICT,
  event_ticket_id uuid REFERENCES public.event_tickets(id) ON DELETE SET NULL,
  sequence_no integer NOT NULL CHECK (sequence_no > 0),
  qr_token_hash text NOT NULL UNIQUE,
  qr_token_ciphertext text NOT NULL,
  status text NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'revoked')),
  issued_at timestamptz NOT NULL DEFAULT now(),
  checked_in_at timestamptz,
  checked_in_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  check_in_source text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (ticket_order_id, sequence_no),
  CONSTRAINT ticket_instances_checkin_pair CHECK (
    (checked_in_at IS NULL AND checked_in_by IS NULL)
    OR (checked_in_at IS NOT NULL AND checked_in_by IS NOT NULL)
  )
);

CREATE INDEX IF NOT EXISTS idx_ticket_instances_event_status
  ON public.ticket_instances(event_id, status, checked_in_at);

CREATE INDEX IF NOT EXISTS idx_ticket_instances_order
  ON public.ticket_instances(ticket_order_id, sequence_no);

CREATE TABLE IF NOT EXISTS public.ticket_maintenance_logs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  event_id uuid NOT NULL REFERENCES public.events(id) ON DELETE RESTRICT,
  ticket_order_id uuid REFERENCES public.ticket_orders(id) ON DELETE SET NULL,
  activity_type text NOT NULL CHECK (activity_type IN ('thanks', 'upcoming_event', 'promo')),
  recipient_name text NOT NULL,
  whatsapp_normalized text NOT NULL CHECK (whatsapp_normalized ~ '^[0-9]{10,15}$'),
  message text NOT NULL,
  delivery_status text NOT NULL DEFAULT 'pending' CHECK (delivery_status IN ('pending', 'sent')),
  sent_at timestamptz,
  sent_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT ticket_maintenance_sent_pair CHECK (
    (delivery_status = 'pending' AND sent_at IS NULL AND sent_by IS NULL)
    OR (delivery_status = 'sent' AND sent_at IS NOT NULL AND sent_by IS NOT NULL)
  )
);

CREATE INDEX IF NOT EXISTS idx_ticket_maintenance_event
  ON public.ticket_maintenance_logs(event_id, created_at DESC);

CREATE TABLE IF NOT EXISTS public.ticket_maintenance_sends (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  maintenance_log_id uuid NOT NULL REFERENCES public.ticket_maintenance_logs(id) ON DELETE CASCADE,
  sent_at timestamptz NOT NULL DEFAULT now(),
  sent_by uuid NOT NULL REFERENCES auth.users(id) ON DELETE RESTRICT
);

CREATE INDEX IF NOT EXISTS idx_ticket_maintenance_sends_log
  ON public.ticket_maintenance_sends(maintenance_log_id, sent_at DESC);

INSERT INTO storage.buckets (id, name, public, allowed_mime_types, file_size_limit)
VALUES (
  'ticket-payment-proofs',
  'ticket-payment-proofs',
  false,
  ARRAY['image/jpeg', 'image/png', 'image/webp'],
  5242880
)
ON CONFLICT (id) DO UPDATE SET
  public = false,
  allowed_mime_types = EXCLUDED.allowed_mime_types,
  file_size_limit = EXCLUDED.file_size_limit;

ALTER TABLE public.event_payment_methods ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ticket_access_codes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ticket_access_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ticket_instances ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ticket_maintenance_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ticket_maintenance_sends ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON public.ticket_access_codes, public.ticket_access_sessions, public.ticket_instances FROM anon, authenticated;
REVOKE ALL ON public.ticket_maintenance_logs FROM anon;

DROP POLICY IF EXISTS "public_read_active_event_payment_methods" ON public.event_payment_methods;
CREATE POLICY "public_read_active_event_payment_methods"
  ON public.event_payment_methods
  FOR SELECT
  TO anon, authenticated
  USING (
    is_active
    AND EXISTS (
      SELECT 1 FROM public.events event
      WHERE event.id = event_id
        AND event.published
        AND event.status = 'upcoming'
    )
    AND (
      auth.role() = 'anon'
      OR (
        NOT public.jwt_has_role('event_admin')
        AND NOT public.jwt_has_role('admin_ticket')
        AND NOT public.jwt_has_role('admin_qr')
      )
    )
  );

DROP POLICY IF EXISTS "ticket_admin_manage_scoped_payment_methods" ON public.event_payment_methods;
CREATE POLICY "ticket_admin_manage_scoped_payment_methods"
  ON public.event_payment_methods
  FOR ALL
  TO authenticated
  USING (
    public.jwt_has_role('admin')
    OR public.user_has_ticket_event_scope(event_id, 'admin_ticket')
  )
  WITH CHECK (
    public.jwt_has_role('admin')
    OR public.user_has_ticket_event_scope(event_id, 'admin_ticket')
  );

DROP POLICY IF EXISTS "admin_manage_ticket_maintenance" ON public.ticket_maintenance_logs;
CREATE POLICY "admin_manage_ticket_maintenance"
  ON public.ticket_maintenance_logs
  FOR ALL
  TO authenticated
  USING (
    public.jwt_has_role('admin')
    OR public.jwt_has_role('event_admin')
  )
  WITH CHECK (
    public.jwt_has_role('admin')
    OR public.jwt_has_role('event_admin')
  );

DROP POLICY IF EXISTS "admin_read_ticket_maintenance_sends" ON public.ticket_maintenance_sends;
CREATE POLICY "admin_read_ticket_maintenance_sends"
  ON public.ticket_maintenance_sends
  FOR SELECT
  TO authenticated
  USING (
    public.jwt_has_role('admin')
    OR EXISTS (
      SELECT 1 FROM public.ticket_maintenance_logs maintenance
      WHERE maintenance.id = maintenance_log_id
        AND (
          public.jwt_has_role('event_admin')
        )
    )
  );

REVOKE ALL ON public.ticket_maintenance_sends FROM anon;

CREATE OR REPLACE FUNCTION public.revoke_ticket_access_on_event_completion()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NEW.status = 'completed' AND OLD.status IS DISTINCT FROM NEW.status THEN
    UPDATE public.ticket_access_codes
    SET status = 'revoked',
        revoked_at = now(),
        revoke_reason = 'event_completed',
        updated_at = now()
    WHERE event_id = NEW.id
      AND status = 'active';

    UPDATE public.ticket_access_sessions session
    SET revoked_at = now(),
        revoke_reason = 'event_completed'
    FROM public.ticket_access_codes access_code
    WHERE session.access_code_id = access_code.id
      AND access_code.event_id = NEW.id
      AND session.revoked_at IS NULL;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS revoke_ticket_access_after_event_completion ON public.events;
CREATE TRIGGER revoke_ticket_access_after_event_completion
  AFTER UPDATE OF status ON public.events
  FOR EACH ROW
  EXECUTE FUNCTION public.revoke_ticket_access_on_event_completion();

-- Source migration: 20261002120000_ticketing_v1_order_rpcs.sql
-- Ticket orders must be created through the atomic RPC so tier quota and the
-- payment-method snapshot cannot be bypassed by a browser client.

CREATE UNIQUE INDEX IF NOT EXISTS idx_ticket_orders_order_number
  ON public.ticket_orders(order_number)
  WHERE order_number IS NOT NULL;

CREATE OR REPLACE FUNCTION public.normalize_ticket_whatsapp(value text)
RETURNS text
LANGUAGE plpgsql
IMMUTABLE
AS $$
DECLARE
  digits text := regexp_replace(coalesce(value, ''), '\D', '', 'g');
BEGIN
  IF digits = '' THEN RETURN ''; END IF;
  IF left(digits, 2) = '62' THEN RETURN '62' || regexp_replace(substr(digits, 3), '^0+', ''); END IF;
  IF left(digits, 1) = '0' THEN RETURN '62' || substr(digits, 2); END IF;
  IF left(digits, 1) = '8' THEN RETURN '62' || digits; END IF;
  RETURN digits;
END;
$$;

CREATE OR REPLACE FUNCTION public.create_ticket_order(
  p_order_number text,
  p_event_id uuid,
  p_ticket_id uuid,
  p_full_name text,
  p_email text,
  p_whatsapp text,
  p_quantity integer,
  p_notes text
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  selected_event public.events%ROWTYPE;
  selected_ticket public.event_tickets%ROWTYPE;
  selected_payment public.event_payment_methods%ROWTYPE;
  normalized_phone text;
  committed_quantity bigint;
  new_order_id uuid := gen_random_uuid();
BEGIN
  IF p_quantity IS NULL OR p_quantity < 1 OR p_quantity > 20 THEN
    RAISE EXCEPTION 'Jumlah tiket harus antara 1 dan 20';
  END IF;
  IF nullif(trim(p_full_name), '') IS NULL THEN
    RAISE EXCEPTION 'Nama pembeli wajib diisi';
  END IF;
  normalized_phone := public.normalize_ticket_whatsapp(p_whatsapp);
  IF length(normalized_phone) < 10 OR length(normalized_phone) > 15 THEN
    RAISE EXCEPTION 'Nomor WhatsApp tidak valid';
  END IF;
  IF p_order_number !~ '^[A-Z]{3}-[A-Z0-9]{6}$' THEN
    RAISE EXCEPTION 'Nomor order tidak valid';
  END IF;

  SELECT * INTO selected_event
  FROM public.events
  WHERE id = p_event_id
    AND published = true
    AND status = 'upcoming'
  FOR SHARE;
  IF NOT FOUND THEN RAISE EXCEPTION 'Event tidak tersedia untuk pemesanan'; END IF;

  PERFORM pg_advisory_xact_lock(hashtextextended(p_ticket_id::text, 0));
  SELECT * INTO selected_ticket
  FROM public.event_tickets
  WHERE id = p_ticket_id
    AND event_id = p_event_id
    AND status = 'active'
  FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'Jenis tiket tidak tersedia'; END IF;

  SELECT * INTO selected_payment
  FROM public.event_payment_methods
  WHERE event_id = p_event_id
    AND is_active = true
  FOR SHARE;
  IF NOT FOUND THEN RAISE EXCEPTION 'Informasi pembayaran Event belum aktif'; END IF;

  UPDATE public.ticket_orders
  SET status = 'Expired', updated_at = now()
  WHERE ticket_id = p_ticket_id
    AND status IN ('Menunggu Pembayaran', 'Menunggu Verifikasi', 'Sudah Bayar')
    AND expires_at IS NOT NULL
    AND expires_at <= now();

  SELECT coalesce(sum(quantity), 0) INTO committed_quantity
  FROM public.ticket_orders
  WHERE ticket_id = p_ticket_id
    AND status IN ('Menunggu Pembayaran', 'Menunggu Verifikasi', 'Sudah Bayar', 'Lunas', 'Terverifikasi', 'Selesai');

  IF selected_ticket.quota IS NOT NULL
    AND committed_quantity + p_quantity > selected_ticket.quota THEN
    RAISE EXCEPTION 'Kuota tiket tidak mencukupi';
  END IF;

  INSERT INTO public.ticket_orders (
    id, order_number, event_id, ticket_id, ticket_category,
    full_name, email, whatsapp, quantity, unit_price, total_price,
    notes, status, expires_at, payment_method_id, payment_method_snapshot
  ) VALUES (
    new_order_id,
    p_order_number,
    p_event_id,
    p_ticket_id,
    selected_ticket.name,
    trim(p_full_name),
    nullif(lower(trim(p_email)), ''),
    normalized_phone,
    p_quantity,
    selected_ticket.price,
    selected_ticket.price * p_quantity,
    nullif(trim(p_notes), ''),
    'Menunggu Pembayaran',
    now() + interval '30 minutes',
    selected_payment.id,
    jsonb_build_object(
      'recipient_name', selected_payment.recipient_name,
      'bank_name', selected_payment.bank_name,
      'account_number', selected_payment.account_number,
      'qris_storage_path', selected_payment.qris_storage_path,
      'note', selected_payment.note
    )
  );

  RETURN new_order_id;
END;
$$;

REVOKE ALL ON FUNCTION public.create_ticket_order(text, uuid, uuid, text, text, text, integer, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.create_ticket_order(text, uuid, uuid, text, text, text, integer, text) TO anon;

-- Public clients may not bypass quota or omit the payment snapshot.
DROP POLICY IF EXISTS "public_insert_ticket_orders" ON public.ticket_orders;

CREATE OR REPLACE FUNCTION public.expire_unpaid_ticket_orders()
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  expired_count integer;
BEGIN
  UPDATE public.ticket_orders
  SET status = 'Expired', updated_at = now()
  WHERE status = 'Menunggu Pembayaran'
    AND expires_at IS NOT NULL
    AND expires_at <= now();
  GET DIAGNOSTICS expired_count = ROW_COUNT;
  RETURN expired_count;
END;
$$;

REVOKE ALL ON FUNCTION public.expire_unpaid_ticket_orders() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.expire_unpaid_ticket_orders() TO service_role;

CREATE OR REPLACE FUNCTION public.expire_ticket_orders_for_events(p_event_ids uuid[])
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  expired_count integer;
BEGIN
  IF auth.role() <> 'service_role' THEN RAISE EXCEPTION 'Operasi harus dipanggil melalui service backend'; END IF;
  UPDATE public.ticket_orders
  SET status = 'Expired', updated_at = now()
  WHERE event_id = ANY(p_event_ids)
    AND status = 'Menunggu Pembayaran'
    AND expires_at IS NOT NULL
    AND expires_at <= now();
  GET DIAGNOSTICS expired_count = ROW_COUNT;
  RETURN expired_count;
END;
$$;

REVOKE ALL ON FUNCTION public.expire_ticket_orders_for_events(uuid[]) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.expire_ticket_orders_for_events(uuid[]) TO service_role;

CREATE EXTENSION IF NOT EXISTS pg_cron;

DO $ticketing_expiry_schedule$
DECLARE
  existing_job_id bigint;
BEGIN
  FOR existing_job_id IN
    SELECT jobid FROM cron.job WHERE jobname = 'ticketing-v1-expire-unpaid-orders'
  LOOP
    PERFORM cron.unschedule(existing_job_id);
  END LOOP;

  PERFORM cron.schedule(
    'ticketing-v1-expire-unpaid-orders',
    '* * * * *',
    'SELECT public.expire_unpaid_ticket_orders();'
  );
END;
$ticketing_expiry_schedule$;

-- Source migration: 20261002130000_ticketing_v1_lifecycle_rpcs.sql
-- Privileged lifecycle operations. Edge Functions authenticate callers,
-- protect encryption keys, and invoke service-only functions below.

CREATE OR REPLACE FUNCTION public.submit_ticket_payment(
  p_order_id uuid,
  p_whatsapp text,
  p_payment_amount integer,
  p_payment_proof_path text
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  selected_order public.ticket_orders%ROWTYPE;
BEGIN
  SELECT * INTO selected_order
  FROM public.ticket_orders
  WHERE id = p_order_id
  FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'Order tidak ditemukan'; END IF;
  IF public.normalize_ticket_whatsapp(p_whatsapp) <> selected_order.whatsapp THEN
    RAISE EXCEPTION 'Nomor WhatsApp tidak sesuai dengan order';
  END IF;
  IF selected_order.status <> 'Menunggu Pembayaran'
    OR selected_order.expires_at IS NULL
    OR selected_order.expires_at <= now() THEN
    RAISE EXCEPTION 'Batas pembayaran order sudah berakhir';
  END IF;
  IF p_payment_amount IS NULL OR p_payment_amount <> selected_order.total_price THEN
    RAISE EXCEPTION 'Nominal pembayaran harus sama dengan total order';
  END IF;
  IF p_payment_proof_path IS NULL
    OR split_part(p_payment_proof_path, '/', 1) <> p_order_id::text THEN
    RAISE EXCEPTION 'Lokasi bukti pembayaran tidak valid';
  END IF;

  UPDATE public.ticket_orders
  SET status = 'Menunggu Verifikasi',
      payment_amount = p_payment_amount,
      payment_proof_path = p_payment_proof_path,
      payment_submitted_at = now(),
      expires_at = NULL,
      updated_at = now()
  WHERE id = p_order_id;
END;
$$;

REVOKE ALL ON FUNCTION public.submit_ticket_payment(uuid, text, integer, text) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.submit_ticket_payment(uuid, text, integer, text) TO service_role;

CREATE OR REPLACE FUNCTION public.resolve_ticket_order_payment(
  p_order_id uuid,
  p_resolution text,
  p_actor_id uuid,
  p_access_code_hash text DEFAULT NULL,
  p_whatsapp_code_hash text DEFAULT NULL,
  p_access_code_ciphertext text DEFAULT NULL,
  p_qr_tokens jsonb DEFAULT '[]'::jsonb
)
RETURNS TABLE (resolved_status text, resolved_access_code_id uuid, issued_ticket_count integer)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  selected_order public.ticket_orders%ROWTYPE;
  normalized_phone text;
  selected_code public.ticket_access_codes%ROWTYPE;
  supplied_token jsonb;
  instance_count integer;
  token_index integer := 0;
BEGIN
  IF p_resolution NOT IN ('Lunas', 'Ditolak') THEN
    RAISE EXCEPTION 'Keputusan pembayaran tidak valid';
  END IF;

  SELECT * INTO selected_order
  FROM public.ticket_orders
  WHERE id = p_order_id
  FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'Order tidak ditemukan'; END IF;

  IF selected_order.status = 'Lunas' AND p_resolution = 'Lunas' THEN
    RETURN QUERY SELECT 'Lunas', selected_order.access_code_id,
      (SELECT count(*)::integer FROM public.ticket_instances WHERE ticket_order_id = p_order_id);
    RETURN;
  END IF;
  IF selected_order.status <> 'Menunggu Verifikasi' THEN
    RAISE EXCEPTION 'Order belum berada pada status menunggu verifikasi';
  END IF;

  IF p_resolution = 'Ditolak' THEN
    UPDATE public.ticket_orders
    SET status = 'Ditolak', reviewed_by = p_actor_id, reviewed_at = now(), updated_at = now()
    WHERE id = p_order_id;
    RETURN QUERY SELECT 'Ditolak', NULL::uuid, 0;
    RETURN;
  END IF;

  IF selected_order.payment_amount IS DISTINCT FROM selected_order.total_price THEN
    RAISE EXCEPTION 'Nominal pembayaran order belum tervalidasi';
  END IF;
  IF EXISTS (SELECT 1 FROM public.events WHERE id = selected_order.event_id AND status = 'completed') THEN
    RAISE EXCEPTION 'Event telah selesai, order tidak dapat diterbitkan';
  END IF;

  normalized_phone := public.normalize_ticket_whatsapp(selected_order.whatsapp);
  PERFORM pg_advisory_xact_lock(hashtextextended(normalized_phone, 0));

  SELECT * INTO selected_code
  FROM public.ticket_access_codes
  WHERE event_id = selected_order.event_id
    AND whatsapp_normalized = normalized_phone
    AND status = 'active'
  FOR UPDATE;

  IF NOT FOUND THEN
    IF nullif(p_access_code_hash, '') IS NULL OR nullif(p_whatsapp_code_hash, '') IS NULL OR nullif(p_access_code_ciphertext, '') IS NULL THEN
      RAISE EXCEPTION 'Access Code baru harus disiapkan server';
    END IF;
    IF EXISTS (SELECT 1 FROM public.ticket_access_codes WHERE whatsapp_normalized = normalized_phone AND whatsapp_code_hash = p_whatsapp_code_hash) THEN
      RAISE EXCEPTION 'Access Code sudah pernah digunakan untuk nomor ini; buat kode baru';
    END IF;
    INSERT INTO public.ticket_access_codes (
      event_id, whatsapp_normalized, access_code_hash, whatsapp_code_hash, access_code_ciphertext
    ) VALUES (
      selected_order.event_id, normalized_phone, p_access_code_hash, p_whatsapp_code_hash, p_access_code_ciphertext
    ) RETURNING * INTO selected_code;
  END IF;

  SELECT count(*)::integer INTO instance_count
  FROM public.ticket_instances
  WHERE ticket_order_id = p_order_id;

  IF instance_count = 0 THEN
    IF jsonb_typeof(p_qr_tokens) <> 'array'
      OR jsonb_array_length(p_qr_tokens) <> selected_order.quantity THEN
      RAISE EXCEPTION 'Token QR harus disiapkan untuk setiap tiket order';
    END IF;
    FOR supplied_token IN SELECT value FROM jsonb_array_elements(p_qr_tokens)
    LOOP
      token_index := token_index + 1;
      IF nullif(supplied_token->>'hash', '') IS NULL OR nullif(supplied_token->>'ciphertext', '') IS NULL THEN
        RAISE EXCEPTION 'Token QR tidak valid';
      END IF;
      INSERT INTO public.ticket_instances (
        ticket_order_id, event_id, event_ticket_id, sequence_no, qr_token_hash, qr_token_ciphertext
      ) VALUES (
        p_order_id, selected_order.event_id, selected_order.ticket_id,
        token_index, supplied_token->>'hash', supplied_token->>'ciphertext'
      );
    END LOOP;
  ELSIF instance_count <> selected_order.quantity THEN
    RAISE EXCEPTION 'Jumlah ticket instance tidak sesuai dengan quantity order';
  END IF;

  UPDATE public.ticket_orders
  SET status = 'Lunas',
      access_code_id = selected_code.id,
      reviewed_by = p_actor_id,
      reviewed_at = now(),
      updated_at = now()
  WHERE id = p_order_id;

  UPDATE public.ticket_orders existing_order
  SET access_code_id = selected_code.id
  WHERE existing_order.event_id = selected_order.event_id
    AND public.normalize_ticket_whatsapp(existing_order.whatsapp) = normalized_phone
    AND existing_order.status IN ('Lunas', 'Terverifikasi', 'Selesai');

  RETURN QUERY SELECT 'Lunas', selected_code.id, selected_order.quantity;
END;
$$;

REVOKE ALL ON FUNCTION public.resolve_ticket_order_payment(uuid, text, uuid, text, text, text, jsonb) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.resolve_ticket_order_payment(uuid, text, uuid, text, text, text, jsonb) TO service_role;

CREATE OR REPLACE FUNCTION public.create_ticket_access_session(
  p_access_code_id uuid,
  p_device_tag_hash text,
  p_session_token_hash text,
  p_replace_existing boolean DEFAULT false
)
RETURNS TABLE (session_id uuid, session_state text, idle_expires_at timestamptz)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  selected_code public.ticket_access_codes%ROWTYPE;
  existing_session public.ticket_access_sessions%ROWTYPE;
  new_session_id uuid := gen_random_uuid();
  new_idle_expiry timestamptz := now() + interval '30 minutes';
BEGIN
  PERFORM pg_advisory_xact_lock(hashtextextended(p_access_code_id::text, 0));
  SELECT * INTO selected_code
  FROM public.ticket_access_codes
  WHERE id = p_access_code_id AND status = 'active'
  FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'Kode Akses sudah tidak berlaku'; END IF;
  IF EXISTS (SELECT 1 FROM public.events WHERE id = selected_code.event_id AND status = 'completed') THEN
    RAISE EXCEPTION 'Kode Akses sudah tidak berlaku karena Event telah selesai';
  END IF;

  UPDATE public.ticket_access_sessions
  SET revoked_at = now(), revoke_reason = 'idle_timeout'
  WHERE access_code_id = p_access_code_id
    AND revoked_at IS NULL
    AND idle_expires_at <= now();

  SELECT * INTO existing_session
  FROM public.ticket_access_sessions
  WHERE access_code_id = p_access_code_id AND revoked_at IS NULL
  FOR UPDATE;

  IF FOUND AND existing_session.device_tag_hash <> p_device_tag_hash AND NOT p_replace_existing THEN
    RETURN QUERY SELECT existing_session.id, 'session_conflict'::text, existing_session.idle_expires_at;
    RETURN;
  END IF;

  IF FOUND THEN
    UPDATE public.ticket_access_sessions
    SET revoked_at = now(), revoke_reason = CASE WHEN existing_session.device_tag_hash = p_device_tag_hash THEN 'logout' ELSE 'replaced' END
    WHERE id = existing_session.id;
  END IF;

  INSERT INTO public.ticket_access_sessions (
    id, access_code_id, session_token_hash, device_tag_hash, idle_expires_at
  ) VALUES (
    new_session_id, p_access_code_id, p_session_token_hash, p_device_tag_hash, new_idle_expiry
  );
  RETURN QUERY SELECT new_session_id, 'created'::text, new_idle_expiry;
END;
$$;

REVOKE ALL ON FUNCTION public.create_ticket_access_session(uuid, text, text, boolean) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.create_ticket_access_session(uuid, text, text, boolean) TO service_role;

CREATE OR REPLACE FUNCTION public.record_ticket_access_login_attempt(
  p_phone_key_hash text,
  p_ip_key_hash text,
  p_success boolean
)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  attempt_key text;
  attempt_keys text[] := ARRAY[p_phone_key_hash, p_ip_key_hash];
  attempts public.ticket_access_login_attempts%ROWTYPE;
BEGIN
  IF auth.role() <> 'service_role' THEN RAISE EXCEPTION 'Operasi harus dipanggil melalui service backend'; END IF;
  IF p_success THEN
    DELETE FROM public.ticket_access_login_attempts WHERE attempt_key_hash = p_phone_key_hash;
    RETURN true;
  END IF;

  PERFORM pg_advisory_xact_lock(hashtextextended(p_phone_key_hash, 0));
  PERFORM pg_advisory_xact_lock(hashtextextended(p_ip_key_hash, 0));
  IF EXISTS (
    SELECT 1 FROM public.ticket_access_login_attempts
    WHERE attempt_key_hash = ANY(attempt_keys) AND blocked_until > now()
  ) THEN
    RETURN false;
  END IF;

  FOREACH attempt_key IN ARRAY attempt_keys LOOP
    SELECT * INTO attempts FROM public.ticket_access_login_attempts WHERE attempt_key_hash = attempt_key FOR UPDATE;
    IF NOT FOUND THEN
      INSERT INTO public.ticket_access_login_attempts(attempt_key_hash, attempt_count, window_started_at, updated_at)
      VALUES (attempt_key, 1, now(), now());
    ELSIF attempts.window_started_at <= now() - interval '15 minutes' THEN
      UPDATE public.ticket_access_login_attempts
      SET attempt_count = 1, window_started_at = now(), blocked_until = NULL, updated_at = now()
      WHERE attempt_key_hash = attempt_key;
    ELSE
      UPDATE public.ticket_access_login_attempts
      SET attempt_count = attempt_count + 1,
          blocked_until = CASE WHEN attempt_count + 1 >= 10 THEN now() + interval '15 minutes' ELSE blocked_until END,
          updated_at = now()
      WHERE attempt_key_hash = attempt_key;
    END IF;
  END LOOP;
  RETURN true;
END;
$$;

REVOKE ALL ON FUNCTION public.record_ticket_access_login_attempt(text, text, boolean) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.record_ticket_access_login_attempt(text, text, boolean) TO service_role;

CREATE OR REPLACE FUNCTION public.revoke_ticket_access_session(p_session_token_hash text)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  revoked_count integer;
BEGIN
  UPDATE public.ticket_access_sessions
  SET revoked_at = now(), revoke_reason = 'logout'
  WHERE session_token_hash = p_session_token_hash AND revoked_at IS NULL;
  GET DIAGNOSTICS revoked_count = ROW_COUNT;
  RETURN revoked_count = 1;
END;
$$;

REVOKE ALL ON FUNCTION public.revoke_ticket_access_session(text) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.revoke_ticket_access_session(text) TO service_role;

CREATE OR REPLACE FUNCTION public.mark_ticket_access_code_sent(
  p_access_code_id uuid,
  p_actor_id uuid
)
RETURNS TABLE (last_sent_at timestamptz, send_count integer)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN QUERY
  UPDATE public.ticket_access_codes access_code
  SET last_sent_at = now(),
      last_sent_by = p_actor_id,
      send_count = access_code.send_count + 1,
      updated_at = now()
  WHERE access_code.id = p_access_code_id
    AND access_code.status = 'active'
  RETURNING access_code.last_sent_at, access_code.send_count;
  IF NOT FOUND THEN RAISE EXCEPTION 'Access Code tidak aktif'; END IF;
END;
$$;

REVOKE ALL ON FUNCTION public.mark_ticket_access_code_sent(uuid, uuid) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.mark_ticket_access_code_sent(uuid, uuid) TO service_role;

CREATE OR REPLACE FUNCTION public.set_ticket_payment_method_active(
  p_method_id uuid,
  p_actor_id uuid
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  selected_method public.event_payment_methods%ROWTYPE;
BEGIN
  SELECT * INTO selected_method
  FROM public.event_payment_methods
  WHERE id = p_method_id
  FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'Informasi pembayaran tidak ditemukan'; END IF;

  IF auth.role() <> 'service_role' THEN RAISE EXCEPTION 'Operasi harus dipanggil melalui service backend'; END IF;

  PERFORM pg_advisory_xact_lock(hashtextextended(selected_method.event_id::text, 0));
  UPDATE public.event_payment_methods
  SET is_active = false, updated_at = now()
  WHERE event_id = selected_method.event_id AND is_active;

  UPDATE public.event_payment_methods
  SET is_active = true, updated_at = now()
  WHERE id = selected_method.id;

  RETURN selected_method.id;
END;
$$;

REVOKE ALL ON FUNCTION public.set_ticket_payment_method_active(uuid, uuid) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.set_ticket_payment_method_active(uuid, uuid) TO service_role;

CREATE OR REPLACE FUNCTION public.mark_ticket_maintenance_sent(
  p_maintenance_log_id uuid,
  p_actor_id uuid
)
RETURNS TABLE (sent_at timestamptz, send_count integer)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  selected_log public.ticket_maintenance_logs%ROWTYPE;
  next_sent_at timestamptz := now();
BEGIN
  IF auth.role() <> 'service_role' THEN RAISE EXCEPTION 'Operasi harus dipanggil melalui service backend'; END IF;
  SELECT * INTO selected_log FROM public.ticket_maintenance_logs WHERE id = p_maintenance_log_id FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'Aktivitas maintenance tidak ditemukan'; END IF;

  INSERT INTO public.ticket_maintenance_sends(maintenance_log_id, sent_at, sent_by)
  VALUES (selected_log.id, next_sent_at, p_actor_id);
  UPDATE public.ticket_maintenance_logs
  SET delivery_status = 'sent', sent_at = next_sent_at, sent_by = p_actor_id, updated_at = next_sent_at
  WHERE id = selected_log.id;

  RETURN QUERY SELECT next_sent_at,
    (SELECT count(*)::integer FROM public.ticket_maintenance_sends WHERE maintenance_log_id = selected_log.id);
END;
$$;

REVOKE ALL ON FUNCTION public.mark_ticket_maintenance_sent(uuid, uuid) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.mark_ticket_maintenance_sent(uuid, uuid) TO service_role;

CREATE OR REPLACE FUNCTION public.check_in_ticket(p_event_id uuid, p_qr_token_hash text)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  selected_ticket public.ticket_instances%ROWTYPE;
  selected_order public.ticket_orders%ROWTYPE;
  selected_event public.events%ROWTYPE;
  event_local_date date := (now() AT TIME ZONE 'Asia/Jakarta')::date;
BEGIN
  SELECT instance.* INTO selected_ticket
  FROM public.ticket_instances instance
  WHERE instance.qr_token_hash = p_qr_token_hash
    AND instance.event_id = p_event_id
  FOR UPDATE;
  IF NOT FOUND THEN RETURN jsonb_build_object('ok', false, 'status', 'invalid', 'message', 'Tiket tidak valid untuk Event ini'); END IF;

  IF NOT public.jwt_has_role('admin')
    AND NOT (public.jwt_has_role('admin_qr') AND public.user_has_ticket_event_scope(p_event_id, 'admin_qr')) THEN
    RAISE EXCEPTION 'Akun tidak memiliki scope scan untuk Event ini';
  END IF;

  SELECT * INTO selected_event FROM public.events WHERE id = p_event_id;
  IF selected_event.status = 'cancelled' THEN
    RETURN jsonb_build_object('ok', false, 'status', 'event_cancelled', 'message', 'Event Dibatalkan');
  END IF;
  IF selected_event.status = 'completed' THEN
    RETURN jsonb_build_object('ok', false, 'status', 'event_completed', 'message', 'Event telah selesai');
  END IF;
  IF event_local_date < selected_event.date OR event_local_date > selected_event.date + 1 THEN
    RETURN jsonb_build_object('ok', false, 'status', 'outside_checkin_window', 'message', 'Di luar periode check-in Event');
  END IF;
  IF selected_ticket.status <> 'active' THEN
    RETURN jsonb_build_object('ok', false, 'status', 'inactive', 'message', 'Tiket tidak aktif');
  END IF;

  SELECT * INTO selected_order FROM public.ticket_orders WHERE id = selected_ticket.ticket_order_id;
  IF selected_order.status <> 'Lunas' THEN
    RETURN jsonb_build_object('ok', false, 'status', 'unpaid', 'message', 'Order belum lunas');
  END IF;
  IF selected_ticket.checked_in_at IS NOT NULL THEN
    RETURN jsonb_build_object('ok', false, 'status', 'already_used', 'message', 'Tiket sudah digunakan', 'checked_in_at', selected_ticket.checked_in_at);
  END IF;

  UPDATE public.ticket_instances
  SET checked_in_at = now(), checked_in_by = auth.uid(), check_in_source = 'qr', updated_at = now()
  WHERE id = selected_ticket.id AND checked_in_at IS NULL AND status = 'active';
  IF NOT FOUND THEN
    RETURN jsonb_build_object('ok', false, 'status', 'already_used', 'message', 'Tiket sudah digunakan');
  END IF;

  RETURN jsonb_build_object('ok', true, 'status', 'checked_in', 'ticket_id', selected_ticket.id, 'checked_in_at', now());
END;
$$;

REVOKE ALL ON FUNCTION public.check_in_ticket(uuid, text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.check_in_ticket(uuid, text) TO authenticated;

-- Source migration: 20261002140000_grant_authenticated_ticket_order_rpc.sql
GRANT EXECUTE ON FUNCTION public.create_ticket_order(text, uuid, uuid, text, text, text, integer, text) TO authenticated;


-- Source migration: 20261002150000_limit_ticket_order_quantity_to_10.sql
CREATE OR REPLACE FUNCTION public.create_ticket_order(
  p_order_number text,
  p_event_id uuid,
  p_ticket_id uuid,
  p_full_name text,
  p_email text,
  p_whatsapp text,
  p_quantity integer,
  p_notes text
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  selected_event public.events%ROWTYPE;
  selected_ticket public.event_tickets%ROWTYPE;
  selected_payment public.event_payment_methods%ROWTYPE;
  normalized_phone text;
  committed_quantity bigint;
  new_order_id uuid := gen_random_uuid();
BEGIN
  IF p_quantity IS NULL OR p_quantity < 1 OR p_quantity > 10 THEN
    RAISE EXCEPTION 'Jumlah tiket harus antara 1 dan 10';
  END IF;
  IF nullif(trim(p_full_name), '') IS NULL THEN
    RAISE EXCEPTION 'Nama pembeli wajib diisi';
  END IF;
  normalized_phone := public.normalize_ticket_whatsapp(p_whatsapp);
  IF length(normalized_phone) < 10 OR length(normalized_phone) > 15 THEN
    RAISE EXCEPTION 'Nomor WhatsApp tidak valid';
  END IF;
  IF p_order_number !~ '^[A-Z]{3}-[A-Z0-9]{6}$' THEN
    RAISE EXCEPTION 'Nomor order tidak valid';
  END IF;

  SELECT * INTO selected_event
  FROM public.events
  WHERE id = p_event_id
    AND published = true
    AND status = 'upcoming'
  FOR SHARE;
  IF NOT FOUND THEN RAISE EXCEPTION 'Event tidak tersedia untuk pemesanan'; END IF;

  PERFORM pg_advisory_xact_lock(hashtextextended(p_ticket_id::text, 0));
  SELECT * INTO selected_ticket
  FROM public.event_tickets
  WHERE id = p_ticket_id
    AND event_id = p_event_id
    AND status = 'active'
  FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'Jenis tiket tidak tersedia'; END IF;

  SELECT * INTO selected_payment
  FROM public.event_payment_methods
  WHERE event_id = p_event_id
    AND is_active = true
  FOR SHARE;
  IF NOT FOUND THEN RAISE EXCEPTION 'Informasi pembayaran Event belum aktif'; END IF;

  UPDATE public.ticket_orders
  SET status = 'Expired', updated_at = now()
  WHERE ticket_id = p_ticket_id
    AND status IN ('Menunggu Pembayaran', 'Menunggu Verifikasi', 'Sudah Bayar')
    AND expires_at IS NOT NULL
    AND expires_at <= now();

  SELECT coalesce(sum(quantity), 0) INTO committed_quantity
  FROM public.ticket_orders
  WHERE ticket_id = p_ticket_id
    AND status IN ('Menunggu Pembayaran', 'Menunggu Verifikasi', 'Sudah Bayar', 'Lunas', 'Terverifikasi', 'Selesai');

  IF selected_ticket.quota IS NOT NULL
    AND committed_quantity + p_quantity > selected_ticket.quota THEN
    RAISE EXCEPTION 'Kuota tiket tidak mencukupi';
  END IF;

  INSERT INTO public.ticket_orders (
    id, order_number, event_id, ticket_id, ticket_category,
    full_name, email, whatsapp, quantity, unit_price, total_price,
    notes, status, expires_at, payment_method_id, payment_method_snapshot
  ) VALUES (
    new_order_id,
    p_order_number,
    p_event_id,
    p_ticket_id,
    selected_ticket.name,
    trim(p_full_name),
    nullif(lower(trim(p_email)), ''),
    normalized_phone,
    p_quantity,
    selected_ticket.price,
    selected_ticket.price * p_quantity,
    nullif(trim(p_notes), ''),
    'Menunggu Pembayaran',
    now() + interval '30 minutes',
    selected_payment.id,
    jsonb_build_object(
      'recipient_name', selected_payment.recipient_name,
      'bank_name', selected_payment.bank_name,
      'account_number', selected_payment.account_number,
      'qris_storage_path', selected_payment.qris_storage_path,
      'note', selected_payment.note
    )
  );

  RETURN new_order_id;
END;
$$;


-- Source migration: 20261002160000_allow_legacy_sudah_bayar_payment_review.sql
-- Keep legacy "Sudah Bayar" orders reviewable in the Admin Ticket workspace.
-- This preserves the existing payment amount validation and ticket lifecycle.

CREATE OR REPLACE FUNCTION public.resolve_ticket_order_payment(
  p_order_id uuid,
  p_resolution text,
  p_actor_id uuid,
  p_access_code_hash text DEFAULT NULL,
  p_whatsapp_code_hash text DEFAULT NULL,
  p_access_code_ciphertext text DEFAULT NULL,
  p_qr_tokens jsonb DEFAULT '[]'::jsonb
)
RETURNS TABLE (resolved_status text, resolved_access_code_id uuid, issued_ticket_count integer)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  selected_order public.ticket_orders%ROWTYPE;
  normalized_phone text;
  selected_code public.ticket_access_codes%ROWTYPE;
  supplied_token jsonb;
  instance_count integer;
  token_index integer := 0;
BEGIN
  IF p_resolution NOT IN ('Lunas', 'Ditolak') THEN
    RAISE EXCEPTION 'Keputusan pembayaran tidak valid';
  END IF;

  SELECT * INTO selected_order
  FROM public.ticket_orders
  WHERE id = p_order_id
  FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'Order tidak ditemukan'; END IF;

  IF selected_order.status = 'Lunas' AND p_resolution = 'Lunas' THEN
    RETURN QUERY SELECT 'Lunas', selected_order.access_code_id,
      (SELECT count(*)::integer FROM public.ticket_instances WHERE ticket_order_id = p_order_id);
    RETURN;
  END IF;
  IF selected_order.status NOT IN ('Menunggu Verifikasi', 'Sudah Bayar') THEN
    RAISE EXCEPTION 'Order belum berada pada status menunggu verifikasi';
  END IF;

  IF p_resolution = 'Ditolak' THEN
    UPDATE public.ticket_orders
    SET status = 'Ditolak', reviewed_by = p_actor_id, reviewed_at = now(), updated_at = now()
    WHERE id = p_order_id;
    RETURN QUERY SELECT 'Ditolak', NULL::uuid, 0;
    RETURN;
  END IF;

  IF selected_order.payment_amount IS DISTINCT FROM selected_order.total_price THEN
    RAISE EXCEPTION 'Nominal pembayaran order belum tervalidasi';
  END IF;
  IF EXISTS (SELECT 1 FROM public.events WHERE id = selected_order.event_id AND status = 'completed') THEN
    RAISE EXCEPTION 'Event telah selesai, order tidak dapat diterbitkan';
  END IF;

  normalized_phone := public.normalize_ticket_whatsapp(selected_order.whatsapp);
  PERFORM pg_advisory_xact_lock(hashtextextended(normalized_phone, 0));

  SELECT * INTO selected_code
  FROM public.ticket_access_codes
  WHERE event_id = selected_order.event_id
    AND whatsapp_normalized = normalized_phone
    AND status = 'active'
  FOR UPDATE;

  IF NOT FOUND THEN
    IF nullif(p_access_code_hash, '') IS NULL OR nullif(p_whatsapp_code_hash, '') IS NULL OR nullif(p_access_code_ciphertext, '') IS NULL THEN
      RAISE EXCEPTION 'Access Code baru harus disiapkan server';
    END IF;
    IF EXISTS (SELECT 1 FROM public.ticket_access_codes WHERE whatsapp_normalized = normalized_phone AND whatsapp_code_hash = p_whatsapp_code_hash) THEN
      RAISE EXCEPTION 'Access Code sudah pernah digunakan untuk nomor ini; buat kode baru';
    END IF;
    INSERT INTO public.ticket_access_codes (
      event_id, whatsapp_normalized, access_code_hash, whatsapp_code_hash, access_code_ciphertext
    ) VALUES (
      selected_order.event_id, normalized_phone, p_access_code_hash, p_whatsapp_code_hash, p_access_code_ciphertext
    ) RETURNING * INTO selected_code;
  END IF;

  SELECT count(*)::integer INTO instance_count
  FROM public.ticket_instances
  WHERE ticket_order_id = p_order_id;

  IF instance_count = 0 THEN
    IF jsonb_typeof(p_qr_tokens) <> 'array'
      OR jsonb_array_length(p_qr_tokens) <> selected_order.quantity THEN
      RAISE EXCEPTION 'Token QR harus disiapkan untuk setiap tiket order';
    END IF;
    FOR supplied_token IN SELECT value FROM jsonb_array_elements(p_qr_tokens)
    LOOP
      token_index := token_index + 1;
      IF nullif(supplied_token->>'hash', '') IS NULL OR nullif(supplied_token->>'ciphertext', '') IS NULL THEN
        RAISE EXCEPTION 'Token QR tidak valid';
      END IF;
      INSERT INTO public.ticket_instances (
        ticket_order_id, event_id, event_ticket_id, sequence_no, qr_token_hash, qr_token_ciphertext
      ) VALUES (
        p_order_id, selected_order.event_id, selected_order.ticket_id,
        token_index, supplied_token->>'hash', supplied_token->>'ciphertext'
      );
    END LOOP;
  ELSIF instance_count <> selected_order.quantity THEN
    RAISE EXCEPTION 'Jumlah ticket instance tidak sesuai dengan quantity order';
  END IF;

  UPDATE public.ticket_orders
  SET status = 'Lunas',
      access_code_id = selected_code.id,
      reviewed_by = p_actor_id,
      reviewed_at = now(),
      updated_at = now()
  WHERE id = p_order_id;

  UPDATE public.ticket_orders existing_order
  SET access_code_id = selected_code.id
  WHERE existing_order.event_id = selected_order.event_id
    AND public.normalize_ticket_whatsapp(existing_order.whatsapp) = normalized_phone
    AND existing_order.status IN ('Lunas', 'Terverifikasi', 'Selesai');

  RETURN QUERY SELECT 'Lunas', selected_code.id, selected_order.quantity;
END;
$$;

REVOKE ALL ON FUNCTION public.resolve_ticket_order_payment(uuid, text, uuid, text, text, text, jsonb) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.resolve_ticket_order_payment(uuid, text, uuid, text, text, text, jsonb) TO service_role;


-- Source migration: 20261002170000_restrict_event_ticket_crud_to_scoped_ticket_admins.sql
-- Keep Event Admin focused on Event management. Ticket configuration is
-- managed by Admin Penuh or Admin Tiket assigned to the Event.

DROP POLICY IF EXISTS "admin_all_event_tickets" ON public.event_tickets;
DROP POLICY IF EXISTS "admin_insert_event_tickets" ON public.event_tickets;
DROP POLICY IF EXISTS "admin_update_event_tickets" ON public.event_tickets;
DROP POLICY IF EXISTS "admin_delete_event_tickets" ON public.event_tickets;
DROP POLICY IF EXISTS "operational_admin_insert_event_tickets" ON public.event_tickets;
DROP POLICY IF EXISTS "operational_admin_update_event_tickets" ON public.event_tickets;
DROP POLICY IF EXISTS "operational_admin_delete_event_tickets" ON public.event_tickets;
DROP POLICY IF EXISTS "event_admin_insert_event_tickets" ON public.event_tickets;
DROP POLICY IF EXISTS "event_admin_update_event_tickets" ON public.event_tickets;
DROP POLICY IF EXISTS "event_admin_delete_event_tickets" ON public.event_tickets;

CREATE POLICY "ticket_admin_insert_scoped_event_tickets"
  ON public.event_tickets
  FOR INSERT
  TO authenticated
  WITH CHECK (
    public.jwt_has_role('admin')
    OR public.user_has_ticket_event_scope(event_id, 'admin_ticket')
  );

CREATE POLICY "ticket_admin_update_scoped_event_tickets"
  ON public.event_tickets
  FOR UPDATE
  TO authenticated
  USING (
    public.jwt_has_role('admin')
    OR public.user_has_ticket_event_scope(event_id, 'admin_ticket')
  )
  WITH CHECK (
    public.jwt_has_role('admin')
    OR public.user_has_ticket_event_scope(event_id, 'admin_ticket')
  );

CREATE POLICY "ticket_admin_delete_scoped_event_tickets"
  ON public.event_tickets
  FOR DELETE
  TO authenticated
  USING (
    public.jwt_has_role('admin')
    OR public.user_has_ticket_event_scope(event_id, 'admin_ticket')
  );


-- Source migration: 20261002180000_fix_ticket_access_session_expiry_ambiguity.sql
CREATE OR REPLACE FUNCTION public.create_ticket_access_session(
  p_access_code_id uuid,
  p_device_tag_hash text,
  p_session_token_hash text,
  p_replace_existing boolean DEFAULT false
)
RETURNS TABLE (session_id uuid, session_state text, idle_expires_at timestamptz)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  selected_code public.ticket_access_codes%ROWTYPE;
  existing_session public.ticket_access_sessions%ROWTYPE;
  new_session_id uuid := gen_random_uuid();
  new_idle_expiry timestamptz := now() + interval '30 minutes';
BEGIN
  PERFORM pg_advisory_xact_lock(hashtextextended(p_access_code_id::text, 0));
  SELECT * INTO selected_code
  FROM public.ticket_access_codes
  WHERE id = p_access_code_id AND status = 'active'
  FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'Kode Akses sudah tidak berlaku'; END IF;
  IF EXISTS (SELECT 1 FROM public.events WHERE id = selected_code.event_id AND status = 'completed') THEN
    RAISE EXCEPTION 'Kode Akses sudah tidak berlaku karena Event telah selesai';
  END IF;

  UPDATE public.ticket_access_sessions AS access_session
  SET revoked_at = now(), revoke_reason = 'idle_timeout'
  WHERE access_session.access_code_id = p_access_code_id
    AND access_session.revoked_at IS NULL
    AND access_session.idle_expires_at <= now();

  SELECT * INTO existing_session
  FROM public.ticket_access_sessions
  WHERE access_code_id = p_access_code_id AND revoked_at IS NULL
  FOR UPDATE;

  IF FOUND AND existing_session.device_tag_hash <> p_device_tag_hash AND NOT p_replace_existing THEN
    RETURN QUERY SELECT existing_session.id, 'session_conflict'::text, existing_session.idle_expires_at;
    RETURN;
  END IF;

  IF FOUND THEN
    UPDATE public.ticket_access_sessions
    SET revoked_at = now(), revoke_reason = CASE WHEN existing_session.device_tag_hash = p_device_tag_hash THEN 'logout' ELSE 'replaced' END
    WHERE id = existing_session.id;
  END IF;

  INSERT INTO public.ticket_access_sessions (
    id, access_code_id, session_token_hash, device_tag_hash, idle_expires_at
  ) VALUES (
    new_session_id, p_access_code_id, p_session_token_hash, p_device_tag_hash, new_idle_expiry
  );
  RETURN QUERY SELECT new_session_id, 'created'::text, new_idle_expiry;
END;
$$;

REVOKE ALL ON FUNCTION public.create_ticket_access_session(uuid, text, text, boolean) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.create_ticket_access_session(uuid, text, text, boolean) TO service_role;


-- Source migration: 20261002190000_ticketing_checkout_drafts_until_proof.sql
ALTER TABLE public.ticket_orders
  DROP CONSTRAINT IF EXISTS ticket_orders_status_check;

ALTER TABLE public.ticket_orders
  ADD CONSTRAINT ticket_orders_status_check CHECK (
    status IN (
      'Draft Pembayaran',
      'Menunggu Pembayaran',
      'Menunggu Verifikasi',
      'Lunas',
      'Ditolak',
      'Expired',
      'Sudah Bayar',
      'Terverifikasi',
      'Selesai',
      'Dibatalkan'
    )
  );

DROP INDEX IF EXISTS public.idx_ticket_orders_expiring;
CREATE INDEX idx_ticket_orders_expiring
  ON public.ticket_orders(expires_at)
  WHERE status IN ('Draft Pembayaran', 'Menunggu Pembayaran', 'Menunggu Verifikasi', 'Sudah Bayar');

CREATE OR REPLACE FUNCTION public.create_ticket_order(
  p_order_number text,
  p_event_id uuid,
  p_ticket_id uuid,
  p_full_name text,
  p_email text,
  p_whatsapp text,
  p_quantity integer,
  p_notes text
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  selected_event public.events%ROWTYPE;
  selected_ticket public.event_tickets%ROWTYPE;
  selected_payment public.event_payment_methods%ROWTYPE;
  normalized_phone text;
  committed_quantity bigint;
  new_order_id uuid := gen_random_uuid();
BEGIN
  IF p_quantity IS NULL OR p_quantity < 1 OR p_quantity > 10 THEN
    RAISE EXCEPTION 'Jumlah tiket harus antara 1 dan 10';
  END IF;
  IF nullif(trim(p_full_name), '') IS NULL THEN
    RAISE EXCEPTION 'Nama pembeli wajib diisi';
  END IF;
  IF nullif(trim(p_email), '') IS NULL OR trim(p_email) !~ '^[^[:space:]@]+@[^[:space:]@]+\.[^[:space:]@]+$' THEN
    RAISE EXCEPTION 'Email pembeli wajib diisi dengan format yang valid';
  END IF;
  normalized_phone := public.normalize_ticket_whatsapp(p_whatsapp);
  IF length(normalized_phone) < 10 OR length(normalized_phone) > 15 THEN
    RAISE EXCEPTION 'Nomor WhatsApp tidak valid';
  END IF;
  IF p_order_number !~ '^[A-Z]{3}-[A-Z0-9]{6}$' THEN
    RAISE EXCEPTION 'Nomor order tidak valid';
  END IF;

  SELECT * INTO selected_event
  FROM public.events
  WHERE id = p_event_id
    AND published = true
    AND status = 'upcoming'
  FOR SHARE;
  IF NOT FOUND THEN RAISE EXCEPTION 'Event tidak tersedia untuk pemesanan'; END IF;

  PERFORM pg_advisory_xact_lock(hashtextextended(p_ticket_id::text, 0));
  SELECT * INTO selected_ticket
  FROM public.event_tickets
  WHERE id = p_ticket_id
    AND event_id = p_event_id
    AND status = 'active'
  FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'Jenis tiket tidak tersedia'; END IF;

  SELECT * INTO selected_payment
  FROM public.event_payment_methods
  WHERE event_id = p_event_id
    AND is_active = true
  FOR SHARE;
  IF NOT FOUND THEN RAISE EXCEPTION 'Informasi pembayaran Event belum aktif'; END IF;

  UPDATE public.ticket_orders
  SET status = 'Expired', updated_at = now()
  WHERE ticket_id = p_ticket_id
    AND status IN ('Draft Pembayaran', 'Menunggu Pembayaran', 'Menunggu Verifikasi', 'Sudah Bayar')
    AND expires_at IS NOT NULL
    AND expires_at <= now();

  SELECT coalesce(sum(quantity), 0) INTO committed_quantity
  FROM public.ticket_orders
  WHERE ticket_id = p_ticket_id
    AND status IN ('Draft Pembayaran', 'Menunggu Pembayaran', 'Menunggu Verifikasi', 'Sudah Bayar', 'Lunas', 'Terverifikasi', 'Selesai');

  IF selected_ticket.quota IS NOT NULL
    AND committed_quantity + p_quantity > selected_ticket.quota THEN
    RAISE EXCEPTION 'Kuota tiket tidak mencukupi';
  END IF;

  INSERT INTO public.ticket_orders (
    id, order_number, event_id, ticket_id, ticket_category,
    full_name, email, whatsapp, quantity, unit_price, total_price,
    notes, status, expires_at, payment_method_id, payment_method_snapshot
  ) VALUES (
    new_order_id,
    p_order_number,
    p_event_id,
    p_ticket_id,
    selected_ticket.name,
    trim(p_full_name),
    lower(trim(p_email)),
    normalized_phone,
    p_quantity,
    selected_ticket.price,
    selected_ticket.price * p_quantity,
    null,
    'Draft Pembayaran',
    now() + interval '30 minutes',
    selected_payment.id,
    jsonb_build_object(
      'recipient_name', selected_payment.recipient_name,
      'bank_name', selected_payment.bank_name,
      'account_number', selected_payment.account_number,
      'qris_storage_path', selected_payment.qris_storage_path,
      'note', selected_payment.note
    )
  );

  RETURN new_order_id;
END;
$$;

REVOKE ALL ON FUNCTION public.create_ticket_order(text, uuid, uuid, text, text, text, integer, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.create_ticket_order(text, uuid, uuid, text, text, text, integer, text) TO anon;

CREATE OR REPLACE FUNCTION public.expire_unpaid_ticket_orders()
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  expired_count integer;
BEGIN
  UPDATE public.ticket_orders
  SET status = 'Expired', updated_at = now()
  WHERE status IN ('Draft Pembayaran', 'Menunggu Pembayaran')
    AND expires_at IS NOT NULL
    AND expires_at <= now();
  GET DIAGNOSTICS expired_count = ROW_COUNT;
  RETURN expired_count;
END;
$$;

REVOKE ALL ON FUNCTION public.expire_unpaid_ticket_orders() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.expire_unpaid_ticket_orders() TO service_role;

CREATE OR REPLACE FUNCTION public.expire_ticket_orders_for_events(p_event_ids uuid[])
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  expired_count integer;
BEGIN
  IF auth.role() <> 'service_role' THEN RAISE EXCEPTION 'Operasi harus dipanggil melalui service backend'; END IF;
  UPDATE public.ticket_orders
  SET status = 'Expired', updated_at = now()
  WHERE event_id = ANY(p_event_ids)
    AND status IN ('Draft Pembayaran', 'Menunggu Pembayaran')
    AND expires_at IS NOT NULL
    AND expires_at <= now();
  GET DIAGNOSTICS expired_count = ROW_COUNT;
  RETURN expired_count;
END;
$$;

REVOKE ALL ON FUNCTION public.expire_ticket_orders_for_events(uuid[]) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.expire_ticket_orders_for_events(uuid[]) TO service_role;

CREATE OR REPLACE FUNCTION public.submit_ticket_payment(
  p_order_id uuid,
  p_whatsapp text,
  p_payment_amount integer,
  p_payment_proof_path text
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  selected_order public.ticket_orders%ROWTYPE;
BEGIN
  SELECT * INTO selected_order
  FROM public.ticket_orders
  WHERE id = p_order_id
  FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'Order tidak ditemukan'; END IF;
  IF public.normalize_ticket_whatsapp(p_whatsapp) <> selected_order.whatsapp THEN
    RAISE EXCEPTION 'Nomor WhatsApp tidak sesuai dengan order';
  END IF;
  IF selected_order.status NOT IN ('Draft Pembayaran', 'Menunggu Pembayaran')
    OR selected_order.expires_at IS NULL
    OR selected_order.expires_at <= now() THEN
    RAISE EXCEPTION 'Batas pembayaran order sudah berakhir';
  END IF;
  IF p_payment_amount IS NULL OR p_payment_amount <> selected_order.total_price THEN
    RAISE EXCEPTION 'Nominal pembayaran harus sama dengan total order';
  END IF;
  IF p_payment_proof_path IS NULL
    OR split_part(p_payment_proof_path, '/', 1) <> p_order_id::text THEN
    RAISE EXCEPTION 'Lokasi bukti pembayaran tidak valid';
  END IF;

  UPDATE public.ticket_orders
  SET status = 'Menunggu Verifikasi',
      payment_amount = p_payment_amount,
      payment_proof_path = p_payment_proof_path,
      payment_submitted_at = now(),
      expires_at = NULL,
      updated_at = now()
  WHERE id = p_order_id;
END;
$$;

REVOKE ALL ON FUNCTION public.submit_ticket_payment(uuid, text, integer, text) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.submit_ticket_payment(uuid, text, integer, text) TO service_role;


-- Source migration: 20261002200000_reset_ticket_login_limits_on_success.sql
CREATE OR REPLACE FUNCTION public.record_ticket_access_login_attempt(
  p_phone_key_hash text,
  p_ip_key_hash text,
  p_success boolean
)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  attempt_key text;
  attempt_keys text[] := ARRAY[p_phone_key_hash, p_ip_key_hash];
  attempts public.ticket_access_login_attempts%ROWTYPE;
BEGIN
  IF auth.role() <> 'service_role' THEN RAISE EXCEPTION 'Operasi harus dipanggil melalui service backend'; END IF;
  IF p_success THEN
    DELETE FROM public.ticket_access_login_attempts WHERE attempt_key_hash = ANY(attempt_keys);
    RETURN true;
  END IF;

  PERFORM pg_advisory_xact_lock(hashtextextended(p_phone_key_hash, 0));
  PERFORM pg_advisory_xact_lock(hashtextextended(p_ip_key_hash, 0));
  IF EXISTS (
    SELECT 1 FROM public.ticket_access_login_attempts
    WHERE attempt_key_hash = ANY(attempt_keys) AND blocked_until > now()
  ) THEN
    RETURN false;
  END IF;

  FOREACH attempt_key IN ARRAY attempt_keys LOOP
    SELECT * INTO attempts FROM public.ticket_access_login_attempts WHERE attempt_key_hash = attempt_key FOR UPDATE;
    IF NOT FOUND THEN
      INSERT INTO public.ticket_access_login_attempts(attempt_key_hash, attempt_count, window_started_at, updated_at)
      VALUES (attempt_key, 1, now(), now());
    ELSIF attempts.window_started_at <= now() - interval '15 minutes' THEN
      UPDATE public.ticket_access_login_attempts
      SET attempt_count = 1, window_started_at = now(), blocked_until = NULL, updated_at = now()
      WHERE attempt_key_hash = attempt_key;
    ELSE
      UPDATE public.ticket_access_login_attempts
      SET attempt_count = attempt_count + 1,
          blocked_until = CASE WHEN attempt_count + 1 >= 10 THEN now() + interval '15 minutes' ELSE blocked_until END,
          updated_at = now()
      WHERE attempt_key_hash = attempt_key;
    END IF;
  END LOOP;
  RETURN true;
END;
$$;

REVOKE ALL ON FUNCTION public.record_ticket_access_login_attempt(text, text, boolean) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.record_ticket_access_login_attempt(text, text, boolean) TO service_role;


-- Source migration: 20261002210000_scope_ticket_login_limits.sql
CREATE OR REPLACE FUNCTION public.record_ticket_access_login_attempt(
  p_phone_key_hash text,
  p_ip_key_hash text,
  p_success boolean
)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  attempt_key text;
  attempt_keys text[] := ARRAY[p_phone_key_hash, p_ip_key_hash];
  attempts public.ticket_access_login_attempts%ROWTYPE;
  attempt_limit integer;
  attempt_window interval;
  block_duration interval;
BEGIN
  IF auth.role() <> 'service_role' THEN RAISE EXCEPTION 'Operasi harus dipanggil melalui service backend'; END IF;
  IF p_success THEN
    DELETE FROM public.ticket_access_login_attempts WHERE attempt_key_hash = p_phone_key_hash;
    RETURN true;
  END IF;

  PERFORM pg_advisory_xact_lock(hashtextextended(p_phone_key_hash, 0));
  PERFORM pg_advisory_xact_lock(hashtextextended(p_ip_key_hash, 0));
  IF EXISTS (
    SELECT 1 FROM public.ticket_access_login_attempts
    WHERE attempt_key_hash = ANY(attempt_keys) AND blocked_until > now()
  ) THEN
    RETURN false;
  END IF;

  FOREACH attempt_key IN ARRAY attempt_keys LOOP
    IF attempt_key = p_phone_key_hash THEN
      attempt_limit := 6;
      attempt_window := interval '5 minutes';
      block_duration := interval '2 minutes';
    ELSE
      attempt_limit := 30;
      attempt_window := interval '5 minutes';
      block_duration := interval '1 minute';
    END IF;

    SELECT * INTO attempts
    FROM public.ticket_access_login_attempts
    WHERE attempt_key_hash = attempt_key
    FOR UPDATE;

    IF NOT FOUND THEN
      INSERT INTO public.ticket_access_login_attempts(attempt_key_hash, attempt_count, window_started_at, updated_at)
      VALUES (attempt_key, 1, now(), now());
    ELSIF attempts.window_started_at <= now() - attempt_window THEN
      UPDATE public.ticket_access_login_attempts
      SET attempt_count = 1, window_started_at = now(), blocked_until = NULL, updated_at = now()
      WHERE attempt_key_hash = attempt_key;
    ELSE
      UPDATE public.ticket_access_login_attempts
      SET attempt_count = attempt_count + 1,
          blocked_until = CASE
            WHEN attempt_count + 1 >= attempt_limit THEN now() + block_duration
            ELSE blocked_until
          END,
          updated_at = now()
      WHERE attempt_key_hash = attempt_key;
    END IF;
  END LOOP;
  RETURN true;
END;
$$;

REVOKE ALL ON FUNCTION public.record_ticket_access_login_attempt(text, text, boolean) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.record_ticket_access_login_attempt(text, text, boolean) TO service_role;

DELETE FROM public.ticket_access_login_attempts;


-- Source migration: 20261002220000_ticket_gates_checkin_windows.sql
CREATE TABLE IF NOT EXISTS public.event_checkin_settings (
  event_id uuid PRIMARY KEY REFERENCES public.events(id) ON DELETE CASCADE,
  opens_at timestamptz NOT NULL,
  closes_at timestamptz NOT NULL,
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT event_checkin_settings_window CHECK (opens_at < closes_at)
);

CREATE TABLE IF NOT EXISTS public.event_gates (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  event_id uuid NOT NULL REFERENCES public.events(id) ON DELETE CASCADE,
  name text NOT NULL CHECK (length(trim(name)) BETWEEN 1 AND 80),
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (event_id, name)
);

CREATE TABLE IF NOT EXISTS public.event_gate_ticket_categories (
  gate_id uuid NOT NULL REFERENCES public.event_gates(id) ON DELETE CASCADE,
  event_ticket_id uuid NOT NULL REFERENCES public.event_tickets(id) ON DELETE CASCADE,
  PRIMARY KEY (gate_id, event_ticket_id)
);

ALTER TABLE public.event_checkin_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.event_gates ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.event_gate_ticket_categories ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.event_checkin_settings, public.event_gates, public.event_gate_ticket_categories FROM PUBLIC, anon, authenticated;

ALTER TABLE public.ticket_instances
  DROP CONSTRAINT IF EXISTS ticket_instances_status_check;
ALTER TABLE public.ticket_instances
  ADD CONSTRAINT ticket_instances_status_check CHECK (status IN ('active', 'revoked', 'expired'));

INSERT INTO public.event_checkin_settings (event_id, opens_at, closes_at)
SELECT event.id,
  (event.date::timestamp AT TIME ZONE 'Asia/Jakarta'),
  ((event.date + 2)::timestamp AT TIME ZONE 'Asia/Jakarta')
FROM public.events event
ON CONFLICT (event_id) DO NOTHING;

INSERT INTO public.event_gates (event_id, name)
SELECT DISTINCT ticket.event_id, 'Gate Utama'
FROM public.event_tickets ticket
WHERE ticket.status = 'active'
ON CONFLICT (event_id, name) DO NOTHING;

INSERT INTO public.event_gate_ticket_categories (gate_id, event_ticket_id)
SELECT gate.id, ticket.id
FROM public.event_gates gate
JOIN public.event_tickets ticket ON ticket.event_id = gate.event_id AND ticket.status = 'active'
WHERE gate.name = 'Gate Utama'
ON CONFLICT DO NOTHING;

CREATE OR REPLACE FUNCTION public.save_event_gate_settings(
  p_event_id uuid,
  p_opens_at timestamptz,
  p_closes_at timestamptz,
  p_gates jsonb
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  gate_item jsonb;
  category_id uuid;
  gate_id uuid;
  gate_name text;
BEGIN
  IF auth.role() <> 'service_role' THEN RAISE EXCEPTION 'Operasi harus dipanggil melalui service backend'; END IF;
  IF p_event_id IS NULL OR p_opens_at IS NULL OR p_closes_at IS NULL OR p_opens_at >= p_closes_at THEN
    RAISE EXCEPTION 'Periode check-in tidak valid';
  END IF;
  IF p_gates IS NULL OR jsonb_typeof(p_gates) <> 'array' THEN
    RAISE EXCEPTION 'Daftar Gate tidak valid';
  END IF;
  IF jsonb_array_length(p_gates) = 0 THEN
    RAISE EXCEPTION 'Tambahkan minimal satu Gate';
  END IF;
  IF EXISTS (
    SELECT lower(trim(value->>'name'))
    FROM jsonb_array_elements(p_gates)
    GROUP BY lower(trim(value->>'name'))
    HAVING count(*) > 1
  ) THEN RAISE EXCEPTION 'Nama Gate tidak boleh duplikat'; END IF;

  INSERT INTO public.event_checkin_settings (event_id, opens_at, closes_at, updated_at)
  VALUES (p_event_id, p_opens_at, p_closes_at, now())
  ON CONFLICT (event_id) DO UPDATE
  SET opens_at = EXCLUDED.opens_at, closes_at = EXCLUDED.closes_at, updated_at = now();

  DELETE FROM public.event_gates existing_gate
  WHERE existing_gate.event_id = p_event_id
    AND NOT EXISTS (
      SELECT 1 FROM jsonb_array_elements(p_gates) AS submitted_gate(value)
      WHERE submitted_gate.value->>'id' = existing_gate.id::text
    );
  UPDATE public.event_gates existing_gate
  SET name = 'pending-' || existing_gate.id::text
  WHERE existing_gate.event_id = p_event_id
    AND EXISTS (
      SELECT 1 FROM jsonb_array_elements(p_gates) AS submitted_gate(value)
      WHERE submitted_gate.value->>'id' = existing_gate.id::text
    );
  FOR gate_item IN SELECT value FROM jsonb_array_elements(p_gates)
  LOOP
    gate_name := trim(gate_item->>'name');
    IF gate_name IS NULL OR length(gate_name) < 1 OR length(gate_name) > 80 THEN
      RAISE EXCEPTION 'Nama Gate wajib diisi maksimal 80 karakter';
    END IF;
    IF gate_item->'category_ids' IS NULL OR jsonb_typeof(gate_item->'category_ids') <> 'array' THEN
      RAISE EXCEPTION 'Daftar kategori Gate tidak valid';
    END IF;
    IF jsonb_array_length(gate_item->'category_ids') = 0 THEN
      RAISE EXCEPTION 'Pilih minimal satu kategori tiket untuk setiap Gate';
    END IF;

    gate_id := NULL;
    IF nullif(gate_item->>'id', '') IS NOT NULL THEN
      SELECT id INTO gate_id FROM public.event_gates
      WHERE id = (gate_item->>'id')::uuid AND event_id = p_event_id;
    END IF;
    IF gate_id IS NULL THEN
      INSERT INTO public.event_gates (event_id, name)
      VALUES (p_event_id, gate_name)
      RETURNING id INTO gate_id;
    ELSE
      UPDATE public.event_gates SET name = gate_name WHERE id = gate_id;
      DELETE FROM public.event_gate_ticket_categories WHERE event_gate_ticket_categories.gate_id = gate_id;
    END IF;

    FOR category_id IN
      SELECT value::uuid FROM jsonb_array_elements_text(gate_item->'category_ids')
    LOOP
      IF NOT EXISTS (
        SELECT 1 FROM public.event_tickets
        WHERE id = category_id AND event_id = p_event_id AND status = 'active'
      ) THEN RAISE EXCEPTION 'Kategori tiket tidak aktif atau bukan milik Event ini'; END IF;
      INSERT INTO public.event_gate_ticket_categories (gate_id, event_ticket_id)
      VALUES (gate_id, category_id);
    END LOOP;
  END LOOP;
END;
$$;

REVOKE ALL ON FUNCTION public.save_event_gate_settings(uuid, timestamptz, timestamptz, jsonb) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.save_event_gate_settings(uuid, timestamptz, timestamptz, jsonb) TO service_role;

DROP FUNCTION IF EXISTS public.check_in_ticket(uuid, text);

CREATE FUNCTION public.check_in_ticket(p_event_id uuid, p_qr_token_hash text, p_gate_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  selected_ticket public.ticket_instances%ROWTYPE;
  selected_order public.ticket_orders%ROWTYPE;
  selected_event public.events%ROWTYPE;
  selected_gate public.event_gates%ROWTYPE;
  checkin_settings public.event_checkin_settings%ROWTYPE;
  ticket_category text;
  allowed_categories jsonb;
  scan_time timestamptz := now();
BEGIN
  SELECT instance.* INTO selected_ticket
  FROM public.ticket_instances instance
  WHERE instance.qr_token_hash = p_qr_token_hash
    AND instance.event_id = p_event_id
  FOR UPDATE;
  IF NOT FOUND THEN RETURN jsonb_build_object('ok', false, 'status', 'invalid', 'message', 'QR Code tidak ditemukan atau tiket tidak dapat digunakan.'); END IF;

  IF NOT public.jwt_has_role('admin')
    AND NOT (public.jwt_has_role('admin_qr') AND public.user_has_ticket_event_scope(p_event_id, 'admin_qr')) THEN
    RAISE EXCEPTION 'Akun tidak memiliki scope scan untuk Event ini';
  END IF;

  SELECT * INTO selected_event FROM public.events WHERE id = p_event_id;
  SELECT * INTO selected_order FROM public.ticket_orders WHERE id = selected_ticket.ticket_order_id;
  SELECT category.name INTO ticket_category
  FROM public.event_tickets category
  WHERE category.id = selected_ticket.event_ticket_id;

  IF selected_event.status = 'cancelled' THEN
    RETURN jsonb_build_object('ok', false, 'status', 'invalid', 'message', 'QR Code tidak ditemukan atau tiket tidak dapat digunakan.', 'event_title', selected_event.title);
  END IF;
  IF selected_ticket.checked_in_at IS NOT NULL THEN
    RETURN jsonb_build_object('ok', false, 'status', 'already_used', 'message', 'Tiket sudah digunakan', 'checked_in_at', selected_ticket.checked_in_at, 'ticket_id', selected_ticket.id, 'event_title', selected_event.title);
  END IF;
  IF selected_event.status = 'completed' THEN
    UPDATE public.ticket_instances
    SET status = 'expired', updated_at = scan_time
    WHERE id = selected_ticket.id AND status = 'active' AND checked_in_at IS NULL;
    RETURN jsonb_build_object('ok', false, 'status', 'checkin_closed', 'message', 'Periode check-in telah berakhir.', 'event_title', selected_event.title, 'expired', true);
  END IF;
  IF selected_ticket.status = 'expired' THEN
    RETURN jsonb_build_object('ok', false, 'status', 'checkin_closed', 'message', 'Periode check-in telah berakhir.', 'event_title', selected_event.title);
  END IF;
  IF selected_ticket.status <> 'active' OR selected_order.status <> 'Lunas' THEN
    RETURN jsonb_build_object('ok', false, 'status', 'invalid', 'message', 'QR Code tidak ditemukan atau tiket tidak dapat digunakan.');
  END IF;

  SELECT * INTO checkin_settings FROM public.event_checkin_settings WHERE event_id = p_event_id FOR SHARE;
  IF NOT FOUND THEN RAISE EXCEPTION 'Periode check-in Event belum diatur'; END IF;
  IF scan_time < checkin_settings.opens_at THEN
    RETURN jsonb_build_object('ok', false, 'status', 'checkin_not_open', 'message', 'Check-in belum dibuka.', 'event_title', selected_event.title, 'checkin_start', checkin_settings.opens_at);
  END IF;
  IF scan_time >= checkin_settings.closes_at THEN
    UPDATE public.ticket_instances
    SET status = 'expired', updated_at = scan_time
    WHERE id = selected_ticket.id AND status = 'active' AND checked_in_at IS NULL;
    RETURN jsonb_build_object('ok', false, 'status', 'checkin_closed', 'message', 'Periode check-in telah berakhir.', 'event_title', selected_event.title, 'expired', true);
  END IF;

  SELECT * INTO selected_gate FROM public.event_gates
  WHERE id = p_gate_id AND event_id = p_event_id
  FOR SHARE;
  IF NOT FOUND OR NOT EXISTS (
    SELECT 1 FROM public.event_gate_ticket_categories
    WHERE gate_id = p_gate_id AND event_ticket_id = selected_ticket.event_ticket_id
  ) THEN
    SELECT coalesce(jsonb_agg(category.name ORDER BY category.sort_order, category.name), '[]'::jsonb)
    INTO allowed_categories
    FROM public.event_gate_ticket_categories access
    JOIN public.event_tickets category ON category.id = access.event_ticket_id
    WHERE access.gate_id = p_gate_id;
    RETURN jsonb_build_object(
      'ok', false,
      'status', 'gate_mismatch',
      'message', 'Silakan menuju gate yang sesuai.',
      'ticket_category', ticket_category,
      'allowed_categories', allowed_categories
    );
  END IF;

  UPDATE public.ticket_instances
  SET checked_in_at = scan_time,
      checked_in_by = auth.uid(),
      check_in_source = selected_gate.name,
      updated_at = scan_time
  WHERE id = selected_ticket.id AND checked_in_at IS NULL AND status = 'active';
  IF NOT FOUND THEN
    RETURN jsonb_build_object('ok', false, 'status', 'already_used', 'message', 'Tiket sudah digunakan', 'ticket_id', selected_ticket.id, 'event_title', selected_event.title);
  END IF;

  RETURN jsonb_build_object(
    'ok', true,
    'status', 'checked_in',
    'ticket_id', selected_ticket.id,
    'checked_in_at', scan_time,
    'gate', selected_gate.name,
    'event_title', selected_event.title,
    'checkin_start', checkin_settings.opens_at,
    'ticket_category', ticket_category,
    'order_number', selected_order.order_number
  );
END;
$$;

REVOKE ALL ON FUNCTION public.check_in_ticket(uuid, text, uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.check_in_ticket(uuid, text, uuid) TO authenticated;


-- Source migration: 20261002230000_optional_ticket_gate_restrictions.sql
ALTER TABLE public.event_checkin_settings
  ADD COLUMN IF NOT EXISTS gates_enabled boolean NOT NULL DEFAULT false;

UPDATE public.event_checkin_settings settings
SET gates_enabled = (
  (SELECT count(*) FROM public.event_gates gate WHERE gate.event_id = settings.event_id) > 0
  AND (
    (SELECT count(*) FROM public.event_gates gate WHERE gate.event_id = settings.event_id) <> 1
    OR EXISTS (
      SELECT 1 FROM public.event_gates gate
      WHERE gate.event_id = settings.event_id AND gate.name <> 'Gate Utama'
    )
    OR EXISTS (
      SELECT 1
      FROM public.event_gates gate
      JOIN public.event_tickets category ON category.event_id = gate.event_id AND category.status = 'active'
      WHERE gate.event_id = settings.event_id
        AND NOT EXISTS (
          SELECT 1
          FROM public.event_gate_ticket_categories access
          WHERE access.gate_id = gate.id AND access.event_ticket_id = category.id
        )
    )
    OR EXISTS (
      SELECT 1
      FROM public.event_gate_ticket_categories access
      JOIN public.event_gates gate ON gate.id = access.gate_id
      JOIN public.event_tickets category ON category.id = access.event_ticket_id
      WHERE gate.event_id = settings.event_id AND category.status <> 'active'
    )
  )
);

CREATE OR REPLACE FUNCTION public.ensure_event_checkin_settings()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.event_checkin_settings (event_id, opens_at, closes_at)
  VALUES (
    NEW.id,
    (NEW.date::timestamp AT TIME ZONE 'Asia/Jakarta'),
    ((NEW.date + 2)::timestamp AT TIME ZONE 'Asia/Jakarta')
  )
  ON CONFLICT (event_id) DO NOTHING;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS ensure_event_checkin_settings_after_write ON public.events;
CREATE TRIGGER ensure_event_checkin_settings_after_write
AFTER INSERT OR UPDATE OF date ON public.events
FOR EACH ROW EXECUTE FUNCTION public.ensure_event_checkin_settings();

INSERT INTO public.event_checkin_settings (event_id, opens_at, closes_at)
SELECT event.id,
  (event.date::timestamp AT TIME ZONE 'Asia/Jakarta'),
  ((event.date + 2)::timestamp AT TIME ZONE 'Asia/Jakarta')
FROM public.events event
ON CONFLICT (event_id) DO NOTHING;

CREATE OR REPLACE FUNCTION public.save_event_gate_settings(
  p_event_id uuid,
  p_opens_at timestamptz,
  p_closes_at timestamptz,
  p_gates jsonb,
  p_gates_enabled boolean
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  gate_item jsonb;
  category_id uuid;
  gate_id uuid;
  gate_name text;
BEGIN
  IF auth.role() <> 'service_role' THEN RAISE EXCEPTION 'Operasi harus dipanggil melalui service backend'; END IF;
  IF p_event_id IS NULL OR p_opens_at IS NULL OR p_closes_at IS NULL OR p_opens_at >= p_closes_at THEN
    RAISE EXCEPTION 'Periode check-in tidak valid';
  END IF;
  IF p_gates_enabled IS NULL OR p_gates IS NULL OR jsonb_typeof(p_gates) <> 'array' THEN
    RAISE EXCEPTION 'Pengaturan Gate tidak valid';
  END IF;
  IF p_gates_enabled AND jsonb_array_length(p_gates) = 0 THEN
    RAISE EXCEPTION 'Tambahkan minimal satu Gate';
  END IF;
  IF p_gates_enabled AND EXISTS (
    SELECT lower(trim(value->>'name'))
    FROM jsonb_array_elements(p_gates)
    GROUP BY lower(trim(value->>'name'))
    HAVING count(*) > 1
  ) THEN RAISE EXCEPTION 'Nama Gate tidak boleh duplikat'; END IF;

  INSERT INTO public.event_checkin_settings (event_id, opens_at, closes_at, gates_enabled, updated_at)
  VALUES (p_event_id, p_opens_at, p_closes_at, p_gates_enabled, now())
  ON CONFLICT (event_id) DO UPDATE
  SET opens_at = EXCLUDED.opens_at,
      closes_at = EXCLUDED.closes_at,
      gates_enabled = EXCLUDED.gates_enabled,
      updated_at = now();

  IF NOT p_gates_enabled THEN
    DELETE FROM public.event_gates WHERE event_id = p_event_id;
    RETURN;
  END IF;

  DELETE FROM public.event_gates existing_gate
  WHERE existing_gate.event_id = p_event_id
    AND NOT EXISTS (
      SELECT 1 FROM jsonb_array_elements(p_gates) AS submitted_gate(value)
      WHERE submitted_gate.value->>'id' = existing_gate.id::text
    );
  UPDATE public.event_gates existing_gate
  SET name = 'pending-' || existing_gate.id::text
  WHERE existing_gate.event_id = p_event_id
    AND EXISTS (
      SELECT 1 FROM jsonb_array_elements(p_gates) AS submitted_gate(value)
      WHERE submitted_gate.value->>'id' = existing_gate.id::text
    );

  FOR gate_item IN SELECT value FROM jsonb_array_elements(p_gates)
  LOOP
    gate_name := trim(gate_item->>'name');
    IF gate_name IS NULL OR length(gate_name) < 1 OR length(gate_name) > 80 THEN
      RAISE EXCEPTION 'Nama Gate wajib diisi maksimal 80 karakter';
    END IF;
    IF gate_item->'category_ids' IS NULL OR jsonb_typeof(gate_item->'category_ids') <> 'array'
      OR jsonb_array_length(gate_item->'category_ids') = 0 THEN
      RAISE EXCEPTION 'Pilih minimal satu kategori tiket untuk setiap Gate';
    END IF;

    gate_id := NULL;
    IF nullif(gate_item->>'id', '') IS NOT NULL THEN
      SELECT id INTO gate_id FROM public.event_gates
      WHERE id = (gate_item->>'id')::uuid AND event_id = p_event_id;
    END IF;
    IF gate_id IS NULL THEN
      INSERT INTO public.event_gates (event_id, name)
      VALUES (p_event_id, gate_name)
      RETURNING id INTO gate_id;
    ELSE
      UPDATE public.event_gates SET name = gate_name WHERE id = gate_id;
      DELETE FROM public.event_gate_ticket_categories WHERE event_gate_ticket_categories.gate_id = gate_id;
    END IF;

    FOR category_id IN
      SELECT value::uuid FROM jsonb_array_elements_text(gate_item->'category_ids')
    LOOP
      IF NOT EXISTS (
        SELECT 1 FROM public.event_tickets
        WHERE id = category_id AND event_id = p_event_id AND status = 'active'
      ) THEN RAISE EXCEPTION 'Kategori tiket tidak aktif atau bukan milik Event ini'; END IF;
      INSERT INTO public.event_gate_ticket_categories (gate_id, event_ticket_id)
      VALUES (gate_id, category_id);
    END LOOP;
  END LOOP;
END;
$$;

REVOKE ALL ON FUNCTION public.save_event_gate_settings(uuid, timestamptz, timestamptz, jsonb, boolean) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.save_event_gate_settings(uuid, timestamptz, timestamptz, jsonb, boolean) TO service_role;

CREATE OR REPLACE FUNCTION public.check_in_ticket(p_event_id uuid, p_qr_token_hash text, p_gate_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  selected_ticket public.ticket_instances%ROWTYPE;
  selected_order public.ticket_orders%ROWTYPE;
  selected_event public.events%ROWTYPE;
  selected_gate public.event_gates%ROWTYPE;
  checkin_settings public.event_checkin_settings%ROWTYPE;
  ticket_category text;
  allowed_categories jsonb;
  checkin_gate text := 'Semua Kategori';
  scan_time timestamptz := now();
BEGIN
  SELECT instance.* INTO selected_ticket
  FROM public.ticket_instances instance
  WHERE instance.qr_token_hash = p_qr_token_hash
    AND instance.event_id = p_event_id
  FOR UPDATE;
  IF NOT FOUND THEN RETURN jsonb_build_object('ok', false, 'status', 'invalid', 'message', 'QR Code tidak ditemukan atau tiket tidak dapat digunakan.'); END IF;

  IF NOT public.jwt_has_role('admin')
    AND NOT (public.jwt_has_role('admin_qr') AND public.user_has_ticket_event_scope(p_event_id, 'admin_qr')) THEN
    RAISE EXCEPTION 'Akun tidak memiliki scope scan untuk Event ini';
  END IF;

  SELECT * INTO selected_event FROM public.events WHERE id = p_event_id;
  SELECT * INTO selected_order FROM public.ticket_orders WHERE id = selected_ticket.ticket_order_id;
  SELECT category.name INTO ticket_category
  FROM public.event_tickets category
  WHERE category.id = selected_ticket.event_ticket_id;

  IF selected_event.status = 'cancelled' THEN
    RETURN jsonb_build_object('ok', false, 'status', 'invalid', 'message', 'QR Code tidak ditemukan atau tiket tidak dapat digunakan.', 'event_title', selected_event.title);
  END IF;
  IF selected_ticket.checked_in_at IS NOT NULL THEN
    RETURN jsonb_build_object('ok', false, 'status', 'already_used', 'message', 'Tiket sudah digunakan', 'checked_in_at', selected_ticket.checked_in_at, 'ticket_id', selected_ticket.id, 'event_title', selected_event.title);
  END IF;
  IF selected_event.status = 'completed' THEN
    UPDATE public.ticket_instances
    SET status = 'expired', updated_at = scan_time
    WHERE id = selected_ticket.id AND status = 'active' AND checked_in_at IS NULL;
    RETURN jsonb_build_object('ok', false, 'status', 'checkin_closed', 'message', 'Periode check-in telah berakhir.', 'event_title', selected_event.title, 'expired', true);
  END IF;
  IF selected_ticket.status = 'expired' THEN
    RETURN jsonb_build_object('ok', false, 'status', 'checkin_closed', 'message', 'Periode check-in telah berakhir.', 'event_title', selected_event.title);
  END IF;
  IF selected_ticket.status <> 'active' OR selected_order.status <> 'Lunas' THEN
    RETURN jsonb_build_object('ok', false, 'status', 'invalid', 'message', 'QR Code tidak ditemukan atau tiket tidak dapat digunakan.');
  END IF;

  SELECT * INTO checkin_settings FROM public.event_checkin_settings WHERE event_id = p_event_id FOR SHARE;
  IF NOT FOUND THEN RAISE EXCEPTION 'Periode check-in Event belum diatur'; END IF;
  IF scan_time < checkin_settings.opens_at THEN
    RETURN jsonb_build_object('ok', false, 'status', 'checkin_not_open', 'message', 'Check-in belum dibuka.', 'event_title', selected_event.title, 'checkin_start', checkin_settings.opens_at);
  END IF;
  IF scan_time >= checkin_settings.closes_at THEN
    UPDATE public.ticket_instances
    SET status = 'expired', updated_at = scan_time
    WHERE id = selected_ticket.id AND status = 'active' AND checked_in_at IS NULL;
    RETURN jsonb_build_object('ok', false, 'status', 'checkin_closed', 'message', 'Periode check-in telah berakhir.', 'event_title', selected_event.title, 'expired', true);
  END IF;

  IF checkin_settings.gates_enabled THEN
    SELECT * INTO selected_gate FROM public.event_gates
    WHERE id = p_gate_id AND event_id = p_event_id
    FOR SHARE;
    IF NOT FOUND OR NOT EXISTS (
      SELECT 1 FROM public.event_gate_ticket_categories
      WHERE gate_id = p_gate_id AND event_ticket_id = selected_ticket.event_ticket_id
    ) THEN
      SELECT coalesce(jsonb_agg(category.name ORDER BY category.sort_order, category.name), '[]'::jsonb)
      INTO allowed_categories
      FROM public.event_gate_ticket_categories access
      JOIN public.event_tickets category ON category.id = access.event_ticket_id
      WHERE access.gate_id = p_gate_id;
      RETURN jsonb_build_object(
        'ok', false,
        'status', 'gate_mismatch',
        'message', 'Silakan menuju gate yang sesuai.',
        'ticket_category', ticket_category,
        'allowed_categories', allowed_categories
      );
    END IF;
    checkin_gate := selected_gate.name;
  END IF;

  UPDATE public.ticket_instances
  SET checked_in_at = scan_time,
      checked_in_by = auth.uid(),
      check_in_source = checkin_gate,
      updated_at = scan_time
  WHERE id = selected_ticket.id AND checked_in_at IS NULL AND status = 'active';
  IF NOT FOUND THEN
    RETURN jsonb_build_object('ok', false, 'status', 'already_used', 'message', 'Tiket sudah digunakan', 'ticket_id', selected_ticket.id, 'event_title', selected_event.title);
  END IF;

  RETURN jsonb_build_object(
    'ok', true,
    'status', 'checked_in',
    'ticket_id', selected_ticket.id,
    'checked_in_at', scan_time,
    'gate', checkin_gate,
    'event_title', selected_event.title,
    'checkin_start', checkin_settings.opens_at,
    'ticket_category', ticket_category,
    'order_number', selected_order.order_number
  );
END;
$$;


-- Source migration: 20261002235500_default_checkin_event_day.sql
ALTER TABLE public.event_checkin_settings
  ADD COLUMN IF NOT EXISTS time_restricted boolean NOT NULL DEFAULT false;

UPDATE public.event_checkin_settings settings
SET time_restricted = NOT (
  settings.opens_at = (event.date::timestamp AT TIME ZONE 'Asia/Jakarta')
  AND settings.closes_at = ((event.date + 2)::timestamp AT TIME ZONE 'Asia/Jakarta')
)
FROM public.events event
WHERE event.id = settings.event_id;

UPDATE public.event_checkin_settings settings
SET opens_at = (event.date::timestamp AT TIME ZONE 'Asia/Jakarta'),
    closes_at = ((event.date + 1)::timestamp AT TIME ZONE 'Asia/Jakarta'),
    updated_at = now()
FROM public.events event
WHERE event.id = settings.event_id
  AND NOT settings.time_restricted;

CREATE OR REPLACE FUNCTION public.ensure_event_checkin_settings()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.event_checkin_settings AS current_settings (event_id, opens_at, closes_at)
  VALUES (
    NEW.id,
    (NEW.date::timestamp AT TIME ZONE 'Asia/Jakarta'),
    ((NEW.date + 1)::timestamp AT TIME ZONE 'Asia/Jakarta')
  )
  ON CONFLICT (event_id) DO UPDATE
  SET opens_at = CASE
        WHEN current_settings.time_restricted
          THEN (NEW.date::timestamp + (current_settings.opens_at AT TIME ZONE 'Asia/Jakarta')::time) AT TIME ZONE 'Asia/Jakarta'
        ELSE (NEW.date::timestamp AT TIME ZONE 'Asia/Jakarta')
      END,
      closes_at = CASE
        WHEN current_settings.time_restricted
          THEN (NEW.date::timestamp + (current_settings.closes_at AT TIME ZONE 'Asia/Jakarta')::time) AT TIME ZONE 'Asia/Jakarta'
        ELSE ((NEW.date + 1)::timestamp AT TIME ZONE 'Asia/Jakarta')
      END,
      updated_at = now();
  RETURN NEW;
END;
$$;

DROP FUNCTION IF EXISTS public.save_event_gate_settings(uuid, timestamptz, timestamptz, jsonb);
DROP FUNCTION IF EXISTS public.save_event_gate_settings(uuid, timestamptz, timestamptz, jsonb, boolean);

CREATE FUNCTION public.save_event_gate_settings(
  p_event_id uuid,
  p_opens_at timestamptz,
  p_closes_at timestamptz,
  p_gates jsonb,
  p_gates_enabled boolean,
  p_time_restricted boolean
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  gate_item jsonb;
  category_id uuid;
  gate_id uuid;
  gate_name text;
BEGIN
  IF auth.role() <> 'service_role' THEN RAISE EXCEPTION 'Operasi harus dipanggil melalui service backend'; END IF;
  IF p_event_id IS NULL OR p_opens_at IS NULL OR p_closes_at IS NULL OR p_opens_at >= p_closes_at THEN
    RAISE EXCEPTION 'Periode check-in tidak valid';
  END IF;
  IF p_gates_enabled IS NULL OR p_time_restricted IS NULL OR p_gates IS NULL OR jsonb_typeof(p_gates) <> 'array' THEN
    RAISE EXCEPTION 'Pengaturan Gate atau waktu check-in tidak valid';
  END IF;
  IF p_gates_enabled AND jsonb_array_length(p_gates) = 0 THEN
    RAISE EXCEPTION 'Tambahkan minimal satu Gate';
  END IF;
  IF p_gates_enabled AND EXISTS (
    SELECT lower(trim(value->>'name'))
    FROM jsonb_array_elements(p_gates)
    GROUP BY lower(trim(value->>'name'))
    HAVING count(*) > 1
  ) THEN RAISE EXCEPTION 'Nama Gate tidak boleh duplikat'; END IF;

  INSERT INTO public.event_checkin_settings (event_id, opens_at, closes_at, gates_enabled, time_restricted, updated_at)
  VALUES (p_event_id, p_opens_at, p_closes_at, p_gates_enabled, p_time_restricted, now())
  ON CONFLICT (event_id) DO UPDATE
  SET opens_at = EXCLUDED.opens_at,
      closes_at = EXCLUDED.closes_at,
      gates_enabled = EXCLUDED.gates_enabled,
      time_restricted = EXCLUDED.time_restricted,
      updated_at = now();

  IF NOT p_gates_enabled THEN
    DELETE FROM public.event_gates WHERE event_id = p_event_id;
    RETURN;
  END IF;

  DELETE FROM public.event_gates existing_gate
  WHERE existing_gate.event_id = p_event_id
    AND NOT EXISTS (
      SELECT 1 FROM jsonb_array_elements(p_gates) AS submitted_gate(value)
      WHERE submitted_gate.value->>'id' = existing_gate.id::text
    );
  UPDATE public.event_gates existing_gate
  SET name = 'pending-' || existing_gate.id::text
  WHERE existing_gate.event_id = p_event_id
    AND EXISTS (
      SELECT 1 FROM jsonb_array_elements(p_gates) AS submitted_gate(value)
      WHERE submitted_gate.value->>'id' = existing_gate.id::text
    );

  FOR gate_item IN SELECT value FROM jsonb_array_elements(p_gates)
  LOOP
    gate_name := trim(gate_item->>'name');
    IF gate_name IS NULL OR length(gate_name) < 1 OR length(gate_name) > 80 THEN
      RAISE EXCEPTION 'Nama Gate wajib diisi maksimal 80 karakter';
    END IF;
    IF gate_item->'category_ids' IS NULL OR jsonb_typeof(gate_item->'category_ids') <> 'array'
      OR jsonb_array_length(gate_item->'category_ids') = 0 THEN
      RAISE EXCEPTION 'Pilih minimal satu kategori tiket untuk setiap Gate';
    END IF;

    gate_id := NULL;
    IF nullif(gate_item->>'id', '') IS NOT NULL THEN
      SELECT id INTO gate_id FROM public.event_gates
      WHERE id = (gate_item->>'id')::uuid AND event_id = p_event_id;
    END IF;
    IF gate_id IS NULL THEN
      INSERT INTO public.event_gates (event_id, name)
      VALUES (p_event_id, gate_name)
      RETURNING id INTO gate_id;
    ELSE
      UPDATE public.event_gates SET name = gate_name WHERE id = gate_id;
      DELETE FROM public.event_gate_ticket_categories WHERE event_gate_ticket_categories.gate_id = gate_id;
    END IF;

    FOR category_id IN
      SELECT value::uuid FROM jsonb_array_elements_text(gate_item->'category_ids')
    LOOP
      IF NOT EXISTS (
        SELECT 1 FROM public.event_tickets
        WHERE id = category_id AND event_id = p_event_id AND status = 'active'
      ) THEN RAISE EXCEPTION 'Kategori tiket tidak aktif atau bukan milik Event ini'; END IF;
      INSERT INTO public.event_gate_ticket_categories (gate_id, event_ticket_id)
      VALUES (gate_id, category_id);
    END LOOP;
  END LOOP;
END;
$$;

REVOKE ALL ON FUNCTION public.save_event_gate_settings(uuid, timestamptz, timestamptz, jsonb, boolean, boolean) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.save_event_gate_settings(uuid, timestamptz, timestamptz, jsonb, boolean, boolean) TO service_role;


-- Source migration: 20261003000000_preserve_disabled_gate_config.sql
CREATE OR REPLACE FUNCTION public.save_event_gate_settings(
  p_event_id uuid,
  p_opens_at timestamptz,
  p_closes_at timestamptz,
  p_gates jsonb,
  p_gates_enabled boolean,
  p_time_restricted boolean
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  gate_item jsonb;
  category_id uuid;
  gate_id uuid;
  gate_name text;
BEGIN
  IF auth.role() <> 'service_role' THEN RAISE EXCEPTION 'Operasi harus dipanggil melalui service backend'; END IF;
  IF p_event_id IS NULL OR p_opens_at IS NULL OR p_closes_at IS NULL OR p_opens_at >= p_closes_at THEN
    RAISE EXCEPTION 'Periode check-in tidak valid';
  END IF;
  IF p_gates_enabled IS NULL OR p_time_restricted IS NULL OR p_gates IS NULL OR jsonb_typeof(p_gates) <> 'array' THEN
    RAISE EXCEPTION 'Pengaturan Gate atau waktu check-in tidak valid';
  END IF;
  IF p_gates_enabled AND jsonb_array_length(p_gates) = 0 THEN
    RAISE EXCEPTION 'Tambahkan minimal satu Gate';
  END IF;
  IF p_gates_enabled AND EXISTS (
    SELECT lower(trim(value->>'name'))
    FROM jsonb_array_elements(p_gates)
    GROUP BY lower(trim(value->>'name'))
    HAVING count(*) > 1
  ) THEN RAISE EXCEPTION 'Nama Gate tidak boleh duplikat'; END IF;

  INSERT INTO public.event_checkin_settings (event_id, opens_at, closes_at, gates_enabled, time_restricted, updated_at)
  VALUES (p_event_id, p_opens_at, p_closes_at, p_gates_enabled, p_time_restricted, now())
  ON CONFLICT (event_id) DO UPDATE
  SET opens_at = EXCLUDED.opens_at,
      closes_at = EXCLUDED.closes_at,
      gates_enabled = EXCLUDED.gates_enabled,
      time_restricted = EXCLUDED.time_restricted,
      updated_at = now();

  IF NOT p_gates_enabled THEN RETURN; END IF;

  DELETE FROM public.event_gates existing_gate
  WHERE existing_gate.event_id = p_event_id
    AND NOT EXISTS (
      SELECT 1 FROM jsonb_array_elements(p_gates) AS submitted_gate(value)
      WHERE submitted_gate.value->>'id' = existing_gate.id::text
    );
  UPDATE public.event_gates existing_gate
  SET name = 'pending-' || existing_gate.id::text
  WHERE existing_gate.event_id = p_event_id
    AND EXISTS (
      SELECT 1 FROM jsonb_array_elements(p_gates) AS submitted_gate(value)
      WHERE submitted_gate.value->>'id' = existing_gate.id::text
    );

  FOR gate_item IN SELECT value FROM jsonb_array_elements(p_gates)
  LOOP
    gate_name := trim(gate_item->>'name');
    IF gate_name IS NULL OR length(gate_name) < 1 OR length(gate_name) > 80 THEN
      RAISE EXCEPTION 'Nama Gate wajib diisi maksimal 80 karakter';
    END IF;
    IF gate_item->'category_ids' IS NULL OR jsonb_typeof(gate_item->'category_ids') <> 'array'
      OR jsonb_array_length(gate_item->'category_ids') = 0 THEN
      RAISE EXCEPTION 'Pilih minimal satu kategori tiket untuk setiap Gate';
    END IF;

    gate_id := NULL;
    IF nullif(gate_item->>'id', '') IS NOT NULL THEN
      SELECT id INTO gate_id FROM public.event_gates
      WHERE id = (gate_item->>'id')::uuid AND event_id = p_event_id;
    END IF;
    IF gate_id IS NULL THEN
      INSERT INTO public.event_gates (event_id, name)
      VALUES (p_event_id, gate_name)
      RETURNING id INTO gate_id;
    ELSE
      UPDATE public.event_gates SET name = gate_name WHERE id = gate_id;
      DELETE FROM public.event_gate_ticket_categories WHERE event_gate_ticket_categories.gate_id = gate_id;
    END IF;

    FOR category_id IN
      SELECT value::uuid FROM jsonb_array_elements_text(gate_item->'category_ids')
    LOOP
      IF NOT EXISTS (
        SELECT 1 FROM public.event_tickets
        WHERE id = category_id AND event_id = p_event_id AND status = 'active'
      ) THEN RAISE EXCEPTION 'Kategori tiket tidak aktif atau bukan milik Event ini'; END IF;
      INSERT INTO public.event_gate_ticket_categories (gate_id, event_ticket_id)
      VALUES (gate_id, category_id);
    END LOOP;
  END LOOP;
END;
$$;


-- Source migration: 20261003020000_enable_ticket_order_notifications.sql
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime'
      AND schemaname = 'public'
      AND tablename = 'ticket_orders'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.ticket_orders;
  END IF;
END;
$$;


-- Source migration: 20261003030000_ticket_payment_email_logs.sql
CREATE TABLE IF NOT EXISTS public.ticket_email_logs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id uuid NOT NULL UNIQUE REFERENCES public.ticket_orders(id) ON DELETE CASCADE,
  recipient_email text,
  email_type text NOT NULL DEFAULT 'payment_confirmation' CHECK (email_type = 'payment_confirmation'),
  status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'sent', 'failed', 'skipped')),
  resend_message_id text,
  error_message text,
  created_at timestamptz NOT NULL DEFAULT now(),
  sent_at timestamptz
);

ALTER TABLE public.ticket_email_logs ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.ticket_email_logs FROM PUBLIC, anon, authenticated;
GRANT SELECT, INSERT, UPDATE ON public.ticket_email_logs TO service_role;

-- Push subscription base table (missing from the original migration chain).
CREATE TABLE IF NOT EXISTS public.push_subscriptions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  app_identity text NOT NULL DEFAULT 'public',
  endpoint text NOT NULL UNIQUE,
  p256dh text NOT NULL,
  auth text NOT NULL,
  expiration_time timestamptz,
  guest_token_hash text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT push_subscriptions_app_identity_check CHECK (app_identity IN ('public', 'admin', 'member')),
  CONSTRAINT push_subscriptions_owner_check CHECK ((user_id IS NOT NULL AND guest_token_hash IS NULL) OR (user_id IS NULL AND guest_token_hash IS NOT NULL))
);
ALTER TABLE public.push_subscriptions ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.push_subscriptions FROM PUBLIC, anon, authenticated;
GRANT ALL ON public.push_subscriptions TO service_role;
CREATE INDEX IF NOT EXISTS idx_push_subscriptions_app_identity_user_id ON public.push_subscriptions (app_identity, user_id);
CREATE INDEX IF NOT EXISTS idx_push_subscriptions_guest_token_hash ON public.push_subscriptions (guest_token_hash) WHERE guest_token_hash IS NOT NULL;

-- Source migration: 20261003050000_automate_event_open_mic_push_notifications.sql
CREATE EXTENSION IF NOT EXISTS pg_cron;
CREATE EXTENSION IF NOT EXISTS pg_net;

CREATE TABLE IF NOT EXISTS public.push_notification_automation_cycles (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  entity_type text NOT NULL CHECK (entity_type IN ('event', 'open-mic')),
  entity_id uuid NOT NULL,
  published_at timestamptz NOT NULL DEFAULT now(),
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX IF NOT EXISTS push_notification_automation_one_active_cycle
  ON public.push_notification_automation_cycles (entity_type, entity_id)
  WHERE is_active;

CREATE TABLE IF NOT EXISTS public.push_notification_automation_deliveries (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  cycle_id uuid NOT NULL REFERENCES public.push_notification_automation_cycles(id) ON DELETE CASCADE,
  stage_key text NOT NULL,
  notification_id text NOT NULL,
  scheduled_at timestamptz NOT NULL,
  status text NOT NULL DEFAULT 'sending' CHECK (status IN ('sending', 'sent', 'failed')),
  sent_count integer NOT NULL DEFAULT 0,
  error_message text,
  created_at timestamptz NOT NULL DEFAULT now(),
  completed_at timestamptz,
  UNIQUE (cycle_id, stage_key)
);

ALTER TABLE public.push_notification_automation_cycles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.push_notification_automation_deliveries ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.push_notification_automation_cycles FROM anon, authenticated;
REVOKE ALL ON public.push_notification_automation_deliveries FROM anon, authenticated;

CREATE OR REPLACE FUNCTION public.track_public_push_notification_cycle()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
DECLARE
  item_kind text := CASE WHEN TG_TABLE_NAME = 'events' THEN 'event' ELSE 'open-mic' END;
BEGIN
  IF TG_OP = 'DELETE' THEN
    UPDATE public.push_notification_automation_cycles
    SET is_active = false
    WHERE entity_type = item_kind AND entity_id = OLD.id AND is_active;
    RETURN OLD;
  END IF;

  IF TG_OP = 'INSERT' THEN
    IF NEW.published THEN
      INSERT INTO public.push_notification_automation_cycles (entity_type, entity_id, published_at, is_active)
      VALUES (item_kind, NEW.id, now(), true);
    END IF;
  ELSIF OLD.published AND NOT NEW.published THEN
    UPDATE public.push_notification_automation_cycles
    SET is_active = false
    WHERE entity_type = item_kind AND entity_id = NEW.id AND is_active;
  ELSIF NEW.published AND NOT OLD.published THEN
    UPDATE public.push_notification_automation_cycles
    SET is_active = false
    WHERE entity_type = item_kind AND entity_id = NEW.id AND is_active;
    INSERT INTO public.push_notification_automation_cycles (entity_type, entity_id, published_at, is_active)
    VALUES (item_kind, NEW.id, now(), true);
  END IF;
  RETURN NEW;
END;
$$;

REVOKE ALL ON FUNCTION public.track_public_push_notification_cycle() FROM PUBLIC, anon, authenticated;

DROP TRIGGER IF EXISTS track_event_public_push_notification_cycle ON public.events;
CREATE TRIGGER track_event_public_push_notification_cycle
AFTER INSERT OR UPDATE OF published OR DELETE ON public.events
FOR EACH ROW EXECUTE FUNCTION public.track_public_push_notification_cycle();

DROP TRIGGER IF EXISTS track_open_mic_public_push_notification_cycle ON public.open_mics;
CREATE TRIGGER track_open_mic_public_push_notification_cycle
AFTER INSERT OR UPDATE OF published OR DELETE ON public.open_mics
FOR EACH ROW EXECUTE FUNCTION public.track_public_push_notification_cycle();

INSERT INTO public.push_notification_automation_cycles (entity_type, entity_id, published_at, is_active)
SELECT 'event', id, now(), true FROM public.events WHERE published
ON CONFLICT (entity_type, entity_id) WHERE is_active DO NOTHING;

INSERT INTO public.push_notification_automation_cycles (entity_type, entity_id, published_at, is_active)
SELECT 'open-mic', id, now(), true FROM public.open_mics WHERE published
ON CONFLICT (entity_type, entity_id) WHERE is_active DO NOTHING;

CREATE OR REPLACE FUNCTION public.invoke_automated_public_event_push()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public, net, vault
AS $$
DECLARE
  project_url text;
  service_role_key text;
BEGIN
  SELECT decrypted_secret INTO project_url
  FROM vault.decrypted_secrets
  WHERE name = 'event_open_mic_push_project_url'
  LIMIT 1;

  SELECT decrypted_secret INTO service_role_key
  FROM vault.decrypted_secrets
  WHERE name = 'event_open_mic_push_service_role_key'
  LIMIT 1;

  IF COALESCE(project_url, '') = '' OR COALESCE(service_role_key, '') = '' THEN
    RAISE WARNING 'Event/Open Mic push cron awaits the project URL and service-role key in Supabase Vault.';
    RETURN;
  END IF;

  PERFORM net.http_post(
    url := rtrim(project_url, '/') || '/functions/v1/automate-public-event-push',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || service_role_key,
      'apikey', service_role_key
    ),
    body := '{}'::jsonb,
    timeout_milliseconds := 10000
  );
END;
$$;

REVOKE ALL ON FUNCTION public.invoke_automated_public_event_push() FROM PUBLIC, anon, authenticated;

DO $$
DECLARE
  existing_job_id bigint;
BEGIN
  SELECT jobid INTO existing_job_id
  FROM cron.job
  WHERE jobname = 'automate-public-event-push';
  IF existing_job_id IS NOT NULL THEN
    PERFORM cron.unschedule(existing_job_id);
  END IF;
  PERFORM cron.schedule(
    'automate-public-event-push',
    '*/15 * * * *',
    'SELECT public.invoke_automated_public_event_push();'
  );
END;
$$;


-- Source migration: 20261004090000_isolate_pwa_push_subscriptions.sql
ALTER TABLE public.push_subscriptions
  ADD COLUMN IF NOT EXISTS app_identity text NOT NULL DEFAULT 'public';

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conrelid = 'public.push_subscriptions'::regclass
      AND conname = 'push_subscriptions_app_identity_check'
  ) THEN
    ALTER TABLE public.push_subscriptions
      ADD CONSTRAINT push_subscriptions_app_identity_check
      CHECK (app_identity IN ('public', 'admin', 'member'));
  END IF;
END;
$$;

CREATE INDEX IF NOT EXISTS idx_push_subscriptions_app_identity_user_id
  ON public.push_subscriptions (app_identity, user_id);

ALTER TABLE public.push_notification_automation_deliveries
  ADD COLUMN IF NOT EXISTS target_key text NOT NULL DEFAULT 'public';

ALTER TABLE public.push_notification_automation_deliveries
  DROP CONSTRAINT IF EXISTS push_notification_automation_deliveries_cycle_id_stage_key_key;

CREATE UNIQUE INDEX IF NOT EXISTS push_notification_automation_deliveries_cycle_stage_target
  ON public.push_notification_automation_deliveries (cycle_id, stage_key, target_key);

CREATE TABLE IF NOT EXISTS public.push_evaluator_assignment_deliveries (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  assignment_id uuid NOT NULL REFERENCES public.evaluator_assignments(id) ON DELETE CASCADE,
  target_subscription_id uuid NOT NULL REFERENCES public.push_subscriptions(id) ON DELETE CASCADE,
  status text NOT NULL DEFAULT 'sending' CHECK (status IN ('sending', 'sent', 'failed')),
  error_message text,
  created_at timestamptz NOT NULL DEFAULT now(),
  completed_at timestamptz,
  UNIQUE (assignment_id, target_subscription_id)
);

ALTER TABLE public.push_evaluator_assignment_deliveries ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.push_evaluator_assignment_deliveries FROM anon, authenticated;

ALTER TABLE public.evaluator_assignments
  ADD COLUMN IF NOT EXISTS notification_pending_at timestamptz;

CREATE OR REPLACE FUNCTION public.mark_evaluator_assignment_push_pending()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
BEGIN
  IF NEW.status = 'active' THEN
    IF TG_OP = 'INSERT' THEN
      NEW.notification_pending_at := now();
    ELSIF OLD.status IS DISTINCT FROM 'active' THEN
      NEW.notification_pending_at := now();
    END IF;
  ELSIF NEW.status <> 'active' THEN
    NEW.notification_pending_at := NULL;
  END IF;
  RETURN NEW;
END;
$$;

REVOKE ALL ON FUNCTION public.mark_evaluator_assignment_push_pending() FROM PUBLIC, anon, authenticated;

DROP TRIGGER IF EXISTS mark_evaluator_assignment_push_pending ON public.evaluator_assignments;
CREATE TRIGGER mark_evaluator_assignment_push_pending
BEFORE INSERT OR UPDATE OF status ON public.evaluator_assignments
FOR EACH ROW EXECUTE FUNCTION public.mark_evaluator_assignment_push_pending();


-- Source migration: 20261004100000_add_event_documentation_photos.sql
ALTER TABLE public.events
ADD COLUMN IF NOT EXISTS documentation_photos text[] NOT NULL DEFAULT '{}';

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'events_documentation_photos_max_15'
      AND conrelid = 'public.events'::regclass
  ) THEN
    ALTER TABLE public.events
    ADD CONSTRAINT events_documentation_photos_max_15
    CHECK (cardinality(documentation_photos) <= 15);
  END IF;
END;
$$;

NOTIFY pgrst, 'reload schema';


-- Source migration: 20261004110000_ensure_event_documentation_schema.sql
ALTER TABLE public.events
ADD COLUMN IF NOT EXISTS documentation_photos text[] NOT NULL DEFAULT '{}';

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'events_documentation_photos_max_15'
      AND conrelid = 'public.events'::regclass
  ) THEN
    ALTER TABLE public.events
    ADD CONSTRAINT events_documentation_photos_max_15
    CHECK (cardinality(documentation_photos) <= 15);
  END IF;
END;
$$;

NOTIFY pgrst, 'reload schema';


-- Source migration: 20261004114000_ticketing_free_pass.sql
ALTER TABLE public.ticket_orders
  ADD COLUMN IF NOT EXISTS order_type text NOT NULL DEFAULT 'paid',
  ADD COLUMN IF NOT EXISTS free_pass_reason text,
  ADD COLUMN IF NOT EXISTS issued_by uuid REFERENCES auth.users(id) ON DELETE SET NULL;

ALTER TABLE public.ticket_orders
  DROP CONSTRAINT IF EXISTS ticket_orders_order_type_check;
ALTER TABLE public.ticket_orders
  ADD CONSTRAINT ticket_orders_order_type_check CHECK (
    (order_type = 'paid' AND free_pass_reason IS NULL)
    OR (order_type = 'free_pass'
      AND nullif(trim(free_pass_reason), '') IS NOT NULL
      AND issued_by IS NOT NULL)
  );

ALTER TABLE public.ticket_email_logs
  DROP CONSTRAINT IF EXISTS ticket_email_logs_email_type_check;
ALTER TABLE public.ticket_email_logs
  ADD CONSTRAINT ticket_email_logs_email_type_check
  CHECK (email_type IN ('payment_confirmation', 'free_pass_access'));

CREATE OR REPLACE FUNCTION public.prepare_ticket_order()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  selected_ticket public.event_tickets%ROWTYPE;
BEGIN
  IF NEW.order_type NOT IN ('paid', 'free_pass') THEN
    RAISE EXCEPTION 'Jenis order tidak valid';
  END IF;
  IF NEW.order_type = 'free_pass' AND auth.role() IS DISTINCT FROM 'service_role' THEN
    RAISE EXCEPTION 'Free Pass hanya dapat diterbitkan melalui Admin Tiket';
  END IF;

  SELECT * INTO selected_ticket
  FROM public.event_tickets
  WHERE id = NEW.ticket_id
    AND event_id = NEW.event_id
    AND status = 'active';

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Ticket tidak tersedia untuk event ini';
  END IF;

  NEW.ticket_category := selected_ticket.name;
  NEW.unit_price := selected_ticket.price;
  IF NEW.order_type = 'free_pass' THEN
    NEW.total_price := 0;
    NEW.payment_amount := 0;
    NEW.payment_proof_path := NULL;
    NEW.payment_submitted_at := NULL;
    NEW.payment_method_id := NULL;
    NEW.payment_method_snapshot := NULL;
    NEW.status := 'Lunas';
    NEW.expires_at := NULL;
  ELSE
    NEW.total_price := selected_ticket.price * NEW.quantity;
    NEW.status := 'Menunggu Pembayaran';
  END IF;
  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.issue_ticket_free_pass(
  p_order_number text,
  p_event_id uuid,
  p_ticket_id uuid,
  p_full_name text,
  p_email text,
  p_whatsapp text,
  p_quantity integer,
  p_reason text,
  p_actor_id uuid,
  p_access_code_hash text,
  p_whatsapp_code_hash text,
  p_access_code_ciphertext text,
  p_qr_tokens jsonb
)
RETURNS TABLE (issued_order_id uuid, resolved_access_code_id uuid, issued_ticket_count integer)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  selected_event public.events%ROWTYPE;
  selected_ticket public.event_tickets%ROWTYPE;
  selected_code public.ticket_access_codes%ROWTYPE;
  normalized_phone text;
  committed_quantity bigint;
  token_value jsonb;
  token_index integer := 0;
  new_order_id uuid := gen_random_uuid();
BEGIN
  IF auth.role() IS DISTINCT FROM 'service_role' THEN
    RAISE EXCEPTION 'Operasi harus dipanggil melalui Admin Tiket';
  END IF;
  IF p_actor_id IS NULL THEN
    RAISE EXCEPTION 'Admin penerbit tidak valid';
  END IF;
  IF p_quantity IS NULL OR p_quantity < 1 OR p_quantity > 10 THEN
    RAISE EXCEPTION 'Jumlah tiket harus antara 1 dan 10';
  END IF;
  IF p_full_name IS NULL OR nullif(trim(p_full_name), '') IS NULL OR length(trim(p_full_name)) > 160 THEN
    RAISE EXCEPTION 'Nama penerima wajib diisi maksimal 160 karakter';
  END IF;
  IF p_reason IS NULL OR nullif(trim(p_reason), '') IS NULL OR length(trim(p_reason)) > 300 THEN
    RAISE EXCEPTION 'Alasan Free Pass wajib diisi maksimal 300 karakter';
  END IF;
  IF p_order_number IS NULL OR p_order_number !~ '^[A-Z]{3}-[A-Z0-9]{6}$' THEN
    RAISE EXCEPTION 'Nomor order tidak valid';
  END IF;
  IF p_email IS NOT NULL AND p_email !~* '^[^[:space:]@]+@[^[:space:]@]+\.[^[:space:]@]+$' THEN
    RAISE EXCEPTION 'Alamat email tidak valid';
  END IF;
  normalized_phone := public.normalize_ticket_whatsapp(p_whatsapp);
  IF length(normalized_phone) < 10 OR length(normalized_phone) > 15 THEN
    RAISE EXCEPTION 'Nomor WhatsApp tidak valid';
  END IF;
  IF p_qr_tokens IS NULL OR jsonb_typeof(p_qr_tokens) IS DISTINCT FROM 'array' THEN
    RAISE EXCEPTION 'Token QR harus disiapkan untuk setiap tiket';
  END IF;
  IF jsonb_array_length(p_qr_tokens) <> p_quantity THEN
    RAISE EXCEPTION 'Token QR harus disiapkan untuk setiap tiket';
  END IF;

  SELECT * INTO selected_event
  FROM public.events
  WHERE id = p_event_id
  FOR SHARE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Event tidak ditemukan';
  END IF;
  IF selected_event.status IN ('completed', 'cancelled') THEN
    RAISE EXCEPTION 'Event tidak tersedia untuk penerbitan Free Pass';
  END IF;

  PERFORM pg_advisory_xact_lock(hashtextextended(p_ticket_id::text, 0));
  SELECT * INTO selected_ticket
  FROM public.event_tickets
  WHERE id = p_ticket_id
    AND event_id = p_event_id
    AND status = 'active'
  FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Kategori tiket tidak tersedia untuk Event ini';
  END IF;

  UPDATE public.ticket_orders
  SET status = 'Expired', updated_at = now()
  WHERE ticket_id = p_ticket_id
    AND status IN ('Menunggu Pembayaran', 'Menunggu Verifikasi', 'Sudah Bayar')
    AND expires_at IS NOT NULL
    AND expires_at <= now();

  SELECT coalesce(sum(quantity), 0) INTO committed_quantity
  FROM public.ticket_orders
  WHERE ticket_id = p_ticket_id
    AND status IN ('Menunggu Pembayaran', 'Menunggu Verifikasi', 'Sudah Bayar', 'Lunas', 'Terverifikasi', 'Selesai');

  IF selected_ticket.quota IS NOT NULL
    AND committed_quantity + p_quantity > selected_ticket.quota THEN
    RAISE EXCEPTION 'Kuota tiket tidak mencukupi';
  END IF;

  PERFORM pg_advisory_xact_lock(hashtextextended(p_event_id::text || ':' || normalized_phone, 0));
  SELECT * INTO selected_code
  FROM public.ticket_access_codes
  WHERE event_id = p_event_id
    AND whatsapp_normalized = normalized_phone
    AND status = 'active'
  FOR UPDATE;

  IF NOT FOUND THEN
    IF nullif(p_access_code_hash, '') IS NULL
      OR nullif(p_whatsapp_code_hash, '') IS NULL
      OR nullif(p_access_code_ciphertext, '') IS NULL THEN
      RAISE EXCEPTION 'Access Code baru harus disiapkan server';
    END IF;
    IF EXISTS (
      SELECT 1 FROM public.ticket_access_codes
      WHERE whatsapp_normalized = normalized_phone
        AND whatsapp_code_hash = p_whatsapp_code_hash
    ) THEN
      RAISE EXCEPTION 'Access Code sudah pernah digunakan untuk nomor ini; buat kode baru';
    END IF;
    INSERT INTO public.ticket_access_codes (
      event_id, whatsapp_normalized, access_code_hash, whatsapp_code_hash, access_code_ciphertext
    ) VALUES (
      p_event_id, normalized_phone, p_access_code_hash, p_whatsapp_code_hash, p_access_code_ciphertext
    ) RETURNING * INTO selected_code;
  END IF;

  INSERT INTO public.ticket_orders (
    id, order_number, event_id, ticket_id, ticket_category, full_name, email, whatsapp,
    quantity, unit_price, total_price, notes, status, expires_at, payment_amount,
    order_type, free_pass_reason, issued_by, access_code_id
  ) VALUES (
    new_order_id, p_order_number, p_event_id, p_ticket_id, selected_ticket.name,
    trim(p_full_name), nullif(lower(trim(p_email)), ''), normalized_phone,
    p_quantity, selected_ticket.price, 0, trim(p_reason), 'Lunas', NULL, 0,
    'free_pass', trim(p_reason), p_actor_id, selected_code.id
  );

  FOR token_value IN SELECT value FROM jsonb_array_elements(p_qr_tokens)
  LOOP
    token_index := token_index + 1;
    IF nullif(token_value->>'hash', '') IS NULL OR nullif(token_value->>'ciphertext', '') IS NULL THEN
      RAISE EXCEPTION 'Token QR tidak valid';
    END IF;
    INSERT INTO public.ticket_instances (
      ticket_order_id, event_id, event_ticket_id, sequence_no, qr_token_hash, qr_token_ciphertext
    ) VALUES (
      new_order_id, p_event_id, p_ticket_id, token_index,
      token_value->>'hash', token_value->>'ciphertext'
    );
  END LOOP;

  RETURN QUERY SELECT new_order_id, selected_code.id, p_quantity;
END;
$$;

REVOKE ALL ON FUNCTION public.issue_ticket_free_pass(text, uuid, uuid, text, text, text, integer, text, uuid, text, text, text, jsonb)
  FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.issue_ticket_free_pass(text, uuid, uuid, text, text, text, integer, text, uuid, text, text, text, jsonb)
  TO service_role;


-- Source migration: 20261004120000_reuse_ticket_payment_methods.sql
CREATE TABLE public.event_payment_method_assignments (
  payment_method_id uuid NOT NULL REFERENCES public.event_payment_methods(id) ON DELETE CASCADE,
  event_id uuid NOT NULL REFERENCES public.events(id) ON DELETE RESTRICT,
  is_active boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (payment_method_id, event_id)
);

CREATE INDEX idx_event_payment_method_assignments_event
  ON public.event_payment_method_assignments(event_id, is_active);

CREATE UNIQUE INDEX idx_event_payment_method_assignments_one_active
  ON public.event_payment_method_assignments(event_id)
  WHERE is_active;

INSERT INTO public.event_payment_method_assignments (payment_method_id, event_id, is_active)
SELECT id, event_id, is_active
FROM public.event_payment_methods;

UPDATE public.event_payment_methods SET is_active = false WHERE is_active;
DROP INDEX IF EXISTS public.idx_event_payment_methods_one_active;

ALTER TABLE public.event_payment_method_assignments ENABLE ROW LEVEL SECURITY;
GRANT SELECT ON public.event_payment_method_assignments TO anon, authenticated;
GRANT ALL ON public.event_payment_method_assignments TO service_role;
REVOKE INSERT, UPDATE, DELETE ON public.event_payment_method_assignments FROM anon, authenticated;

DROP POLICY IF EXISTS "public_read_active_event_payment_methods" ON public.event_payment_methods;
CREATE POLICY "public_read_active_event_payment_methods"
  ON public.event_payment_methods
  FOR SELECT
  TO anon, authenticated
  USING (
    EXISTS (
      SELECT 1
      FROM public.event_payment_method_assignments assignment
      JOIN public.events event ON event.id = assignment.event_id
      WHERE assignment.payment_method_id = event_payment_methods.id
        AND assignment.is_active
        AND event.published
        AND event.status = 'upcoming'
    )
    AND (
      auth.role() = 'anon'
      OR (
        NOT public.jwt_has_role('event_admin')
        AND NOT public.jwt_has_role('admin_ticket')
        AND NOT public.jwt_has_role('admin_qr')
      )
    )
  );

DROP POLICY IF EXISTS "ticket_admin_manage_scoped_payment_methods" ON public.event_payment_methods;
CREATE POLICY "ticket_admin_manage_scoped_payment_methods"
  ON public.event_payment_methods
  FOR ALL
  TO authenticated
  USING (
    public.jwt_has_role('admin')
    OR EXISTS (
      SELECT 1
      FROM public.event_payment_method_assignments assignment
      WHERE assignment.payment_method_id = event_payment_methods.id
        AND public.user_has_ticket_event_scope(assignment.event_id, 'admin_ticket')
    )
  )
  WITH CHECK (
    public.jwt_has_role('admin')
    OR EXISTS (
      SELECT 1
      FROM public.event_payment_method_assignments assignment
      WHERE assignment.payment_method_id = event_payment_methods.id
        AND public.user_has_ticket_event_scope(assignment.event_id, 'admin_ticket')
    )
  );

CREATE POLICY "public_read_active_ticket_payment_assignments"
  ON public.event_payment_method_assignments
  FOR SELECT
  TO anon, authenticated
  USING (
    is_active
    AND EXISTS (
      SELECT 1
      FROM public.events event
      WHERE event.id = event_id
        AND event.published
        AND event.status = 'upcoming'
    )
    AND (
      auth.role() = 'anon'
      OR (
        NOT public.jwt_has_role('event_admin')
        AND NOT public.jwt_has_role('admin_ticket')
        AND NOT public.jwt_has_role('admin_qr')
      )
    )
  );

CREATE POLICY "ticket_admin_manage_payment_assignments"
  ON public.event_payment_method_assignments
  FOR ALL
  TO authenticated
  USING (
    public.jwt_has_role('admin')
    OR public.user_has_ticket_event_scope(event_id, 'admin_ticket')
  )
  WITH CHECK (
    public.jwt_has_role('admin')
    OR public.user_has_ticket_event_scope(event_id, 'admin_ticket')
  );

CREATE OR REPLACE FUNCTION public.save_ticket_payment_method(
  p_method_id uuid,
  p_event_ids uuid[],
  p_recipient_name text,
  p_bank_name text,
  p_account_number text,
  p_qris_storage_path text,
  p_note text
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  saved_method_id uuid;
  anchor_event_id uuid;
BEGIN
  IF auth.role() <> 'service_role' THEN RAISE EXCEPTION 'Operasi harus dipanggil melalui service backend'; END IF;
  IF nullif(trim(p_recipient_name), '') IS NULL THEN RAISE EXCEPTION 'Nama penerima wajib diisi'; END IF;
  IF coalesce(cardinality(p_event_ids), 0) = 0
    OR EXISTS (SELECT 1 FROM unnest(p_event_ids) AS selected_events(event_id) WHERE selected_events.event_id IS NULL)
    OR cardinality(p_event_ids) <> (SELECT count(DISTINCT selected_events.event_id) FROM unnest(p_event_ids) AS selected_events(event_id)) THEN
    RAISE EXCEPTION 'Pilih minimal satu Event yang berbeda';
  END IF;
  IF nullif(trim(p_account_number), '') IS NULL
    AND nullif(trim(p_qris_storage_path), '') IS NULL THEN
    RAISE EXCEPTION 'Isi nomor rekening atau upload QRIS';
  END IF;
  IF EXISTS (
    SELECT 1 FROM unnest(p_event_ids) AS selected_events(event_id)
    WHERE NOT EXISTS (SELECT 1 FROM public.events event WHERE event.id = selected_events.event_id)
  ) THEN
    RAISE EXCEPTION 'Event yang dipilih tidak ditemukan';
  END IF;

  anchor_event_id := p_event_ids[1];
  IF p_method_id IS NULL THEN
    INSERT INTO public.event_payment_methods (
      event_id, recipient_name, bank_name, account_number, qris_storage_path, note, is_active
    ) VALUES (
      anchor_event_id, trim(p_recipient_name), nullif(trim(p_bank_name), ''),
      nullif(trim(p_account_number), ''), nullif(trim(p_qris_storage_path), ''),
      nullif(trim(p_note), ''), false
    )
    RETURNING id INTO saved_method_id;
  ELSE
    UPDATE public.event_payment_methods
    SET recipient_name = trim(p_recipient_name),
        bank_name = nullif(trim(p_bank_name), ''),
        account_number = nullif(trim(p_account_number), ''),
        qris_storage_path = nullif(trim(p_qris_storage_path), ''),
        note = nullif(trim(p_note), ''),
        updated_at = now()
    WHERE id = p_method_id
    RETURNING id INTO saved_method_id;
    IF NOT FOUND THEN RAISE EXCEPTION 'Informasi pembayaran tidak ditemukan'; END IF;
  END IF;

  DELETE FROM public.event_payment_method_assignments
  WHERE payment_method_id = saved_method_id
    AND NOT (event_id = ANY(p_event_ids));

  INSERT INTO public.event_payment_method_assignments (payment_method_id, event_id)
  SELECT saved_method_id, selected_events.event_id
  FROM unnest(p_event_ids) AS selected_events(event_id)
  ON CONFLICT (payment_method_id, event_id) DO NOTHING;

  RETURN saved_method_id;
END;
$$;

REVOKE ALL ON FUNCTION public.save_ticket_payment_method(uuid, uuid[], text, text, text, text, text) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.save_ticket_payment_method(uuid, uuid[], text, text, text, text, text) TO service_role;

DROP FUNCTION IF EXISTS public.set_ticket_payment_method_active(uuid, uuid);
CREATE FUNCTION public.set_ticket_payment_method_active(
  p_method_id uuid,
  p_event_id uuid,
  p_actor_id uuid
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF auth.role() <> 'service_role' THEN RAISE EXCEPTION 'Operasi harus dipanggil melalui service backend'; END IF;

  PERFORM pg_advisory_xact_lock(hashtextextended(p_event_id::text, 0));
  PERFORM 1
  FROM public.event_payment_method_assignments
  WHERE payment_method_id = p_method_id AND event_id = p_event_id
  FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Informasi pembayaran tidak ditugaskan ke Event ini';
  END IF;

  UPDATE public.event_payment_method_assignments
  SET is_active = false, updated_at = now()
  WHERE event_id = p_event_id AND is_active;

  UPDATE public.event_payment_method_assignments
  SET is_active = true, updated_at = now()
  WHERE payment_method_id = p_method_id AND event_id = p_event_id;

  RETURN p_method_id;
END;
$$;

REVOKE ALL ON FUNCTION public.set_ticket_payment_method_active(uuid, uuid, uuid) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.set_ticket_payment_method_active(uuid, uuid, uuid) TO service_role;

CREATE OR REPLACE FUNCTION public.create_ticket_order(
  p_order_number text,
  p_event_id uuid,
  p_ticket_id uuid,
  p_full_name text,
  p_email text,
  p_whatsapp text,
  p_quantity integer,
  p_notes text
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  selected_event public.events%ROWTYPE;
  selected_ticket public.event_tickets%ROWTYPE;
  selected_payment public.event_payment_methods%ROWTYPE;
  normalized_phone text;
  committed_quantity bigint;
  new_order_id uuid := gen_random_uuid();
BEGIN
  IF p_quantity IS NULL OR p_quantity < 1 OR p_quantity > 10 THEN
    RAISE EXCEPTION 'Jumlah tiket harus antara 1 dan 10';
  END IF;
  IF nullif(trim(p_full_name), '') IS NULL THEN
    RAISE EXCEPTION 'Nama pembeli wajib diisi';
  END IF;
  IF nullif(trim(p_email), '') IS NULL OR trim(p_email) !~ '^[^[:space:]@]+@[^[:space:]@]+\.[^[:space:]@]+$' THEN
    RAISE EXCEPTION 'Email pembeli wajib diisi dengan format yang valid';
  END IF;
  normalized_phone := public.normalize_ticket_whatsapp(p_whatsapp);
  IF length(normalized_phone) < 10 OR length(normalized_phone) > 15 THEN
    RAISE EXCEPTION 'Nomor WhatsApp tidak valid';
  END IF;
  IF p_order_number !~ '^[A-Z]{3}-[A-Z0-9]{6}$' THEN
    RAISE EXCEPTION 'Nomor order tidak valid';
  END IF;

  SELECT * INTO selected_event
  FROM public.events
  WHERE id = p_event_id AND published = true AND status = 'upcoming'
  FOR SHARE;
  IF NOT FOUND THEN RAISE EXCEPTION 'Event tidak tersedia untuk pemesanan'; END IF;

  PERFORM pg_advisory_xact_lock(hashtextextended(p_ticket_id::text, 0));
  SELECT * INTO selected_ticket
  FROM public.event_tickets
  WHERE id = p_ticket_id AND event_id = p_event_id AND status = 'active'
  FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'Jenis tiket tidak tersedia'; END IF;

  SELECT method.* INTO selected_payment
  FROM public.event_payment_method_assignments assignment
  JOIN public.event_payment_methods method ON method.id = assignment.payment_method_id
  WHERE assignment.event_id = p_event_id AND assignment.is_active = true
  FOR SHARE OF assignment, method;
  IF NOT FOUND THEN RAISE EXCEPTION 'Informasi pembayaran Event belum aktif'; END IF;

  UPDATE public.ticket_orders
  SET status = 'Expired', updated_at = now()
  WHERE ticket_id = p_ticket_id
    AND status IN ('Draft Pembayaran', 'Menunggu Pembayaran', 'Menunggu Verifikasi', 'Sudah Bayar')
    AND expires_at IS NOT NULL
    AND expires_at <= now();

  SELECT coalesce(sum(quantity), 0) INTO committed_quantity
  FROM public.ticket_orders
  WHERE ticket_id = p_ticket_id
    AND status IN ('Draft Pembayaran', 'Menunggu Pembayaran', 'Menunggu Verifikasi', 'Sudah Bayar', 'Lunas', 'Terverifikasi', 'Selesai');

  IF selected_ticket.quota IS NOT NULL AND committed_quantity + p_quantity > selected_ticket.quota THEN
    RAISE EXCEPTION 'Kuota tiket tidak mencukupi';
  END IF;

  INSERT INTO public.ticket_orders (
    id, order_number, event_id, ticket_id, ticket_category,
    full_name, email, whatsapp, quantity, unit_price, total_price,
    notes, status, expires_at, payment_method_id, payment_method_snapshot
  ) VALUES (
    new_order_id, p_order_number, p_event_id, p_ticket_id, selected_ticket.name,
    trim(p_full_name), lower(trim(p_email)), normalized_phone, p_quantity,
    selected_ticket.price, selected_ticket.price * p_quantity, null, 'Draft Pembayaran',
    now() + interval '30 minutes', selected_payment.id,
    jsonb_build_object(
      'recipient_name', selected_payment.recipient_name,
      'bank_name', selected_payment.bank_name,
      'account_number', selected_payment.account_number,
      'qris_storage_path', selected_payment.qris_storage_path,
      'note', selected_payment.note
    )
  );

  RETURN new_order_id;
END;
$$;

REVOKE ALL ON FUNCTION public.create_ticket_order(text, uuid, uuid, text, text, text, integer, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.create_ticket_order(text, uuid, uuid, text, text, text, integer, text) TO anon;


-- Source migration: 20261004130000_clear_default_whatsapp_contact_numbers.sql
UPDATE site_settings
SET
  whatsapp_admin = '',
  whatsapp_registration = '',
  whatsapp_partnership = '',
  whatsapp_ticket = ''
WHERE id = 1;


-- Source migration: 20261006100000_add_ots_ticket_sales.sql
ALTER TABLE public.event_tickets
  ADD COLUMN IF NOT EXISTS available_public boolean NOT NULL DEFAULT true,
  ADD COLUMN IF NOT EXISTS available_ots boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS ots_price integer;

ALTER TABLE public.event_tickets
  DROP CONSTRAINT IF EXISTS event_tickets_ots_price_nonnegative;
ALTER TABLE public.event_tickets
  ADD CONSTRAINT event_tickets_ots_price_nonnegative
  CHECK (ots_price IS NULL OR ots_price >= 0);

ALTER TABLE public.event_tickets
  DROP CONSTRAINT IF EXISTS event_tickets_ots_price_required;
ALTER TABLE public.event_tickets
  ADD CONSTRAINT event_tickets_ots_price_required
  CHECK (NOT available_ots OR ots_price IS NOT NULL);

ALTER TABLE public.ticket_orders
  ADD COLUMN IF NOT EXISTS sale_channel text NOT NULL DEFAULT 'online';

UPDATE public.ticket_orders
SET sale_channel = 'free_pass'
WHERE order_type = 'free_pass' AND sale_channel = 'online';

ALTER TABLE public.ticket_orders
  DROP CONSTRAINT IF EXISTS ticket_orders_sale_channel_check;
ALTER TABLE public.ticket_orders
  ADD CONSTRAINT ticket_orders_sale_channel_check
  CHECK (sale_channel IN ('online', 'ots', 'free_pass'));

DROP POLICY IF EXISTS "public_read_active_event_tickets" ON public.event_tickets;
DROP POLICY IF EXISTS "public_read_active_event_tickets_anon" ON public.event_tickets;
DROP POLICY IF EXISTS "public_read_active_event_tickets_authenticated" ON public.event_tickets;

CREATE POLICY "public_read_active_event_tickets_anon"
  ON public.event_tickets
  FOR SELECT
  TO anon
  USING (status = 'active' AND available_public);

CREATE POLICY "public_read_active_event_tickets_authenticated"
  ON public.event_tickets
  FOR SELECT
  TO authenticated
  USING (
    status = 'active'
    AND available_public
    AND NOT public.jwt_has_role('admin_ticket')
    AND NOT public.jwt_has_role('admin_qr')
  );

CREATE OR REPLACE FUNCTION public.prepare_ticket_order()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  selected_ticket public.event_tickets%ROWTYPE;
BEGIN
  IF NEW.order_type NOT IN ('paid', 'free_pass') THEN
    RAISE EXCEPTION 'Jenis order tidak valid';
  END IF;
  IF NEW.order_type = 'free_pass' AND auth.role() IS DISTINCT FROM 'service_role' THEN
    RAISE EXCEPTION 'Free Pass hanya dapat diterbitkan melalui Admin Tiket';
  END IF;
  IF NEW.sale_channel NOT IN ('online', 'ots', 'free_pass') THEN
    RAISE EXCEPTION 'Sumber transaksi tidak valid';
  END IF;

  SELECT * INTO selected_ticket
  FROM public.event_tickets
  WHERE id = NEW.ticket_id AND event_id = NEW.event_id AND status = 'active';
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Ticket tidak tersedia untuk event ini';
  END IF;

  IF NEW.order_type = 'free_pass' THEN
    NEW.sale_channel := 'free_pass';
    NEW.ticket_category := selected_ticket.name;
    NEW.unit_price := selected_ticket.price;
    NEW.total_price := 0;
    NEW.payment_amount := 0;
    NEW.payment_proof_path := NULL;
    NEW.payment_submitted_at := NULL;
    NEW.payment_method_id := NULL;
    NEW.payment_method_snapshot := NULL;
    NEW.status := 'Lunas';
    NEW.expires_at := NULL;
  ELSIF NEW.sale_channel = 'ots' THEN
    IF NOT selected_ticket.available_ots OR selected_ticket.ots_price IS NULL THEN
      RAISE EXCEPTION 'Kategori tiket tidak tersedia untuk penjualan OTS';
    END IF;
    NEW.ticket_category := selected_ticket.name;
    NEW.unit_price := selected_ticket.ots_price;
    NEW.total_price := selected_ticket.ots_price * NEW.quantity;
    NEW.payment_amount := NEW.total_price;
    NEW.payment_proof_path := NULL;
    NEW.payment_submitted_at := NULL;
    NEW.payment_method_id := NULL;
    NEW.payment_method_snapshot := NULL;
    NEW.status := 'Lunas';
    NEW.expires_at := NULL;
  ELSE
    IF NOT selected_ticket.available_public THEN
      RAISE EXCEPTION 'Kategori tiket tidak tersedia untuk pembelian publik';
    END IF;
    NEW.ticket_category := selected_ticket.name;
    NEW.unit_price := selected_ticket.price;
    NEW.total_price := selected_ticket.price * NEW.quantity;
    NEW.status := 'Menunggu Pembayaran';
  END IF;
  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.create_ticket_order(
  p_order_number text,
  p_event_id uuid,
  p_ticket_id uuid,
  p_full_name text,
  p_email text,
  p_whatsapp text,
  p_quantity integer,
  p_notes text
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  selected_event public.events%ROWTYPE;
  selected_ticket public.event_tickets%ROWTYPE;
  selected_payment public.event_payment_methods%ROWTYPE;
  normalized_phone text;
  committed_quantity bigint;
  new_order_id uuid := gen_random_uuid();
BEGIN
  IF p_quantity IS NULL OR p_quantity < 1 OR p_quantity > 10 THEN
    RAISE EXCEPTION 'Jumlah tiket harus antara 1 dan 10';
  END IF;
  IF nullif(trim(p_full_name), '') IS NULL THEN RAISE EXCEPTION 'Nama pembeli wajib diisi'; END IF;
  normalized_phone := public.normalize_ticket_whatsapp(p_whatsapp);
  IF length(normalized_phone) < 10 OR length(normalized_phone) > 15 THEN
    RAISE EXCEPTION 'Nomor WhatsApp tidak valid';
  END IF;
  IF p_order_number !~ '^[A-Z]{3}-[A-Z0-9]{6}$' THEN RAISE EXCEPTION 'Nomor order tidak valid'; END IF;

  SELECT * INTO selected_event FROM public.events
  WHERE id = p_event_id AND published = true AND status = 'upcoming'
  FOR SHARE;
  IF NOT FOUND THEN RAISE EXCEPTION 'Event tidak tersedia untuk pemesanan'; END IF;

  PERFORM pg_advisory_xact_lock(hashtextextended(p_ticket_id::text, 0));
  SELECT * INTO selected_ticket FROM public.event_tickets
  WHERE id = p_ticket_id AND event_id = p_event_id
    AND status = 'active' AND available_public
  FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'Jenis tiket tidak tersedia untuk pembelian publik'; END IF;

  SELECT * INTO selected_payment FROM public.event_payment_methods
  WHERE event_id = p_event_id AND is_active = true
  FOR SHARE;
  IF NOT FOUND THEN RAISE EXCEPTION 'Informasi pembayaran Event belum aktif'; END IF;

  UPDATE public.ticket_orders SET status = 'Expired', updated_at = now()
  WHERE ticket_id = p_ticket_id
    AND status IN ('Menunggu Pembayaran', 'Menunggu Verifikasi', 'Sudah Bayar')
    AND expires_at IS NOT NULL AND expires_at <= now();

  SELECT coalesce(sum(quantity), 0) INTO committed_quantity
  FROM public.ticket_orders
  WHERE ticket_id = p_ticket_id
    AND status IN ('Menunggu Pembayaran', 'Menunggu Verifikasi', 'Sudah Bayar', 'Lunas', 'Terverifikasi', 'Selesai');
  IF selected_ticket.quota IS NOT NULL AND committed_quantity + p_quantity > selected_ticket.quota THEN
    RAISE EXCEPTION 'Kuota tiket tidak mencukupi';
  END IF;

  INSERT INTO public.ticket_orders (
    id, order_number, event_id, ticket_id, ticket_category, full_name, email, whatsapp,
    quantity, unit_price, total_price, notes, status, expires_at,
    payment_method_id, payment_method_snapshot, sale_channel
  ) VALUES (
    new_order_id, p_order_number, p_event_id, p_ticket_id, selected_ticket.name,
    trim(p_full_name), nullif(lower(trim(p_email)), ''), normalized_phone,
    p_quantity, selected_ticket.price, selected_ticket.price * p_quantity,
    nullif(trim(p_notes), ''), 'Menunggu Pembayaran', now() + interval '30 minutes',
    selected_payment.id,
    jsonb_build_object(
      'recipient_name', selected_payment.recipient_name,
      'bank_name', selected_payment.bank_name,
      'account_number', selected_payment.account_number,
      'qris_storage_path', selected_payment.qris_storage_path,
      'note', selected_payment.note
    ),
    'online'
  );
  RETURN new_order_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.issue_ticket_ots(
  p_order_number text,
  p_event_id uuid,
  p_ticket_id uuid,
  p_full_name text,
  p_whatsapp text,
  p_quantity integer,
  p_actor_id uuid,
  p_access_code_hash text,
  p_whatsapp_code_hash text,
  p_access_code_ciphertext text,
  p_qr_tokens jsonb
)
RETURNS TABLE (issued_order_id uuid, resolved_access_code_id uuid, issued_ticket_count integer)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  selected_event public.events%ROWTYPE;
  selected_ticket public.event_tickets%ROWTYPE;
  selected_code public.ticket_access_codes%ROWTYPE;
  normalized_phone text;
  committed_quantity bigint;
  token_value jsonb;
  token_index integer := 0;
  new_order_id uuid := gen_random_uuid();
BEGIN
  IF auth.role() IS DISTINCT FROM 'service_role' THEN RAISE EXCEPTION 'Operasi harus dipanggil melalui Admin Tiket'; END IF;
  IF p_actor_id IS NULL OR p_quantity IS NULL OR p_quantity < 1 OR p_quantity > 10 THEN
    RAISE EXCEPTION 'Admin penerbit atau jumlah tiket tidak valid (maksimal 10)';
  END IF;
  IF p_full_name IS NULL OR nullif(trim(p_full_name), '') IS NULL OR length(trim(p_full_name)) > 160 THEN
    RAISE EXCEPTION 'Nama penerima wajib diisi maksimal 160 karakter';
  END IF;
  IF p_order_number IS NULL OR p_order_number !~ '^[A-Z]{3}-[A-Z0-9]{6}$' THEN RAISE EXCEPTION 'Nomor order tidak valid'; END IF;
  normalized_phone := public.normalize_ticket_whatsapp(p_whatsapp);
  IF length(normalized_phone) < 10 OR length(normalized_phone) > 15 THEN
    RAISE EXCEPTION 'Nomor WhatsApp tidak valid';
  END IF;
  IF p_qr_tokens IS NULL OR jsonb_typeof(p_qr_tokens) IS DISTINCT FROM 'array'
    OR jsonb_array_length(p_qr_tokens) <> p_quantity THEN
    RAISE EXCEPTION 'Token QR harus disiapkan untuk setiap tiket';
  END IF;

  SELECT * INTO selected_event FROM public.events WHERE id = p_event_id FOR SHARE;
  IF NOT FOUND OR selected_event.status <> 'upcoming' THEN
    RAISE EXCEPTION 'Event tidak tersedia untuk penjualan OTS';
  END IF;
  PERFORM pg_advisory_xact_lock(hashtextextended(p_ticket_id::text, 0));
  SELECT * INTO selected_ticket FROM public.event_tickets
  WHERE id = p_ticket_id AND event_id = p_event_id AND status = 'active'
    AND available_ots AND ots_price IS NOT NULL
  FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'Kategori tiket tidak tersedia untuk penjualan OTS'; END IF;

  UPDATE public.ticket_orders SET status = 'Expired', updated_at = now()
  WHERE ticket_id = p_ticket_id
    AND status IN ('Menunggu Pembayaran', 'Menunggu Verifikasi', 'Sudah Bayar')
    AND expires_at IS NOT NULL AND expires_at <= now();
  SELECT coalesce(sum(quantity), 0) INTO committed_quantity
  FROM public.ticket_orders
  WHERE ticket_id = p_ticket_id
    AND status IN ('Menunggu Pembayaran', 'Menunggu Verifikasi', 'Sudah Bayar', 'Lunas', 'Terverifikasi', 'Selesai');
  IF selected_ticket.quota IS NOT NULL AND committed_quantity + p_quantity > selected_ticket.quota THEN
    RAISE EXCEPTION 'Kuota tiket tidak mencukupi';
  END IF;

  PERFORM pg_advisory_xact_lock(hashtextextended(p_event_id::text || ':' || normalized_phone, 0));
  SELECT * INTO selected_code FROM public.ticket_access_codes
  WHERE event_id = p_event_id AND whatsapp_normalized = normalized_phone AND status = 'active'
  FOR UPDATE;
  IF NOT FOUND THEN
    IF nullif(p_access_code_hash, '') IS NULL OR nullif(p_whatsapp_code_hash, '') IS NULL
      OR nullif(p_access_code_ciphertext, '') IS NULL THEN
      RAISE EXCEPTION 'Access Code baru harus disiapkan server';
    END IF;
    IF EXISTS (SELECT 1 FROM public.ticket_access_codes
      WHERE whatsapp_normalized = normalized_phone AND whatsapp_code_hash = p_whatsapp_code_hash) THEN
      RAISE EXCEPTION 'Access Code sudah pernah digunakan untuk nomor ini; buat kode baru';
    END IF;
    INSERT INTO public.ticket_access_codes (
      event_id, whatsapp_normalized, access_code_hash, whatsapp_code_hash, access_code_ciphertext
    ) VALUES (
      p_event_id, normalized_phone, p_access_code_hash, p_whatsapp_code_hash, p_access_code_ciphertext
    ) RETURNING * INTO selected_code;
  END IF;

  INSERT INTO public.ticket_orders (
    id, order_number, event_id, ticket_id, ticket_category, full_name, whatsapp,
    quantity, unit_price, total_price, payment_amount, status, sale_channel,
    order_type, issued_by, access_code_id
  ) VALUES (
    new_order_id, p_order_number, p_event_id, p_ticket_id, selected_ticket.name,
    trim(p_full_name), normalized_phone, p_quantity, selected_ticket.ots_price,
    selected_ticket.ots_price * p_quantity, selected_ticket.ots_price * p_quantity,
    'Lunas', 'ots', 'paid', p_actor_id, selected_code.id
  );

  FOR token_value IN SELECT value FROM jsonb_array_elements(p_qr_tokens)
  LOOP
    token_index := token_index + 1;
    IF nullif(token_value->>'hash', '') IS NULL OR nullif(token_value->>'ciphertext', '') IS NULL THEN
      RAISE EXCEPTION 'Token QR tidak valid';
    END IF;
    INSERT INTO public.ticket_instances (
      ticket_order_id, event_id, event_ticket_id, sequence_no, qr_token_hash, qr_token_ciphertext
    ) VALUES (
      new_order_id, p_event_id, p_ticket_id, token_index,
      token_value->>'hash', token_value->>'ciphertext'
    );
  END LOOP;
  RETURN QUERY SELECT new_order_id, selected_code.id, p_quantity;
END;
$$;

REVOKE ALL ON FUNCTION public.issue_ticket_ots(text, uuid, uuid, text, text, integer, uuid, text, text, text, jsonb)
  FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.issue_ticket_ots(text, uuid, uuid, text, text, integer, uuid, text, text, text, jsonb)
  TO service_role;


-- Source migration: 20261006110000_auto_deactivate_event_payment_methods.sql
CREATE OR REPLACE FUNCTION public.deactivate_expired_event_payment_assignments()
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
DECLARE
  deactivated_count integer;
BEGIN
  UPDATE public.event_payment_method_assignments AS assignment
  SET is_active = false,
      updated_at = now()
  FROM public.events AS event
  WHERE event.id = assignment.event_id
    AND assignment.is_active
    AND event.date + 2 <= (now() AT TIME ZONE 'Asia/Jakarta')::date;

  GET DIAGNOSTICS deactivated_count = ROW_COUNT;
  RETURN deactivated_count;
END;
$$;

REVOKE ALL ON FUNCTION public.deactivate_expired_event_payment_assignments() FROM PUBLIC, anon, authenticated;

SELECT public.deactivate_expired_event_payment_assignments();

DO $$
DECLARE
  existing_job_id bigint;
BEGIN
  SELECT jobid INTO existing_job_id
  FROM cron.job
  WHERE jobname = 'deactivate-expired-event-payment-assignments';

  IF existing_job_id IS NOT NULL THEN
    PERFORM cron.unschedule(existing_job_id);
  END IF;

  PERFORM cron.schedule(
    'deactivate-expired-event-payment-assignments',
    '*/15 * * * *',
    'SELECT public.deactivate_expired_event_payment_assignments();'
  );
END;
$$;


-- Source migration: 20261006120000_add_mc_member_history.sql
ALTER TABLE public.member_open_mic_history_submissions
  ADD COLUMN IF NOT EXISTS activity_type text NOT NULL DEFAULT 'performance',
  ADD COLUMN IF NOT EXISTS internal_open_mic_id uuid,
  ADD COLUMN IF NOT EXISTS event_time text;

ALTER TABLE public.member_open_mic_history_submissions
  DROP CONSTRAINT IF EXISTS member_open_mic_history_submissions_internal_open_mic_id_fkey;
ALTER TABLE public.member_open_mic_history_submissions
  ADD CONSTRAINT member_open_mic_history_submissions_internal_open_mic_id_fkey
  FOREIGN KEY (internal_open_mic_id) REFERENCES public.open_mics(id) ON DELETE SET NULL;

ALTER TABLE public.member_open_mic_history_submissions
  DROP CONSTRAINT IF EXISTS member_open_mic_history_activity_type_check;
ALTER TABLE public.member_open_mic_history_submissions
  ADD CONSTRAINT member_open_mic_history_activity_type_check
  CHECK (activity_type IN ('performance', 'mc_internal', 'mc_external'));

DROP INDEX IF EXISTS public.uq_member_open_mic_history_duplicate;
CREATE UNIQUE INDEX uq_member_open_mic_history_duplicate
  ON public.member_open_mic_history_submissions (
    user_id,
    activity_type,
    lower(trim(title)),
    event_date,
    lower(trim(venue))
  )
  WHERE activity_type <> 'mc_internal';

CREATE UNIQUE INDEX IF NOT EXISTS uq_member_mc_internal_open_mic
  ON public.member_open_mic_history_submissions (user_id, internal_open_mic_id)
  WHERE activity_type = 'mc_internal';

CREATE OR REPLACE FUNCTION public.prepare_member_mc_history_submission()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
DECLARE
  selected_open_mic public.open_mics%ROWTYPE;
BEGIN
  IF TG_OP = 'UPDATE'
    AND auth.uid() = OLD.user_id
    AND (
      NEW.activity_type IS DISTINCT FROM OLD.activity_type
      OR NEW.internal_open_mic_id IS DISTINCT FROM OLD.internal_open_mic_id
    ) THEN
    RAISE EXCEPTION 'Jenis riwayat dan Open Mic internal tidak dapat diubah setelah pengajuan';
  END IF;

  IF TG_OP = 'UPDATE'
    AND OLD.activity_type = 'mc_internal'
    AND NEW.activity_type = 'mc_internal'
    AND OLD.internal_open_mic_id IS NOT NULL
    AND NEW.internal_open_mic_id IS NULL THEN
    RETURN NEW;
  END IF;

  IF NEW.activity_type = 'mc_internal' THEN
    IF NEW.internal_open_mic_id IS NULL THEN
      RAISE EXCEPTION 'Pilih Open Mic internal untuk pengajuan MC';
    END IF;

    SELECT * INTO selected_open_mic
    FROM public.open_mics
    WHERE id = NEW.internal_open_mic_id
      AND status <> 'cancelled'
      AND (status = 'completed' OR date < (now() AT TIME ZONE 'Asia/Jakarta')::date);
    IF NOT FOUND THEN
      RAISE EXCEPTION 'Open Mic internal belum selesai atau tidak ditemukan';
    END IF;

    NEW.title := selected_open_mic.title;
    NEW.organizer_name := 'Standupindo Serang';
    NEW.event_date := selected_open_mic.date;
    NEW.event_time := selected_open_mic.time;
    NEW.venue := selected_open_mic.venue;
    NEW.city := selected_open_mic.location;
    NEW.proof_url := NULL;
  ELSIF NEW.activity_type = 'mc_external' THEN
    IF nullif(trim(NEW.title), '') IS NULL
      OR nullif(trim(NEW.organizer_name), '') IS NULL
      OR NEW.event_date IS NULL
      OR nullif(trim(NEW.venue), '') IS NULL
      OR nullif(trim(NEW.proof_url), '') IS NULL THEN
      RAISE EXCEPTION 'Data MC eksternal dan bukti dokumentasi wajib diisi';
    END IF;
    NEW.internal_open_mic_id := NULL;
  ELSIF NEW.activity_type = 'performance' THEN
    NEW.internal_open_mic_id := NULL;
  ELSE
    RAISE EXCEPTION 'Jenis aktivitas riwayat tidak valid';
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS prepare_member_mc_history_submission
  ON public.member_open_mic_history_submissions;
CREATE TRIGGER prepare_member_mc_history_submission
  BEFORE INSERT OR UPDATE OF activity_type, internal_open_mic_id, title, organizer_name, event_date, event_time, venue, city, proof_url
  ON public.member_open_mic_history_submissions
  FOR EACH ROW EXECUTE FUNCTION public.prepare_member_mc_history_submission();

REVOKE ALL ON FUNCTION public.prepare_member_mc_history_submission() FROM PUBLIC, anon, authenticated;


-- Source migration: 20261007082000_fix_ticket_order_payment_assignment_lookup.sql
CREATE OR REPLACE FUNCTION public.create_ticket_order(
  p_order_number text,
  p_event_id uuid,
  p_ticket_id uuid,
  p_full_name text,
  p_email text,
  p_whatsapp text,
  p_quantity integer,
  p_notes text
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  selected_event public.events%ROWTYPE;
  selected_ticket public.event_tickets%ROWTYPE;
  selected_payment public.event_payment_methods%ROWTYPE;
  normalized_phone text;
  committed_quantity bigint;
  new_order_id uuid := gen_random_uuid();
BEGIN
  IF p_quantity IS NULL OR p_quantity < 1 OR p_quantity > 10 THEN
    RAISE EXCEPTION 'Jumlah tiket harus antara 1 dan 10';
  END IF;
  IF nullif(trim(p_full_name), '') IS NULL THEN RAISE EXCEPTION 'Nama pembeli wajib diisi'; END IF;
  normalized_phone := public.normalize_ticket_whatsapp(p_whatsapp);
  IF length(normalized_phone) < 10 OR length(normalized_phone) > 15 THEN
    RAISE EXCEPTION 'Nomor WhatsApp tidak valid';
  END IF;
  IF p_order_number !~ '^[A-Z]{3}-[A-Z0-9]{6}$' THEN RAISE EXCEPTION 'Nomor order tidak valid'; END IF;

  SELECT * INTO selected_event FROM public.events
  WHERE id = p_event_id AND published = true AND status = 'upcoming'
  FOR SHARE;
  IF NOT FOUND THEN RAISE EXCEPTION 'Event tidak tersedia untuk pemesanan'; END IF;

  PERFORM pg_advisory_xact_lock(hashtextextended(p_ticket_id::text, 0));
  SELECT * INTO selected_ticket FROM public.event_tickets
  WHERE id = p_ticket_id AND event_id = p_event_id
    AND status = 'active' AND available_public
  FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'Jenis tiket tidak tersedia untuk pembelian publik'; END IF;

  SELECT method.* INTO selected_payment
  FROM public.event_payment_method_assignments assignment
  JOIN public.event_payment_methods method ON method.id = assignment.payment_method_id
  WHERE assignment.event_id = p_event_id AND assignment.is_active = true
  FOR SHARE OF assignment, method;
  IF NOT FOUND THEN RAISE EXCEPTION 'Informasi pembayaran Event belum aktif'; END IF;

  UPDATE public.ticket_orders SET status = 'Expired', updated_at = now()
  WHERE ticket_id = p_ticket_id
    AND status IN ('Menunggu Pembayaran', 'Menunggu Verifikasi', 'Sudah Bayar')
    AND expires_at IS NOT NULL AND expires_at <= now();

  SELECT coalesce(sum(quantity), 0) INTO committed_quantity
  FROM public.ticket_orders
  WHERE ticket_id = p_ticket_id
    AND status IN ('Menunggu Pembayaran', 'Menunggu Verifikasi', 'Sudah Bayar', 'Lunas', 'Terverifikasi', 'Selesai');
  IF selected_ticket.quota IS NOT NULL AND committed_quantity + p_quantity > selected_ticket.quota THEN
    RAISE EXCEPTION 'Kuota tiket tidak mencukupi';
  END IF;

  INSERT INTO public.ticket_orders (
    id, order_number, event_id, ticket_id, ticket_category, full_name, email, whatsapp,
    quantity, unit_price, total_price, notes, status, expires_at,
    payment_method_id, payment_method_snapshot, sale_channel
  ) VALUES (
    new_order_id, p_order_number, p_event_id, p_ticket_id, selected_ticket.name,
    trim(p_full_name), nullif(lower(trim(p_email)), ''), normalized_phone,
    p_quantity, selected_ticket.price, selected_ticket.price * p_quantity,
    nullif(trim(p_notes), ''), 'Menunggu Pembayaran', now() + interval '30 minutes',
    selected_payment.id,
    jsonb_build_object(
      'recipient_name', selected_payment.recipient_name,
      'bank_name', selected_payment.bank_name,
      'account_number', selected_payment.account_number,
      'qris_storage_path', selected_payment.qris_storage_path,
      'note', selected_payment.note
    ),
    'online'
  );
  RETURN new_order_id;
END;
$$;


-- Source migration: 20261007083000_default_ticket_payment_method.sql
ALTER TABLE public.event_payment_methods
  ADD COLUMN IF NOT EXISTS is_default boolean NOT NULL DEFAULT false;

CREATE UNIQUE INDEX IF NOT EXISTS idx_event_payment_methods_one_default
  ON public.event_payment_methods(is_default)
  WHERE is_default;

CREATE OR REPLACE FUNCTION public.set_default_ticket_payment_method(p_method_id uuid)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
BEGIN
  IF auth.role() <> 'service_role' THEN
    RAISE EXCEPTION 'Operasi harus dipanggil melalui service backend';
  END IF;

  IF p_method_id IS NOT NULL AND NOT EXISTS (
    SELECT 1 FROM public.event_payment_methods WHERE id = p_method_id
  ) THEN
    RAISE EXCEPTION 'Informasi pembayaran tidak ditemukan';
  END IF;

  UPDATE public.event_payment_methods
  SET is_default = false
  WHERE is_default;

  IF p_method_id IS NOT NULL THEN
    UPDATE public.event_payment_methods
    SET is_default = true
    WHERE id = p_method_id;
  END IF;

  RETURN p_method_id;
END;
$$;

REVOKE ALL ON FUNCTION public.set_default_ticket_payment_method(uuid) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.set_default_ticket_payment_method(uuid) TO service_role;

CREATE OR REPLACE FUNCTION public.apply_default_ticket_payment_method_on_publish()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
DECLARE
  default_method_id uuid;
BEGIN
  IF NOT NEW.published OR (TG_OP = 'UPDATE' AND OLD.published) THEN
    RETURN NEW;
  END IF;

  SELECT id INTO default_method_id
  FROM public.event_payment_methods
  WHERE is_default
  FOR SHARE;

  IF default_method_id IS NULL THEN
    RETURN NEW;
  END IF;

  UPDATE public.event_payment_method_assignments
  SET is_active = false,
      updated_at = now()
  WHERE event_id = NEW.id AND is_active;

  INSERT INTO public.event_payment_method_assignments (payment_method_id, event_id, is_active)
  VALUES (default_method_id, NEW.id, true)
  ON CONFLICT (payment_method_id, event_id) DO UPDATE
  SET is_active = true,
      updated_at = now();

  RETURN NEW;
END;
$$;

REVOKE ALL ON FUNCTION public.apply_default_ticket_payment_method_on_publish() FROM PUBLIC, anon, authenticated;

DROP TRIGGER IF EXISTS apply_default_ticket_payment_method_on_publish ON public.events;
CREATE TRIGGER apply_default_ticket_payment_method_on_publish
  AFTER INSERT OR UPDATE OF published ON public.events
  FOR EACH ROW
  WHEN (NEW.published = true)
  EXECUTE FUNCTION public.apply_default_ticket_payment_method_on_publish();


-- Source migration: 20261007134000_add_account_active_sessions.sql
CREATE TABLE IF NOT EXISTS public.account_active_sessions (
  user_id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  device_id uuid NOT NULL,
  device_label text NOT NULL,
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.account_active_sessions ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON public.account_active_sessions FROM PUBLIC, anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.account_active_sessions TO authenticated;

DROP POLICY IF EXISTS "users_manage_own_active_account_session" ON public.account_active_sessions;
CREATE POLICY "users_manage_own_active_account_session"
  ON public.account_active_sessions
  FOR ALL
  TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime'
      AND schemaname = 'public'
      AND tablename = 'account_active_sessions'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.account_active_sessions;
  END IF;
END;
$$;


-- Source migration: 20261008120000_add_komika_card_photo.sql
ALTER TABLE public.komika
  ADD COLUMN IF NOT EXISTS photo_card text;


-- Source migration: 20261009100000_create_annual_recaps.sql
CREATE TABLE IF NOT EXISTS public.annual_recaps (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  year smallint NOT NULL UNIQUE,
  published boolean NOT NULL DEFAULT false,
  closing_narrative text,
  created_by uuid,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.annual_recaps ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "public_select_published_annual_recaps" ON public.annual_recaps;
CREATE POLICY "public_select_published_annual_recaps"
ON public.annual_recaps
FOR SELECT
TO anon, authenticated
USING (published = true);

DROP POLICY IF EXISTS "admin_select_all_annual_recaps" ON public.annual_recaps;
CREATE POLICY "admin_select_all_annual_recaps"
ON public.annual_recaps
FOR SELECT
TO authenticated
USING (public.jwt_has_role('admin'));

DROP POLICY IF EXISTS "annual_recaps_select_visibility_guard" ON public.annual_recaps;
CREATE POLICY "annual_recaps_select_visibility_guard"
ON public.annual_recaps
AS RESTRICTIVE
FOR SELECT
TO anon, authenticated
USING (published = true OR public.jwt_has_role('admin'));

DROP POLICY IF EXISTS "admin_manage_annual_recaps" ON public.annual_recaps;
CREATE POLICY "admin_manage_annual_recaps"
ON public.annual_recaps
FOR INSERT
TO authenticated
WITH CHECK (public.jwt_has_role('admin'));

DROP POLICY IF EXISTS "annual_recaps_insert_admin_guard" ON public.annual_recaps;
CREATE POLICY "annual_recaps_insert_admin_guard"
ON public.annual_recaps
AS RESTRICTIVE
FOR INSERT
TO authenticated
WITH CHECK (public.jwt_has_role('admin'));

DROP POLICY IF EXISTS "admin_manage_annual_recaps_update" ON public.annual_recaps;
CREATE POLICY "admin_manage_annual_recaps_update"
ON public.annual_recaps
FOR UPDATE
TO authenticated
USING (public.jwt_has_role('admin'))
WITH CHECK (public.jwt_has_role('admin'));

DROP POLICY IF EXISTS "annual_recaps_update_admin_guard" ON public.annual_recaps;
CREATE POLICY "annual_recaps_update_admin_guard"
ON public.annual_recaps
AS RESTRICTIVE
FOR UPDATE
TO authenticated
USING (public.jwt_has_role('admin'))
WITH CHECK (public.jwt_has_role('admin'));

REVOKE ALL ON TABLE public.annual_recaps FROM PUBLIC;
REVOKE ALL ON TABLE public.annual_recaps FROM anon;
REVOKE ALL ON TABLE public.annual_recaps FROM authenticated;
GRANT SELECT ON TABLE public.annual_recaps TO anon, authenticated;
GRANT INSERT, UPDATE ON TABLE public.annual_recaps TO authenticated;

NOTIFY pgrst, 'reload schema';


-- Source migration: 20261012100000_create_event_lineups_and_stage_experiences.sql
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


-- Source migration: 20261012110000_expand_event_lineup_roles.sql
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


-- Source migration: 20261012120000_add_event_lineup_external_link.sql
ALTER TABLE public.event_lineups
  ADD COLUMN IF NOT EXISTS external_url text;

ALTER TABLE public.event_lineups
  DROP CONSTRAINT IF EXISTS event_lineups_external_url_check;

ALTER TABLE public.event_lineups
  ADD CONSTRAINT event_lineups_external_url_check
  CHECK (external_url IS NULL OR external_url ~* '^https://');


-- Source migration: 20261012130000_create_ccs_schedules.sql
CREATE TABLE IF NOT EXISTS public.ccs_schedules (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title text NOT NULL DEFAULT 'Serang Comedy Sharing (CCS)'
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


-- Source migration: 20261012140000_add_ccs_date_override.sql
ALTER TABLE public.ccs_schedules
  ADD COLUMN IF NOT EXISTS date_override boolean NOT NULL DEFAULT false;

DROP POLICY IF EXISTS "public_read_upcoming_ccs_schedules" ON public.ccs_schedules;
CREATE POLICY "public_read_upcoming_ccs_schedules"
  ON public.ccs_schedules FOR SELECT TO anon, authenticated
  USING (is_published = true);


-- Source migration: 20261013120000_allow_member_manage_own_specialties.sql
DROP POLICY IF EXISTS "admin_all_komika" ON public.komika;
DROP POLICY IF EXISTS "admin_select_komika" ON public.komika;
DROP POLICY IF EXISTS "admin_insert_komika" ON public.komika;
DROP POLICY IF EXISTS "admin_update_komika" ON public.komika;
DROP POLICY IF EXISTS "admin_delete_komika" ON public.komika;
DROP POLICY IF EXISTS "member_update_own_profile" ON public.komika;

CREATE POLICY "admin_select_komika" ON public.komika FOR SELECT TO authenticated
  USING (public.jwt_has_role('admin'));
CREATE POLICY "admin_insert_komika" ON public.komika FOR INSERT TO authenticated
  WITH CHECK (public.jwt_has_role('admin'));
CREATE POLICY "admin_update_komika" ON public.komika FOR UPDATE TO authenticated
  USING (public.jwt_has_role('admin'))
  WITH CHECK (public.jwt_has_role('admin'));
CREATE POLICY "admin_delete_komika" ON public.komika FOR DELETE TO authenticated
  USING (public.jwt_has_role('admin'));
CREATE POLICY "member_update_own_profile" ON public.komika FOR UPDATE TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

CREATE OR REPLACE FUNCTION public.prevent_member_komika_protected_changes()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT public.jwt_has_role('admin') THEN
    IF NEW.id IS DISTINCT FROM OLD.id
      OR NEW.user_id IS DISTINCT FROM OLD.user_id
      OR NEW.full_name IS DISTINCT FROM OLD.full_name
      OR NEW.slug IS DISTINCT FROM OLD.slug
      OR NEW.joined_at IS DISTINCT FROM OLD.joined_at
      OR NEW.featured_order IS DISTINCT FROM OLD.featured_order
      OR NEW.status IS DISTINCT FROM OLD.status
      OR NEW.published IS DISTINCT FROM OLD.published
      OR NEW.created_at IS DISTINCT FROM OLD.created_at
    THEN
      RAISE EXCEPTION 'Member hanya dapat mengubah data profil publik yang diizinkan';
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS protect_member_komika_fields ON public.komika;
CREATE TRIGGER protect_member_komika_fields
  BEFORE UPDATE ON public.komika
  FOR EACH ROW
  EXECUTE FUNCTION public.prevent_member_komika_protected_changes();

-- Source migration: 20261013130000_expand_member_stage_experience_roles.sql
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

-- Source migration: 20261013140000_add_annual_recap_music.sql
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
