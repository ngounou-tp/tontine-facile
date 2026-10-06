-- DjanguiBook — socle multi-groupes : profils, groupes, membres, rôles et
-- invitations.
--
-- Principes :
-- * Un utilisateur peut appartenir à plusieurs groupes, avec des rôles
--   cumulables et propres à chaque groupe.
-- * L'appartenance (`group_members.user_id`) n'est JAMAIS écrite par le
--   client : seules les fonctions `create_tontine` et `claim_invitation`
--   l'établissent. C'est ce qui ferme l'usurpation possible avec l'ancien
--   modèle (profil Firestore modifiable par son propriétaire).
-- * Toute table du schéma public a la RLS activée ; les droits SQL sont
--   accordés explicitement (rien n'est hérité des privilèges par défaut).

create extension if not exists pgcrypto with schema extensions;

-- ---------------------------------------------------------------------------
-- Types
-- ---------------------------------------------------------------------------

create type public.group_kind as enum ('tontine', 'caisse');

-- owner : créateur (gère les rôles). president / treasurer : bureau.
-- auditor : commissaire aux comptes (lecture étendue). member : membre.
create type public.member_role as enum ('owner', 'president', 'treasurer', 'auditor', 'member');

-- ---------------------------------------------------------------------------
-- Tables
-- ---------------------------------------------------------------------------

create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  display_name text,
  locale text check (locale in ('fr', 'en')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.groups (
  id uuid primary key default gen_random_uuid(),
  kind public.group_kind not null,
  name text not null check (char_length(btrim(name)) between 2 and 80),
  currency text not null default 'XAF' check (currency ~ '^[A-Z]{3}$'),
  timezone text not null default 'Africa/Douala',
  created_by uuid not null references auth.users (id),
  created_at timestamptz not null default now()
);

create table public.group_members (
  id uuid primary key default gen_random_uuid(),
  group_id uuid not null references public.groups (id) on delete cascade,
  -- NULL : membre « sans application » ou invitation pas encore réclamée.
  user_id uuid references auth.users (id) on delete set null,
  full_name text not null check (char_length(btrim(full_name)) between 2 and 120),
  email text check (email is null or position('@' in email) > 1),
  whatsapp text,
  roles public.member_role[] not null default array['member']::public.member_role[]
    check (cardinality(roles) > 0),
  active boolean not null default true,
  invitation_code text,
  joined_at timestamptz,
  created_at timestamptz not null default now(),
  unique (group_id, user_id),
  -- Cible des clés étrangères composites : une ligne enfant ne peut pas
  -- désigner le membre d'un autre groupe.
  unique (id, group_id)
);
create index group_members_user_id_idx on public.group_members (user_id);

create table public.group_invitations (
  code text primary key check (code ~ '^[A-Z0-9]{6}$'),
  group_id uuid not null references public.groups (id) on delete cascade,
  member_id uuid not null,
  created_by uuid not null references auth.users (id),
  created_at timestamptz not null default now(),
  claimed_by uuid references auth.users (id),
  claimed_at timestamptz,
  foreign key (member_id, group_id) references public.group_members (id, group_id) on delete cascade
);
create index group_invitations_member_idx on public.group_invitations (member_id);

-- ---------------------------------------------------------------------------
-- Fonctions d'autorisation (schéma privé, non exposé par l'API)
-- ---------------------------------------------------------------------------

create schema if not exists private;
grant usage on schema private to authenticated;

-- SECURITY DEFINER : lues depuis les politiques RLS de group_members
-- elles-mêmes, elles doivent contourner cette RLS pour ne pas boucler.
create or replace function private.is_member(p_group_id uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from public.group_members m
    where m.group_id = p_group_id and m.user_id = auth.uid()
  )
$$;

create or replace function private.has_any_role(p_group_id uuid, p_roles public.member_role[])
returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from public.group_members m
    where m.group_id = p_group_id
      and m.user_id = auth.uid()
      and m.active
      and m.roles && p_roles
  )
$$;

-- Bureau : peut gérer le groupe au quotidien (membres, noms, tours,
-- cotisations, validations).
create or replace function private.is_manager(p_group_id uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  select private.has_any_role(
    p_group_id,
    array['owner', 'president', 'treasurer']::public.member_role[]
  )
$$;

-- Identifiant de la fiche membre de l'utilisateur courant dans un groupe.
create or replace function private.my_member_id(p_group_id uuid) returns uuid
language sql stable security definer set search_path = '' as $$
  select m.id from public.group_members m
  where m.group_id = p_group_id and m.user_id = auth.uid()
$$;

grant execute on all functions in schema private to authenticated;

-- ---------------------------------------------------------------------------
-- RLS et droits
-- ---------------------------------------------------------------------------

alter table public.profiles enable row level security;
alter table public.groups enable row level security;
alter table public.group_members enable row level security;
alter table public.group_invitations enable row level security;

revoke all on public.profiles, public.groups, public.group_members, public.group_invitations
  from anon, authenticated;

-- Profils : chacun le sien.
grant select, insert on public.profiles to authenticated;
grant update (display_name, locale, updated_at) on public.profiles to authenticated;
create policy profiles_select_own on public.profiles
  for select to authenticated using (id = auth.uid());
create policy profiles_insert_own on public.profiles
  for insert to authenticated with check (id = auth.uid());
create policy profiles_update_own on public.profiles
  for update to authenticated using (id = auth.uid()) with check (id = auth.uid());

-- Groupes : visibles par leurs membres ; création par `create_tontine`.
grant select on public.groups to authenticated;
grant update (name, timezone) on public.groups to authenticated;
create policy groups_select_member on public.groups
  for select to authenticated using (private.is_member(id));
create policy groups_update_manager on public.groups
  for update to authenticated
  using (private.is_manager(id)) with check (private.is_manager(id));

-- Membres : lisibles par tout membre du groupe (transparence, comme
-- avant) ; le bureau modifie coordonnées et activation, jamais `user_id`
-- ni `roles` (droits par colonne) — voir `set_member_roles`.
grant select on public.group_members to authenticated;
grant update (full_name, email, whatsapp, active) on public.group_members to authenticated;
create policy group_members_select_member on public.group_members
  for select to authenticated using (private.is_member(group_id));
create policy group_members_update_manager on public.group_members
  for update to authenticated
  using (private.is_manager(group_id)) with check (private.is_manager(group_id));

-- Invitations : aucun accès direct ; uniquement via les fonctions.

-- ---------------------------------------------------------------------------
-- Profil créé à l'inscription
-- ---------------------------------------------------------------------------

create or replace function private.handle_new_user() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  insert into public.profiles (id, display_name, locale)
  values (
    new.id,
    nullif(btrim(new.raw_user_meta_data ->> 'display_name'), ''),
    case when new.raw_user_meta_data ->> 'locale' in ('fr', 'en')
      then new.raw_user_meta_data ->> 'locale' end
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function private.handle_new_user();

-- ---------------------------------------------------------------------------
-- Fonctions métier (RPC)
-- ---------------------------------------------------------------------------
-- Les erreurs métier sont signalées par un message stable (code) que
-- l'application traduit : `invitation_not_found`, `forbidden`, etc.

create or replace function private.require_user() returns uuid
language plpgsql stable set search_path = '' as $$
declare
  v_uid uuid := auth.uid();
begin
  if v_uid is null then
    raise exception 'sign_in_required' using errcode = '28000';
  end if;
  return v_uid;
end;
$$;

create or replace function private.require_manager(p_group_id uuid) returns uuid
language plpgsql stable set search_path = '' as $$
declare
  v_uid uuid := private.require_user();
begin
  if not private.is_manager(p_group_id) then
    raise exception 'forbidden' using errcode = '42501';
  end if;
  return v_uid;
end;
$$;

-- Code d'invitation : 6 caractères lisibles (sans 0/O, 1/I), unique.
create or replace function private.new_invitation_code() returns text
language plpgsql volatile set search_path = '' as $$
declare
  v_alphabet constant text := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  v_code text;
begin
  for attempt in 1..20 loop
    v_code := '';
    for i in 1..6 loop
      v_code := v_code || substr(
        v_alphabet,
        1 + (get_byte(extensions.gen_random_bytes(1), 0) % length(v_alphabet)),
        1
      );
    end loop;
    if not exists (select 1 from public.group_invitations where code = v_code) then
      return v_code;
    end if;
  end loop;
  raise exception 'invitation_code_exhausted';
end;
$$;

-- Ajoute un membre (sans compte) et génère son invitation nominative.
create or replace function public.invite_member(
  p_group_id uuid,
  p_full_name text,
  p_email text default null,
  p_whatsapp text default null
) returns table (member_id uuid, code text)
language plpgsql security definer set search_path = '' as $$
declare
  v_uid uuid := private.require_manager(p_group_id);
  v_member_id uuid;
  v_code text := private.new_invitation_code();
begin
  if nullif(btrim(p_email), '') is null and nullif(btrim(p_whatsapp), '') is null then
    raise exception 'contact_required' using errcode = '22023';
  end if;

  insert into public.group_members (group_id, full_name, email, whatsapp, invitation_code)
  values (
    p_group_id,
    btrim(p_full_name),
    nullif(btrim(p_email), ''),
    nullif(btrim(p_whatsapp), ''),
    v_code
  )
  returning id into v_member_id;

  insert into public.group_invitations (code, group_id, member_id, created_by)
  values (v_code, p_group_id, v_member_id, v_uid);

  return query select v_member_id, v_code;
end;
$$;

-- Aperçu public d'une invitation (avant même de créer un compte) : nom du
-- groupe et nombre de membres. Rien d'autre ne fuit.
create or replace function public.invitation_preview(p_code text)
returns table (group_name text, group_kind public.group_kind, member_count integer, claimed boolean)
language sql stable security definer set search_path = '' as $$
  select g.name, g.kind,
         (select count(*)::integer from public.group_members m where m.group_id = g.id and m.active),
         i.claimed_at is not null
  from public.group_invitations i
  join public.groups g on g.id = i.group_id
  where i.code = upper(btrim(p_code))
$$;

-- Réclame une invitation : rattache le compte courant à la fiche membre.
create or replace function public.claim_invitation(p_code text)
returns table (group_id uuid, member_id uuid)
language plpgsql security definer set search_path = '' as $$
declare
  v_uid uuid := private.require_user();
  v_invitation public.group_invitations;
begin
  select * into v_invitation
  from public.group_invitations
  where code = upper(btrim(p_code))
  for update;

  if not found then
    raise exception 'invitation_not_found' using errcode = 'P0002';
  end if;

  if v_invitation.claimed_at is not null or exists (
    select 1 from public.group_members m
    where m.id = v_invitation.member_id and m.user_id is not null
  ) then
    raise exception 'invitation_already_used' using errcode = '23505';
  end if;

  if exists (
    select 1 from public.group_members m
    where m.group_id = v_invitation.group_id and m.user_id = v_uid
  ) then
    raise exception 'already_member' using errcode = '23505';
  end if;

  update public.group_members
  set user_id = v_uid, joined_at = now()
  where id = v_invitation.member_id;

  update public.group_invitations
  set claimed_by = v_uid, claimed_at = now()
  where code = v_invitation.code;

  return query select v_invitation.group_id, v_invitation.member_id;
end;
$$;

-- Change les rôles d'un membre (propriétaire uniquement). Le groupe garde
-- toujours au moins un propriétaire actif.
create or replace function public.set_member_roles(p_member_id uuid, p_roles public.member_role[])
returns void
language plpgsql security definer set search_path = '' as $$
declare
  v_group_id uuid;
begin
  perform private.require_user();
  select group_id into v_group_id from public.group_members where id = p_member_id;
  if v_group_id is null or not private.has_any_role(v_group_id, array['owner']::public.member_role[]) then
    raise exception 'forbidden' using errcode = '42501';
  end if;
  if coalesce(cardinality(p_roles), 0) = 0 then
    raise exception 'roles_required' using errcode = '22023';
  end if;

  update public.group_members set roles = p_roles where id = p_member_id;

  if not exists (
    select 1 from public.group_members
    where group_id = v_group_id and active and roles @> array['owner']::public.member_role[]
  ) then
    raise exception 'last_owner' using errcode = '23514';
  end if;
end;
$$;

revoke all on function public.invite_member(uuid, text, text, text) from public, anon;
revoke all on function public.claim_invitation(text) from public, anon;
revoke all on function public.set_member_roles(uuid, public.member_role[]) from public, anon;
revoke all on function public.invitation_preview(text) from public;
grant execute on function public.invite_member(uuid, text, text, text) to authenticated;
grant execute on function public.claim_invitation(text) to authenticated;
grant execute on function public.set_member_roles(uuid, public.member_role[]) to authenticated;
grant execute on function public.invitation_preview(text) to anon, authenticated;
