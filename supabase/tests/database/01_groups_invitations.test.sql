-- Groupes, rôles et invitations : création, adhésion, isolation, et
-- impossibilité de s'attribuer l'identité d'un autre membre.
begin;
select plan(28);

-- Comptes : Adèle (créatrice), Bruno (invité), Chantal (étrangère).
select tests.create_user('adele@example.com') as adele \gset
select tests.create_user('bruno@example.com') as bruno \gset
select tests.create_user('chantal@example.com') as chantal \gset

select is(
  (select count(*)::integer from public.profiles where id in (:'adele', :'bruno', :'chantal')),
  3, 'un profil est créé pour chaque nouveau compte'
);

-- Toutes les tables exposées ont la RLS activée.
select is(
  (select count(*)::integer from pg_tables
   where schemaname = 'public' and not rowsecurity),
  0, 'aucune table publique sans RLS'
);

-- ---------------------------------------------------------------- création
select tests.authenticate_as(:'adele');
select public.create_tontine(
  'Tontine des Dames', 'Adèle Tchoumi',
  '{"amount_per_name": 25000, "names_count": 3, "first_due_date": "2026-11-01",
    "periodicity": {"type": "chaqueSemaine", "jourDeLaSemaine": 6},
    "penalty_rule": "forfaitaire", "penalty_value": 1000, "grace_days": 2,
    "shares_mode": "FIXED_AMOUNT"}'::jsonb
) as g1 \gset

select is((select kind::text from public.groups where id = :'g1'), 'tontine', 'la tontine est créée');
select is(
  (select roles from public.group_members where group_id = :'g1' and user_id = :'adele'),
  array['owner', 'treasurer']::public.member_role[],
  'la créatrice est propriétaire et trésorière'
);
select is((select amount_per_name from public.tontine_settings where group_id = :'g1'), 25000::bigint,
  'les réglages sont enregistrés');

select throws_ok(
  $$ select public.create_tontine('X', 'Adèle', '{"amount_per_name": 0, "names_count": 1,
     "first_due_date": "2026-11-01", "periodicity": {"type": "tousLesNJours", "jours": 7},
     "penalty_rule": "aucune", "grace_days": 0, "shares_mode": "FIXED_AMOUNT"}'::jsonb) $$,
  '23514', null, 'des réglages invalides sont refusés (nom trop court, montant nul)'
);

-- ---------------------------------------------------------------- invitation
select code as code_bruno, member_id as m_bruno
from public.invite_member(:'g1', 'Bruno Ekotto', null, '+237690000001') \gset

select ok(:'code_bruno' ~ '^[A-Z0-9]{6}$', 'le code d''invitation a 6 caractères');
select is(
  (select invitation_code from public.group_members where id = :'m_bruno'), :'code_bruno',
  'le code est consultable depuis la fiche membre'
);
select throws_ok(
  $$ select * from public.invite_member('$$ || :'g1' || $$', 'Sans Contact') $$,
  '22023', 'contact_required', 'un email ou un WhatsApp est exigé'
);

-- Un non-membre ne peut pas inviter dans le groupe.
select tests.authenticate_as(:'chantal');
select throws_ok(
  format('select * from public.invite_member(%L, %L, %L)', :'g1', 'Intrus', 'x@y.z'),
  '42501', 'forbidden', 'un non-membre ne peut pas inviter'
);

-- ---------------------------------------------------------------- isolation
select is((select count(*)::integer from public.groups where id = :'g1'), 0,
  'un non-membre ne voit pas le groupe');
select is((select count(*)::integer from public.group_members where group_id = :'g1'), 0,
  'un non-membre ne voit pas les membres');
select is((select count(*)::integer from public.tontine_settings where group_id = :'g1'), 0,
  'un non-membre ne voit pas les réglages');
select throws_ok(
  'select count(*) from public.group_invitations',
  '42501', null, 'les invitations ne sont jamais lisibles directement'
);

-- ---------------------------------------------------------------- aperçu
select tests.authenticate_as_anon();
select is(
  (select group_name from public.invitation_preview(lower(:'code_bruno'))),
  'Tontine des Dames', 'l''aperçu est accessible sans compte (code insensible à la casse)'
);
select is(
  (select member_count from public.invitation_preview(:'code_bruno')), 2,
  'l''aperçu donne le nombre de membres'
);
select is((select count(*)::integer from public.invitation_preview('ZZZZZZ')), 0,
  'un code inconnu ne renvoie rien');
select throws_ok(
  format('select * from public.claim_invitation(%L)', :'code_bruno'),
  '42501', null, 'un visiteur sans compte ne peut pas réclamer une invitation'
);

-- ---------------------------------------------------------------- adhésion
select tests.authenticate_as(:'bruno');
select throws_ok(
  $$ select * from public.claim_invitation('ZZZZZZ') $$,
  'P0002', 'invitation_not_found', 'code inconnu'
);
select is(
  (select member_id from public.claim_invitation(:'code_bruno')), :'m_bruno'::uuid,
  'Bruno réclame sa fiche'
);
select is((select count(*)::integer from public.groups where id = :'g1'), 1,
  'Bruno voit désormais le groupe');
select ok(
  (select roles = array['member']::public.member_role[] from public.group_members where id = :'m_bruno'),
  'Bruno est simple membre'
);

select tests.authenticate_as(:'chantal');
select throws_ok(
  format('select * from public.claim_invitation(%L)', :'code_bruno'),
  '23505', 'invitation_already_used', 'une invitation ne sert qu''une fois'
);

-- ---------------------------------------------------------------- usurpation
-- Bruno ne peut pas se rattacher à la fiche d'Adèle, ni se donner un rôle.
select tests.authenticate_as(:'bruno');
select throws_ok(
  format('update public.group_members set user_id = %L where group_id = %L and user_id = %L',
    :'bruno', :'g1', :'adele'),
  '42501', null, 'user_id n''est jamais modifiable par le client'
);
select throws_ok(
  format('update public.group_members set roles = %L where id = %L',
    '{owner}', :'m_bruno'),
  '42501', null, 'les rôles ne sont pas modifiables directement'
);
select throws_ok(
  format('select public.set_member_roles(%L, %L)', :'m_bruno', '{owner}'),
  '42501', 'forbidden', 'seul un propriétaire change les rôles'
);

-- Le propriétaire ne peut pas retirer le dernier propriétaire.
select tests.authenticate_as(:'adele');
select throws_ok(
  format('select public.set_member_roles((select id from public.group_members where group_id = %L and user_id = %L), %L)',
    :'g1', :'adele', '{treasurer}'),
  '23514', 'last_owner', 'le groupe garde toujours un propriétaire'
);
select lives_ok(
  format('select public.set_member_roles(%L, %L)', :'m_bruno', '{member,auditor}'),
  'le propriétaire peut nommer un commissaire'
);

select tests.clear_authentication();
select * from finish();
rollback;
