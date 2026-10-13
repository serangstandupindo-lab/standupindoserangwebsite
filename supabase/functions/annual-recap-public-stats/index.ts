import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { serve } from 'https://deno.land/std@0.224.0/http/server.ts';
import { chunkValues, fetchAllPages } from '../_shared/pagination.ts';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

type RequestBody = { year?: unknown };
type EventRow = { id: string; date: string };
type PaidOrder = { id: string; event_id: string };
type CheckedInTicket = { event_id: string; ticket_order_id: string; checked_in_at: string | null };

function json(body: Record<string, unknown>, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json', 'Cache-Control': 'public, max-age=300' },
  });
}

function getJakartaDate() {
  const parts = new Intl.DateTimeFormat('en-CA', {
    timeZone: 'Asia/Jakarta',
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
  }).formatToParts(new Date());
  const part = (type: string) => parts.find((entry) => entry.type === type)?.value ?? '';
  return `${part('year')}-${part('month')}-${part('day')}`;
}

serve(async (request) => {
  if (request.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });
  if (request.method !== 'POST') return json({ error: 'Method not allowed.' }, 405);

  let body: RequestBody;
  try {
    const parsed: unknown = await request.json();
    if (parsed === null || typeof parsed !== 'object' || Array.isArray(parsed)) {
      return json({ error: 'Data permintaan tidak valid.' }, 400);
    }
    body = parsed as RequestBody;
  } catch {
    return json({ error: 'Data permintaan tidak valid.' }, 400);
  }

  const currentYear = Number(getJakartaDate().slice(0, 4));
  if (typeof body.year !== 'number' || !Number.isInteger(body.year) || body.year < 1900 || body.year > currentYear) {
    return json({ error: 'Tahun recap tidak valid.' }, 400);
  }

  const supabaseUrl = Deno.env.get('SUPABASE_URL');
  const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
  if (!supabaseUrl || !serviceRoleKey) return json({ error: 'Konfigurasi Annual Recap belum tersedia.' }, 500);

  const serviceClient = createClient(supabaseUrl, serviceRoleKey);
  const fromDate = `${body.year}-01-01`;
  const yearEnd = `${body.year + 1}-01-01`;
  const untilDate = body.year === currentYear ? getJakartaDate() : yearEnd;

  try {
    const { data: recap, error: recapError } = await serviceClient.from('annual_recaps')
      .select('year')
      .eq('year', body.year)
      .eq('published', true)
      .maybeSingle();
    if (recapError) return json({ error: 'Status publikasi recap gagal dimuat.' }, 500);
    if (!recap) return json({ error: 'Annual Recap tidak tersedia.' }, 404);

    const { data: eventRows, error: eventError } = await fetchAllPages((from, to) => serviceClient
      .from('events')
      .select('id, date')
      .eq('published', true)
      .neq('status', 'cancelled')
      .gte('date', fromDate)
      .lt('date', untilDate)
      .order('date', { ascending: true })
      .range(from, to));
    if (eventError) return json({ error: 'Data Event gagal dimuat.' }, 500);

    const events = (eventRows ?? []) as EventRow[];
    const eventIds = events.map((event) => event.id);
    if (eventIds.length === 0) return json({ year: body.year, totalCheckedIn: 0, events: [] });

    const paidOrders: PaidOrder[] = [];
    for (const ids of chunkValues(eventIds)) {
      const { data, error } = await fetchAllPages((from, to) => serviceClient
        .from('ticket_orders')
        .select('id, event_id')
        .eq('status', 'Lunas')
        .in('event_id', ids)
        .order('id', { ascending: true })
        .range(from, to));
      if (error) return json({ error: 'Data tiket gagal dimuat.' }, 500);
      paidOrders.push(...((data ?? []) as PaidOrder[]));
    }

    const orderEventById = new Map(paidOrders.map((order) => [order.id, order.event_id]));
    const checkedInByEvent = new Map<string, number>();
    for (const orderIds of chunkValues(paidOrders.map((order) => order.id))) {
      const { data, error } = await fetchAllPages((from, to) => serviceClient
        .from('ticket_instances')
        .select('event_id, ticket_order_id, checked_in_at')
        .in('ticket_order_id', orderIds)
        .not('checked_in_at', 'is', null)
        .order('id', { ascending: true })
        .range(from, to));
      if (error) return json({ error: 'Data check-in gagal dimuat.' }, 500);

      ((data ?? []) as CheckedInTicket[]).forEach((ticket) => {
        if (!ticket.checked_in_at || orderEventById.get(ticket.ticket_order_id) !== ticket.event_id) return;
        checkedInByEvent.set(ticket.event_id, (checkedInByEvent.get(ticket.event_id) ?? 0) + 1);
      });
    }

    const eventStats = events.map((event) => ({ eventId: event.id, checkedIn: checkedInByEvent.get(event.id) ?? 0 }));
    return json({
      year: body.year,
      totalCheckedIn: eventStats.reduce((total, event) => total + event.checkedIn, 0),
      events: eventStats,
    });
  } catch (error) {
    console.error('annual-recap-public-stats failed', error instanceof Error ? error.message : 'Unknown error');
    return json({ error: 'Statistik Annual Recap gagal diproses.' }, 500);
  }
});