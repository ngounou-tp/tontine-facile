-- Suivi des e-mails d'invitation (Edge Function `send-invitation-email`).
--
-- Écrit UNIQUEMENT par la fonction serveur (rôle service) : aucun client
-- ne peut le créer ni le falsifier. Seul le bureau du groupe le lit (il
-- contient l'adresse du destinataire et l'éventuelle cause d'échec).

create table public.invitation_deliveries (
  member_id uuid primary key,
  group_id uuid not null,
  code text not null,
  email text,
  status text not null check (status in ('en_cours', 'envoye', 'simule', 'echec', 'sans_email')),
  error text,
  updated_at timestamptz not null default now(),
  sent_at timestamptz,
  foreign key (member_id, group_id) references public.group_members (id, group_id) on delete cascade
);

alter table public.invitation_deliveries enable row level security;
revoke all on public.invitation_deliveries from anon, authenticated;
grant select on public.invitation_deliveries to authenticated;
grant select, insert, update on public.invitation_deliveries to service_role;

create policy invitation_deliveries_select_manager on public.invitation_deliveries
  for select to authenticated using (private.is_manager(group_id));

-- Réserve l'envoi d'un e-mail, atomiquement : `false` si cet envoi est déjà
-- fait, ou en cours depuis moins de 5 minutes (un webhook peut être livré
-- plusieurs fois). Au-delà, une réservation est considérée comme abandonnée.
create or replace function public.reserve_invitation_delivery(
  p_member_id uuid,
  p_group_id uuid,
  p_code text,
  p_email text
) returns boolean
language plpgsql security definer set search_path = '' as $$
declare
  v_existant public.invitation_deliveries;
begin
  -- Sérialise les livraisons concurrentes pour ce membre.
  perform pg_advisory_xact_lock(hashtext(p_member_id::text));

  select * into v_existant from public.invitation_deliveries where member_id = p_member_id;
  if found and v_existant.code = p_code then
    if v_existant.status in ('envoye', 'simule') then
      return false;
    end if;
    if v_existant.status = 'en_cours' and v_existant.updated_at > now() - interval '5 minutes' then
      return false;
    end if;
  end if;

  insert into public.invitation_deliveries (member_id, group_id, code, email, status, error, updated_at)
  values (p_member_id, p_group_id, p_code, p_email, 'en_cours', null, now())
  on conflict (member_id) do update
    set code = excluded.code, email = excluded.email, status = 'en_cours',
        error = null, updated_at = now();
  return true;
end;
$$;

revoke all on function public.reserve_invitation_delivery(uuid, uuid, text, text) from public, anon, authenticated;
grant execute on function public.reserve_invitation_delivery(uuid, uuid, text, text) to service_role;
