-- Wardrobe photos are personal — switch from a public bucket to private,
-- signed-URL access only. (Feedback screenshots stay public: low sensitivity,
-- and the dev-facing email needs to render them without auth.)

update storage.buckets set public = false where id = 'tw-wardrobe-images';

drop policy if exists "public read of wardrobe images" on storage.objects;

-- "users manage their own wardrobe images" policy (insert/update/delete/select
-- scoped to auth.uid() = first folder segment) already covers everything an
-- owner needs, including generating their own signed URLs.
