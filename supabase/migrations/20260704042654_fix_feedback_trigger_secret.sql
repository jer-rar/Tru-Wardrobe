-- SECURITY FIX 2026-07-04: the previous version of this function
-- (20260704033308_feedback.sql) hardcoded the service_role key in the
-- Authorization header. That file got committed to git and pushed to the
-- public Tru-Wardrobe GitHub repo — flagged by GitGuardian.
--
-- The notify-feedback Edge Function is deployed with --no-verify-jwt, so it
-- never actually needed a valid service_role token in the first place — any
-- Authorization header satisfies Supabase's gateway routing. Replaced the
-- leaked service_role key with the anon/publishable key instead, which is
-- meant to be public (it's already embedded in the compiled app and visible
-- in app_constants.dart in this same repo) — so this migration file is safe
-- to have in public source control going forward.

create or replace function public.notify_feedback_webhook()
returns trigger as $$
begin
  perform net.http_post(
    url := 'https://yxqrbjpvckvzgspgczok.supabase.co/functions/v1/notify-feedback',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inl4cXJianB2Y2t2emdzcGdjem9rIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODMwNzg1MDMsImV4cCI6MjA5ODY1NDUwM30.naoiGkMic0d6Kq67vfrGLEx9HDd8monJU6X7M4DGTH4'
    ),
    body := jsonb_build_object('type', 'INSERT', 'table', 'tw_feedback', 'record', to_jsonb(new))
  );
  return new;
end;
$$ language plpgsql security definer;
