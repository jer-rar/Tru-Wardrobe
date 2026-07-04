-- "Send to Dev" feedback feature, mirroring TruBrief's trl_feedback pattern.

create table tw_feedback (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete set null,
  user_email text,
  type text not null,
  message text not null,
  screenshot_url text,
  created_at timestamptz not null default now(),
  read boolean not null default false
);

alter table tw_feedback enable row level security;

create policy "users can submit feedback" on tw_feedback for insert
  with check (auth.uid() = user_id);

insert into storage.buckets (id, name, public)
values ('tw-feedback-screenshots', 'tw-feedback-screenshots', true)
on conflict (id) do nothing;

create policy "authenticated users can upload feedback screenshots"
  on storage.objects for insert
  with check (bucket_id = 'tw-feedback-screenshots' and auth.role() = 'authenticated');

create policy "public read of feedback screenshots"
  on storage.objects for select
  using (bucket_id = 'tw-feedback-screenshots');

-- Fires notify-feedback edge function (sends an email to the dev) on every new row.
-- Uses pg_net directly (rather than the dashboard-only supabase_functions.http_request
-- wrapper, which only exists once a webhook has been created via the dashboard UI) so
-- this works purely from a CLI-managed migration. Payload shape mimics Supabase's
-- official webhook format ({"type","table","record"}) so the edge function's
-- `body.record` access works unchanged.
create extension if not exists pg_net;

create or replace function public.notify_feedback_webhook()
returns trigger as $$
begin
  perform net.http_post(
    url := 'https://yxqrbjpvckvzgspgczok.supabase.co/functions/v1/notify-feedback',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inl4cXJianB2Y2t2emdzcGdjem9rIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc4MzA3ODUwMywiZXhwIjoyMDk4NjU0NTAzfQ.AY5-ka8Q8iBkbSK2d2pnJHk0pD3uUltsKrpdHobQfvM'
    ),
    body := jsonb_build_object('type', 'INSERT', 'table', 'tw_feedback', 'record', to_jsonb(new))
  );
  return new;
end;
$$ language plpgsql security definer;

create or replace trigger on_feedback_insert
  after insert on public.tw_feedback
  for each row
  execute function public.notify_feedback_webhook();
