import type { CcsSchedule } from '@/lib/types';

function getJakartaDateTime(date = new Date()): { date: string; time: string } {
  const parts = new Intl.DateTimeFormat('en-CA', {
    timeZone: 'Asia/Jakarta',
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
    hourCycle: 'h23',
  }).formatToParts(date);
  const values = Object.fromEntries(parts.map((part) => [part.type, part.value]));
  return {
    date: `${values.year}-${values.month}-${values.day}`,
    time: `${values.hour}:${values.minute}`,
  };
}

function nextOccurrence(date: string, time: string, startTime: string, targetWeekday: number): string {
  const weekday = new Date(`${date}T12:00:00Z`).getUTCDay();
  let daysUntilOccurrence = (targetWeekday - weekday + 7) % 7;
  if (daysUntilOccurrence === 0 && startTime <= time) daysUntilOccurrence = 7;
  const next = new Date(`${date}T12:00:00Z`);
  next.setUTCDate(next.getUTCDate() + daysUntilOccurrence);
  return next.toISOString().slice(0, 10);
}

export function getNextCcsWednesdayDate(now = new Date()): string {
  const current = getJakartaDateTime(now);
  return nextOccurrence(current.date, current.time, '00:00', 3);
}

export function getCcsOccurrenceDate(schedule: CcsSchedule, now = new Date()): string {
  const current = getJakartaDateTime(now);
  const startTime = schedule.start_time?.slice(0, 5) ?? '23:59';
  if (schedule.date_override && `${schedule.event_date}T${startTime}` >= `${current.date}T${current.time}`) {
    return schedule.event_date;
  }
  const recurringWeekday = schedule.date_override ? new Date(`${schedule.event_date}T12:00:00Z`).getUTCDay() : 3;

  return nextOccurrence(current.date, current.time, startTime, recurringWeekday);
}

export function isUpcomingCcsSchedule(schedule: CcsSchedule, now = new Date()): boolean {
  return getCcsOccurrenceDate(schedule, now) >= getJakartaDateTime(now).date;
}

export function getCcsMapsUrl(schedule: CcsSchedule): string | null {
  const verifiedUrl = schedule.maps_url?.trim();
  if (verifiedUrl && /^https:\/\//i.test(verifiedUrl)) return verifiedUrl;

  const venue = schedule.venue?.trim();
  return venue ? `https://www.google.com/maps/search/?api=1&query=${encodeURIComponent(venue)}` : null;
}

export function formatCcsTime(time: string | null): string | null {
  return time ? `${time.slice(0, 5)} WIB` : null;
}

export function formatCcsDate(date: string): string {
  return new Intl.DateTimeFormat('id-ID', {
    timeZone: 'Asia/Jakarta',
    day: 'numeric',
    month: 'long',
    year: 'numeric',
  }).format(new Date(`${date}T12:00:00+07:00`));
}

export function getCcsRecurrenceLabel(schedule: Pick<CcsSchedule, 'date_override' | 'event_date'>): string {
  const weekday = schedule.date_override
    ? new Date(`${schedule.event_date}T12:00:00Z`).getUTCDay()
    : 3;
  const label = new Intl.DateTimeFormat('id-ID', {
    timeZone: 'Asia/Jakarta',
    weekday: 'long',
  }).format(new Date(Date.UTC(2026, 0, 4 + weekday, 12)));
  return `Setiap ${label.charAt(0).toUpperCase()}${label.slice(1)}`;
}
