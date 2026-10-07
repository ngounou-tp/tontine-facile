-- Suivi des e-mails d'invitation : lu par le bureau seul, écrit par le
-- serveur seul, un seul envoi par invitation.
begin;
select plan(13);

select tests.create_user('adele@example.com') as adele \gset
select tests.create_user('bruno@example.com') as bruno \gset
select tests.create_user('chantal@example.com') as chantal \gset

select tests.authenticate_as(:'adele');
select public.create_tontine('Tontine des Dames', 'Adèle Tchoumi',
  '{"amount_per_name": 25000, "names_count": 2, "first_due_date": "2026-11-01",
    "periodicity": {"type": "tousLesNJours", "jours": 7},
    "penalty_rule": "aucune", "grace_days": 0, "shares_mode": "FIXED_AMOUNT"}'::jsonb) as g1 \gset
select code as code_bruno, member_id as m_bruno
  from public.invite_member(:'g1', 'Bruno Ekotto', 'bruno@example.com') \gset
select code as code_dina, member_id as m_dina
  from public.invite_member(:'g1', 'Dina Mbarga', 'dina@example.com') \gset
select tests.authenticate_as(:'bruno');
select public.claim_invitation(:'code_bruno');

-- ------------------------------------------------- réservation (serveur)
select tests.clear_authentication();
select set_config('role', 'service_role', true);
select ok(public.reserve_invitation_delivery(:'m_dina', :'g1', :'code_dina', 'dina@example.com'),
  'la première livraison réserve l''envoi');
select ok(not public.reserve_invitation_delivery(:'m_dina', :'g1', :'code_dina', 'dina@example.com'),
  'une livraison en double pendant l''envoi est ignorée');

select tests.clear_authentication();
update public.invitation_deliveries set status = 'envoye', sent_at = now() where member_id = :'m_dina';
select set_config('role', 'service_role', true);
select ok(not public.reserve_invitation_delivery(:'m_dina', :'g1', :'code_dina', 'dina@example.com'),
  'un e-mail déjà envoyé ne repart pas');

select tests.clear_authentication();
update public.invitation_deliveries set status = 'echec', error = 'refusé' where member_id = :'m_dina';
select set_config('role', 'service_role', true);
select ok(public.reserve_invitation_delivery(:'m_dina', :'g1', :'code_dina', 'dina@example.com'),
  'après un échec, une nouvelle tentative est possible');

select tests.clear_authentication();
update public.invitation_deliveries set updated_at = now() - interval '10 minutes' where member_id = :'m_dina';
select set_config('role', 'service_role', true);
select ok(public.reserve_invitation_delivery(:'m_dina', :'g1', :'code_dina', 'dina@example.com'),
  'une réservation abandonnée depuis plus de 5 minutes est reprise');
select tests.clear_authentication();
select is((select error from public.invitation_deliveries where member_id = :'m_dina'), null,
  'la nouvelle tentative efface l''erreur précédente');

-- ------------------------------------------------------- lecture (client)
select tests.authenticate_as(:'adele');
select is((select status from public.invitation_deliveries where member_id = :'m_dina'), 'en_cours',
  'le bureau suit l''envoi de l''e-mail');

select tests.authenticate_as(:'bruno');
select is((select count(*)::integer from public.invitation_deliveries), 0,
  'un simple membre ne voit pas les envois (adresses des autres)');

select tests.authenticate_as(:'chantal');
select is((select count(*)::integer from public.invitation_deliveries), 0,
  'une étrangère au groupe ne voit rien');

-- ---------------------------------------------- écriture interdite (client)
select tests.authenticate_as(:'adele');
select throws_ok(
  format('update public.invitation_deliveries set status = %L where member_id = %L', 'envoye', :'m_dina'),
  '42501', null, 'le bureau ne peut pas falsifier un statut d''envoi'
);
select throws_ok(
  format('insert into public.invitation_deliveries (member_id, group_id, code, status) values (%L, %L, %L, %L)',
    :'m_bruno', :'g1', :'code_bruno', 'envoye'),
  '42501', null, 'ni en créer un'
);
select throws_ok(
  format('select public.reserve_invitation_delivery(%L, %L, %L, %L)', :'m_dina', :'g1', :'code_dina', 'x@y.z'),
  '42501', null, 'la réservation est réservée au serveur'
);

-- Un membre supprimé emporte son suivi.
select tests.clear_authentication();
delete from public.group_members where id = :'m_dina';
select is((select count(*)::integer from public.invitation_deliveries where member_id = :'m_dina'), 0,
  'le suivi disparaît avec la fiche');

select * from finish();
rollback;
