-- Suppression de compte : anonymisation, groupes solitaires supprimés,
-- jamais de groupe sans propriétaire.
begin;
select plan(10);

select tests.create_user('adele@example.com') as adele \gset
select tests.create_user('bruno@example.com') as bruno \gset
select tests.create_user('solo@example.com') as solo \gset

select tests.authenticate_as(:'adele');
select public.create_tontine('Tontine des Dames', 'Adèle Tchoumi',
  '{"amount_per_name": 25000, "names_count": 2, "first_due_date": "2026-11-01",
    "periodicity": {"type": "tousLesNJours", "jours": 7},
    "penalty_rule": "aucune", "grace_days": 0, "shares_mode": "FIXED_AMOUNT"}'::jsonb) as g1 \gset
select code as code_bruno, member_id as m_bruno
  from public.invite_member(:'g1', 'Bruno Ekotto', 'bruno@example.com', '+237690000001') \gset
select tests.authenticate_as(:'bruno');
select public.claim_invitation(:'code_bruno');

-- Solo : seul membre de son groupe.
select tests.authenticate_as(:'solo');
select public.create_tontine('Mon groupe', 'Solo',
  '{"amount_per_name": 1000, "names_count": 1, "first_due_date": "2026-11-01",
    "periodicity": {"type": "tousLesNJours", "jours": 7},
    "penalty_rule": "aucune", "grace_days": 0, "shares_mode": "FIXED_AMOUNT"}'::jsonb) as g_solo \gset

-- Le groupe de Solo a déjà de l'historique (nom, tour, cotisation).
select id as m_solo from public.group_members where group_id = :'g_solo' \gset
select public.save_tontine_name(:'g_solo', null, 1, 'Nom 1',
  format('[{"member_id": "%s", "fraction": 1}]', :'m_solo')::jsonb) as n_solo \gset
insert into public.tontine_turns (id, group_id, name_id, position, planned_date, status)
values ('00000000-0000-0000-0000-0000000000f1', :'g_solo', :'n_solo', 1, '2026-11-01', 'enCours');
insert into public.tontine_contributions (group_id, turn_id, name_id, member_id, amount_due, amount_paid,
  payment_date, origin, status, author_id)
values (:'g_solo', '00000000-0000-0000-0000-0000000000f1', :'n_solo', :'m_solo', 1000, 1000,
  '2026-11-01', 'administratrice', 'validee', :'solo');
select throws_ok(
  $$ delete from public.tontine_turns where id = '00000000-0000-0000-0000-0000000000f1' $$,
  '23503', null, 'un tour qui a des cotisations ne se supprime pas'
);

-- Seule propriétaire d'un groupe où Bruno a un compte : refus.
select tests.authenticate_as(:'adele');
select throws_ok('select public.delete_my_account()', '55000', 'transfer_ownership_required',
  'une propriétaire unique doit d''abord transmettre le groupe');

-- Un visiteur sans compte ne supprime rien.
select tests.authenticate_as_anon();
select throws_ok('select public.delete_my_account()', '42501', null, 'réservé aux comptes connectés');

-- Bruno supprime son compte : sa fiche reste, anonymisée.
select tests.authenticate_as(:'bruno');
select lives_ok('select public.delete_my_account()', 'un membre supprime son compte');
select tests.clear_authentication();
select is((select count(*)::integer from auth.users where id = :'bruno'), 0, 'le compte n''existe plus');
select is(
  (select row(user_id, email, whatsapp, full_name)::text from public.group_members where id = :'m_bruno'),
  row(null::uuid, null::text, null::text, 'Bruno Ekotto'::text)::text,
  'la fiche reste dans le groupe, sans compte ni coordonnées'
);

-- Adèle peut maintenant partir : plus personne d'autre n'a de compte.
select tests.authenticate_as(:'adele');
select lives_ok('select public.delete_my_account()', 'la propriétaire part quand plus personne n''a de compte');
select tests.clear_authentication();
select is((select count(*)::integer from public.groups where id = :'g1'), 0,
  'le groupe sans plus aucun compte disparaît avec elle');

-- Solo : son groupe disparaît avec son compte.
select tests.authenticate_as(:'solo');
select lives_ok('select public.delete_my_account()', 'le seul membre supprime son compte');
select tests.clear_authentication();
select is((select count(*)::integer from public.groups where id = :'g_solo'), 0,
  'son groupe solitaire est supprimé');

select * from finish();
rollback;
