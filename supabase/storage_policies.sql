-- Execute este arquivo no SQL Editor do seu projeto Supabase.
-- O bucket permanece privado: convidados podem enviar, mas não baixar/listar.

insert into storage.buckets (
  id,
  name,
  public,
  file_size_limit,
  allowed_mime_types
)
values (
  'casamento',
  'casamento',
  false,
  15728640,
  array['image/jpeg', 'image/png', 'image/webp', 'image/heic']
)
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "Convidados podem enviar fotos" on storage.objects;
drop policy if exists "Permitir upload de fotos do casamento" on storage.objects;

create policy "Permitir upload de fotos do casamento"
on storage.objects
for insert
to anon, authenticated
with check (
  bucket_id = 'casamento'
  and name like 'fotos/%'
);
