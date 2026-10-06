-- DjanguiBook — tontine rotative : réglages, noms et parts, tours,
-- cotisations, déclarations de paiement, preuves et historique des
-- réorganisations.
--
-- Lecture : tout membre du groupe (transparence, comme avant).
-- Écriture : le bureau (owner / president / treasurer), sauf la déclaration
-- de paiement et sa preuve, qu'un membre dépose pour un nom qu'il détient.

create table public.tontine_settings (
  group_id uuid primary key references public.groups (id) on delete cascade,
  amount_per_name bigint not null check (amount_per_name > 0),
  names_count integer not null check (names_count > 0),
  first_due_date date not null,
  periodicity jsonb not null check (jsonb_typeof(periodicity) = 'object' and periodicity ? 'type'),
  penalty_rule text not null check (penalty_rule in ('aucune', 'forfaitaire', 'proportionnelle')),
  penalty_value bigint check (penalty_value is null or penalty_value > 0),
  grace_days integer not null check (grace_days between 0 and 30),
  shares_mode text not null check (shares_mode in ('FIXED_AMOUNT', 'PROPORTIONAL', 'EQUAL_SHARE')),
  status text not null default 'active' check (status in ('active', 'cloturee')),
  updated_at timestamptz not null default now(),
  check ((penalty_rule = 'aucune') = (penalty_value is null))
);

create table public.tontine_names (
  id uuid primary key default gen_random_uuid(),
  group_id uuid not null references public.groups (id) on delete cascade,
  position integer not null check (position > 0),
  label text not null check (char_length(btrim(label)) between 1 and 60),
  created_at timestamptz not null default now(),
  unique (group_id, position) deferrable initially deferred,
  unique (id, group_id)
);

create table public.tontine_name_shares (
  name_id uuid not null,
  member_id uuid not null,
  group_id uuid not null,
  fraction numeric(9, 8) not null check (fraction > 0 and fraction <= 1),
  primary key (name_id, member_id),
  foreign key (name_id, group_id) references public.tontine_names (id, group_id) on delete cascade,
  foreign key (member_id, group_id) references public.group_members (id, group_id) on delete cascade
);
create index tontine_name_shares_member_idx on public.tontine_name_shares (group_id, member_id);

create table public.tontine_turns (
  id uuid primary key default gen_random_uuid(),
  group_id uuid not null references public.groups (id) on delete cascade,
  name_id uuid not null,
  position integer not null check (position > 0),
  planned_date date not null,
  status text not null check (status in ('aVenir', 'enCours', 'remis', 'reporte')),
  amount_paid_out bigint check (amount_paid_out is null or amount_paid_out >= 0),
  unique (group_id, position) deferrable initially deferred,
  unique (id, group_id),
  foreign key (name_id, group_id) references public.tontine_names (id, group_id) on delete restrict
);

create table public.tontine_proofs (
  id uuid primary key default gen_random_uuid(),
  group_id uuid not null references public.groups (id) on delete cascade,
  -- Chemin dans le bucket privé `proofs` : `<group_id>/<proof_id>.jpg`.
  storage_path text not null,
  size_bytes integer not null check (size_bytes > 0 and size_bytes <= 150000),
  created_by uuid not null default auth.uid() references auth.users (id),
  created_at timestamptz not null default now(),
  unique (id, group_id),
  check (storage_path like group_id::text || '/%')
);

create table public.tontine_contributions (
  id uuid primary key default gen_random_uuid(),
  group_id uuid not null references public.groups (id) on delete cascade,
  turn_id uuid not null,
  name_id uuid not null,
  member_id uuid not null,
  amount_due bigint not null check (amount_due > 0),
  amount_paid bigint not null check (amount_paid > 0 and amount_paid <= amount_due),
  payment_date date not null,
  origin text not null check (origin in ('administratrice', 'membre')),
  status text not null check (status in ('declaree', 'validee', 'refusee')),
  author_id uuid not null references auth.users (id),
  penalty bigint not null default 0 check (penalty >= 0),
  exception_reason text,
  rejection_reason text,
  proof_id uuid,
  created_at timestamptz not null default now(),
  check (status <> 'refusee' or nullif(btrim(rejection_reason), '') is not null),
  foreign key (turn_id, group_id) references public.tontine_turns (id, group_id) on delete restrict,
  foreign key (name_id, group_id) references public.tontine_names (id, group_id) on delete restrict,
  foreign key (member_id, group_id) references public.group_members (id, group_id) on delete restrict,
  foreign key (proof_id, group_id) references public.tontine_proofs (id, group_id) on delete restrict
);
create index tontine_contributions_turn_idx on public.tontine_contributions (group_id, turn_id);
create index tontine_contributions_member_idx on public.tontine_contributions (group_id, member_id);

create table public.tontine_declarations (
  id uuid primary key default gen_random_uuid(),
  group_id uuid not null references public.groups (id) on delete cascade,
  turn_id uuid not null,
  name_id uuid not null,
  member_id uuid not null,
  amount_declared bigint not null check (amount_declared > 0),
  payment_date date not null,
  proof_id uuid not null,
  status text not null default 'enAttente' check (status in ('enAttente', 'validee', 'contestee')),
  dispute_reason text,
  created_by uuid not null default auth.uid() references auth.users (id),
  created_at timestamptz not null default now(),
  updated_at timestamptz,
  check (status <> 'contestee' or nullif(btrim(dispute_reason), '') is not null),
  foreign key (turn_id, group_id) references public.tontine_turns (id, group_id) on delete restrict,
  foreign key (name_id, group_id) references public.tontine_names (id, group_id) on delete restrict,
  foreign key (member_id, group_id) references public.group_members (id, group_id) on delete restrict,
  foreign key (proof_id, group_id) references public.tontine_proofs (id, group_id) on delete restrict
);
create index tontine_declarations_status_idx on public.tontine_declarations (group_id, status);

create table public.tontine_turn_changes (
  id uuid primary key default gen_random_uuid(),
  group_id uuid not null references public.groups (id) on delete cascade,
  turn_id uuid not null,
  old_position integer not null check (old_position > 0),
  new_position integer not null check (new_position > 0 and new_position <> old_position),
  reason text not null check (char_length(btrim(reason)) > 0),
  author_id uuid not null default auth.uid() references auth.users (id),
  created_at timestamptz not null default now(),
  foreign key (turn_id, group_id) references public.tontine_turns (id, group_id) on delete cascade
);

-- ---------------------------------------------------------------------------
-- RLS et droits
-- ---------------------------------------------------------------------------

alter table public.tontine_settings enable row level security;
alter table public.tontine_names enable row level security;
alter table public.tontine_name_shares enable row level security;
alter table public.tontine_turns enable row level security;
alter table public.tontine_proofs enable row level security;
alter table public.tontine_contributions enable row level security;
alter table public.tontine_declarations enable row level security;
alter table public.tontine_turn_changes enable row level security;

revoke all on
  public.tontine_settings, public.tontine_names, public.tontine_name_shares,
  public.tontine_turns, public.tontine_proofs, public.tontine_contributions,
  public.tontine_declarations, public.tontine_turn_changes
from anon, authenticated;

grant select on
  public.tontine_settings, public.tontine_names, public.tontine_name_shares,
  public.tontine_turns, public.tontine_proofs, public.tontine_contributions,
  public.tontine_declarations, public.tontine_turn_changes
to authenticated;

-- Lecture : tout membre du groupe.
create policy tontine_settings_select on public.tontine_settings
  for select to authenticated using (private.is_member(group_id));
create policy tontine_names_select on public.tontine_names
  for select to authenticated using (private.is_member(group_id));
create policy tontine_name_shares_select on public.tontine_name_shares
  for select to authenticated using (private.is_member(group_id));
create policy tontine_turns_select on public.tontine_turns
  for select to authenticated using (private.is_member(group_id));
create policy tontine_proofs_select on public.tontine_proofs
  for select to authenticated using (private.is_member(group_id));
create policy tontine_contributions_select on public.tontine_contributions
  for select to authenticated using (private.is_member(group_id));
create policy tontine_declarations_select on public.tontine_declarations
  for select to authenticated using (private.is_member(group_id));
create policy tontine_turn_changes_select on public.tontine_turn_changes
  for select to authenticated using (private.is_member(group_id));

-- Réglages : modifiables par le bureau tant que la tontine est active.
grant update (amount_per_name, names_count, first_due_date, periodicity, penalty_rule,
  penalty_value, grace_days, shares_mode, status, updated_at)
  on public.tontine_settings to authenticated;
create policy tontine_settings_update on public.tontine_settings
  for update to authenticated
  using (private.is_manager(group_id)) with check (private.is_manager(group_id));

-- Tours : générés, avancés et remis par le bureau.
grant insert, update, delete on public.tontine_turns to authenticated;
create policy tontine_turns_insert on public.tontine_turns
  for insert to authenticated with check (private.is_manager(group_id));
create policy tontine_turns_update on public.tontine_turns
  for update to authenticated
  using (private.is_manager(group_id)) with check (private.is_manager(group_id));
create policy tontine_turns_delete on public.tontine_turns
  for delete to authenticated using (private.is_manager(group_id));

-- Cotisations officielles : saisies par le bureau ; jamais supprimées.
grant insert on public.tontine_contributions to authenticated;
create policy tontine_contributions_insert on public.tontine_contributions
  for insert to authenticated
  with check (private.is_manager(group_id) and author_id = auth.uid());

-- Déclarations : déposées par un membre pour un nom qu'il détient, sur le
-- tour en cours, toujours « en attente ». Traitées par le bureau.
grant insert on public.tontine_declarations to authenticated;
grant update (status, dispute_reason, updated_at) on public.tontine_declarations to authenticated;
create policy tontine_declarations_insert on public.tontine_declarations
  for insert to authenticated
  with check (
    status = 'enAttente'
    and dispute_reason is null
    and created_by = auth.uid()
    and member_id = private.my_member_id(group_id)
    and exists (
      select 1 from public.tontine_name_shares s
      where s.name_id = tontine_declarations.name_id and s.member_id = tontine_declarations.member_id
    )
    and exists (
      select 1 from public.tontine_turns t
      where t.id = tontine_declarations.turn_id
        and t.group_id = tontine_declarations.group_id
        and t.status = 'enCours'
    )
  );
create policy tontine_declarations_update on public.tontine_declarations
  for update to authenticated
  using (private.is_manager(group_id)) with check (private.is_manager(group_id));

-- Preuves : jointes par tout membre, immuables ensuite.
grant insert on public.tontine_proofs to authenticated;
create policy tontine_proofs_insert on public.tontine_proofs
  for insert to authenticated
  with check (private.is_member(group_id) and created_by = auth.uid());

-- Historique des réorganisations : écrit par `reorder_turns` uniquement.

-- Noms et parts : écrits par `save_tontine_name` uniquement (atomique,
-- somme des fractions contrôlée).

-- ---------------------------------------------------------------------------
-- Stockage des preuves (bucket privé)
-- ---------------------------------------------------------------------------

insert into storage.buckets (id, name, public)
values ('proofs', 'proofs', false)
on conflict (id) do nothing;

create policy proofs_objects_select on storage.objects
  for select to authenticated
  using (bucket_id = 'proofs' and private.is_member(((storage.foldername(name))[1])::uuid));

create policy proofs_objects_insert on storage.objects
  for insert to authenticated
  with check (bucket_id = 'proofs' and private.is_member(((storage.foldername(name))[1])::uuid));

-- ---------------------------------------------------------------------------
-- Fonctions métier (RPC)
-- ---------------------------------------------------------------------------

-- Crée une tontine : le groupe, la fiche de l'administratrice (owner +
-- treasurer, rattachée au compte courant) et ses réglages.
create or replace function public.create_tontine(
  p_name text,
  p_admin_full_name text,
  p_settings jsonb
) returns uuid
language plpgsql security definer set search_path = '' as $$
declare
  v_uid uuid := private.require_user();
  v_group_id uuid;
begin
  insert into public.groups (kind, name, created_by)
  values ('tontine', btrim(p_name), v_uid)
  returning id into v_group_id;

  insert into public.group_members (group_id, user_id, full_name, roles, joined_at)
  values (
    v_group_id, v_uid, btrim(p_admin_full_name),
    array['owner', 'treasurer']::public.member_role[], now()
  );

  insert into public.tontine_settings (
    group_id, amount_per_name, names_count, first_due_date, periodicity,
    penalty_rule, penalty_value, grace_days, shares_mode
  ) values (
    v_group_id,
    (p_settings ->> 'amount_per_name')::bigint,
    (p_settings ->> 'names_count')::integer,
    (p_settings ->> 'first_due_date')::date,
    p_settings -> 'periodicity',
    p_settings ->> 'penalty_rule',
    (p_settings ->> 'penalty_value')::bigint,
    (p_settings ->> 'grace_days')::integer,
    p_settings ->> 'shares_mode'
  );

  insert into public.profiles (id) values (v_uid) on conflict (id) do nothing;
  return v_group_id;
end;
$$;

-- Crée ou remplace un nom et ses parts, d'un bloc. `p_name_id` peut être
-- généré par l'application : inconnu, il désigne un nouveau nom (soumis au
-- nombre de noms prévu) ; il ne peut jamais désigner le nom d'un autre
-- groupe. `p_shares` : `[{"member_id": "...", "fraction": 0.5}, ...]`,
-- somme = 1, membres du groupe.
create or replace function public.save_tontine_name(
  p_group_id uuid,
  p_name_id uuid,
  p_position integer,
  p_label text,
  p_shares jsonb
) returns uuid
language plpgsql security definer set search_path = '' as $$
declare
  v_name_id uuid := coalesce(p_name_id, gen_random_uuid());
  v_existing_group uuid;
  v_total numeric;
  v_names_count integer;
begin
  perform private.require_manager(p_group_id);

  if jsonb_typeof(p_shares) <> 'array' or jsonb_array_length(p_shares) = 0 then
    raise exception 'shares_required' using errcode = '22023';
  end if;
  select coalesce(sum((s ->> 'fraction')::numeric), 0) into v_total
  from jsonb_array_elements(p_shares) s;
  if abs(v_total - 1) > 0.000001 then
    raise exception 'shares_must_total_one' using errcode = '22023';
  end if;

  select group_id into v_existing_group from public.tontine_names where id = v_name_id for update;
  if v_existing_group is not null and v_existing_group <> p_group_id then
    raise exception 'forbidden' using errcode = '42501';
  end if;

  if v_existing_group is null then
    select names_count into v_names_count from public.tontine_settings where group_id = p_group_id;
    if (select count(*) from public.tontine_names where group_id = p_group_id) >= v_names_count then
      raise exception 'names_quota_exceeded' using errcode = '23514';
    end if;
    insert into public.tontine_names (id, group_id, position, label)
    values (v_name_id, p_group_id, p_position, btrim(p_label));
  else
    update public.tontine_names set position = p_position, label = btrim(p_label)
    where id = v_name_id;
  end if;

  delete from public.tontine_name_shares where name_id = v_name_id;
  insert into public.tontine_name_shares (name_id, member_id, group_id, fraction)
  select v_name_id, (s ->> 'member_id')::uuid, p_group_id, (s ->> 'fraction')::numeric
  from jsonb_array_elements(p_shares) s;

  return v_name_id;
end;
$$;

-- Valide une déclaration d'un bloc : enregistre la cotisation officielle
-- correspondante (montants calculés par l'application, contrôlés ici) et
-- passe la déclaration en « validée ».
create or replace function public.validate_declaration(
  p_declaration_id uuid,
  p_amount_due bigint,
  p_penalty bigint default 0
) returns uuid
language plpgsql security definer set search_path = '' as $$
declare
  v_uid uuid;
  v_declaration public.tontine_declarations;
  v_contribution_id uuid;
begin
  select * into v_declaration from public.tontine_declarations
  where id = p_declaration_id for update;
  if not found then
    raise exception 'declaration_not_found' using errcode = 'P0002';
  end if;
  v_uid := private.require_manager(v_declaration.group_id);

  if v_declaration.status <> 'enAttente' then
    raise exception 'declaration_not_pending' using errcode = '55000';
  end if;
  if v_declaration.amount_declared > p_amount_due then
    raise exception 'amount_exceeds_due' using errcode = '22023';
  end if;

  insert into public.tontine_contributions (
    group_id, turn_id, name_id, member_id, amount_due, amount_paid, payment_date,
    origin, status, author_id, penalty, proof_id
  ) values (
    v_declaration.group_id, v_declaration.turn_id, v_declaration.name_id,
    v_declaration.member_id, p_amount_due, v_declaration.amount_declared,
    v_declaration.payment_date, 'membre', 'validee', v_uid, coalesce(p_penalty, 0),
    v_declaration.proof_id
  ) returning id into v_contribution_id;

  update public.tontine_declarations
  set status = 'validee', updated_at = now()
  where id = p_declaration_id;

  return v_contribution_id;
end;
$$;

-- Réorganise l'échéancier d'un bloc : nouvelles positions et dates
-- calculées par l'application, motif obligatoire, un changement historisé
-- par tour déplacé. Un tour déjà remis ne bouge jamais.
-- `p_turns` : `[{"id": "...", "position": 2, "planned_date": "2026-02-01"}, ...]`
-- `p_changes` : `[{"turn_id": "...", "old_position": 3, "new_position": 2}, ...]`
create or replace function public.reorder_turns(
  p_group_id uuid,
  p_reason text,
  p_turns jsonb,
  p_changes jsonb
) returns void
language plpgsql security definer set search_path = '' as $$
declare
  v_uid uuid := private.require_manager(p_group_id);
begin
  if nullif(btrim(p_reason), '') is null then
    raise exception 'reason_required' using errcode = '22023';
  end if;
  if jsonb_typeof(p_changes) <> 'array' or jsonb_array_length(p_changes) = 0 then
    raise exception 'changes_required' using errcode = '22023';
  end if;
  if exists (
    select 1
    from public.tontine_turns t
    join jsonb_array_elements(p_turns) s on t.id = (s ->> 'id')::uuid
    where t.group_id = p_group_id
      and t.status = 'remis'
      and (t.position <> (s ->> 'position')::integer or t.planned_date <> (s ->> 'planned_date')::date)
  ) then
    raise exception 'turn_already_paid' using errcode = '55000';
  end if;

  update public.tontine_turns t
  set position = (s ->> 'position')::integer,
      planned_date = (s ->> 'planned_date')::date
  from jsonb_array_elements(p_turns) s
  where t.id = (s ->> 'id')::uuid and t.group_id = p_group_id;

  insert into public.tontine_turn_changes (group_id, turn_id, old_position, new_position, reason, author_id)
  select p_group_id, (c ->> 'turn_id')::uuid, (c ->> 'old_position')::integer,
         (c ->> 'new_position')::integer, btrim(p_reason), v_uid
  from jsonb_array_elements(p_changes) c;
end;
$$;

revoke all on function public.create_tontine(text, text, jsonb) from public, anon;
revoke all on function public.save_tontine_name(uuid, uuid, integer, text, jsonb) from public, anon;
revoke all on function public.validate_declaration(uuid, bigint, bigint) from public, anon;
revoke all on function public.reorder_turns(uuid, text, jsonb, jsonb) from public, anon;
grant execute on function public.create_tontine(text, text, jsonb) to authenticated;
grant execute on function public.save_tontine_name(uuid, uuid, integer, text, jsonb) to authenticated;
grant execute on function public.validate_declaration(uuid, bigint, bigint) to authenticated;
grant execute on function public.reorder_turns(uuid, text, jsonb, jsonb) to authenticated;

-- Temps réel : les écrans suivent ces tables en direct.
alter publication supabase_realtime add table
  public.groups, public.group_members, public.tontine_settings, public.tontine_names,
  public.tontine_name_shares, public.tontine_turns, public.tontine_contributions,
  public.tontine_declarations, public.tontine_turn_changes;
