-- Suppression de compte (exigée par Google Play et l'App Store).
--
-- Les données financières des groupes appartiennent aussi aux autres
-- membres : elles sont conservées, anonymisées (la fiche membre redevient
-- une fiche « sans compte », l'auteur des opérations devient inconnu).
-- Un groupe dont le compte était le seul membre est supprimé entièrement.
-- Un propriétaire ne part pas en laissant un groupe sans propriétaire.

-- Les références à un compte deviennent facultatives et se vident à sa
-- suppression.
alter table public.groups alter column created_by drop not null;
alter table public.groups drop constraint groups_created_by_fkey,
  add constraint groups_created_by_fkey foreign key (created_by)
    references auth.users (id) on delete set null;

alter table public.group_invitations drop constraint group_invitations_created_by_fkey,
  add constraint group_invitations_created_by_fkey foreign key (created_by)
    references auth.users (id) on delete set null;
alter table public.group_invitations alter column created_by drop not null;
alter table public.group_invitations drop constraint group_invitations_claimed_by_fkey,
  add constraint group_invitations_claimed_by_fkey foreign key (claimed_by)
    references auth.users (id) on delete set null;

alter table public.tontine_proofs alter column created_by drop not null;
alter table public.tontine_proofs drop constraint tontine_proofs_created_by_fkey,
  add constraint tontine_proofs_created_by_fkey foreign key (created_by)
    references auth.users (id) on delete set null;

alter table public.tontine_contributions alter column author_id drop not null;
alter table public.tontine_contributions drop constraint tontine_contributions_author_id_fkey,
  add constraint tontine_contributions_author_id_fkey foreign key (author_id)
    references auth.users (id) on delete set null;

alter table public.tontine_declarations alter column created_by drop not null;
alter table public.tontine_declarations drop constraint tontine_declarations_created_by_fkey,
  add constraint tontine_declarations_created_by_fkey foreign key (created_by)
    references auth.users (id) on delete set null;

alter table public.tontine_turn_changes alter column author_id drop not null;
alter table public.tontine_turn_changes drop constraint tontine_turn_changes_author_id_fkey,
  add constraint tontine_turn_changes_author_id_fkey foreign key (author_id)
    references auth.users (id) on delete set null;

-- Supprime le compte courant. Échoue avec `transfer_ownership_required` si
-- le compte est le seul propriétaire actif d'un groupe où d'autres
-- personnes ont un compte : il faut d'abord nommer un autre propriétaire.
create or replace function public.delete_my_account() returns void
language plpgsql security definer set search_path = '' as $$
declare
  v_uid uuid := private.require_user();
begin
  if exists (
    select 1
    from public.group_members moi
    where moi.user_id = v_uid
      and moi.roles @> array['owner']::public.member_role[]
      and not exists (
        select 1 from public.group_members autre
        where autre.group_id = moi.group_id
          and autre.id <> moi.id
          and autre.active
          and autre.roles @> array['owner']::public.member_role[]
      )
      and exists (
        select 1 from public.group_members autre
        where autre.group_id = moi.group_id
          and autre.id <> moi.id
          and autre.user_id is not null
      )
  ) then
    raise exception 'transfer_ownership_required' using errcode = '55000';
  end if;

  -- Groupes où personne d'autre n'a de compte : ils disparaissent avec lui.
  delete from public.groups g
  where exists (select 1 from public.group_members m where m.group_id = g.id and m.user_id = v_uid)
    and not exists (
      select 1 from public.group_members m
      where m.group_id = g.id and m.user_id is not null and m.user_id <> v_uid
    );

  -- Partout ailleurs : la fiche reste (soldes, historique), sans compte ni
  -- coordonnées personnelles.
  update public.group_members
  set email = null, whatsapp = null
  where user_id = v_uid;

  delete from auth.users where id = v_uid;
end;
$$;

revoke all on function public.delete_my_account() from public, anon;
grant execute on function public.delete_my_account() to authenticated;
