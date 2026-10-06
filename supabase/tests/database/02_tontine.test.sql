-- Tontine : noms et parts, tours, déclarations, validation, réorganisation,
-- preuves (stockage) et isolation entre groupes.
begin;
select plan(40);

select tests.create_user('adele@example.com') as adele \gset
select tests.create_user('bruno@example.com') as bruno \gset
select tests.create_user('chantal@example.com') as chantal \gset

-- Groupe 1 : Adèle (bureau), Bruno (membre), Dina (sans application).
select tests.authenticate_as(:'adele');
select public.create_tontine(
  'Tontine des Dames', 'Adèle Tchoumi',
  '{"amount_per_name": 25000, "names_count": 3, "first_due_date": "2026-11-01",
    "periodicity": {"type": "tousLesNJours", "jours": 7},
    "penalty_rule": "aucune", "grace_days": 0, "shares_mode": "FIXED_AMOUNT"}'::jsonb
) as g1 \gset
select id as m_adele from public.group_members where group_id = :'g1' and user_id = :'adele' \gset
select code as code_bruno, member_id as m_bruno
  from public.invite_member(:'g1', 'Bruno Ekotto', 'bruno@example.com') \gset
select member_id as m_dina from public.invite_member(:'g1', 'Dina Mbarga', null, '+237690000002') \gset
select tests.authenticate_as(:'bruno');
select public.claim_invitation(:'code_bruno');

-- Groupe 2 : celui de Chantal, pour l'isolation.
select tests.authenticate_as(:'chantal');
select public.create_tontine(
  'Njangi des Amis', 'Chantal Ngo',
  '{"amount_per_name": 10000, "names_count": 1, "first_due_date": "2026-11-01",
    "periodicity": {"type": "tousLesNJours", "jours": 30},
    "penalty_rule": "aucune", "grace_days": 0, "shares_mode": "FIXED_AMOUNT"}'::jsonb
) as g2 \gset
select id as m_chantal from public.group_members where group_id = :'g2' and user_id = :'chantal' \gset

-- ------------------------------------------------------------ noms et parts
select tests.authenticate_as(:'bruno');
select throws_ok(
  format($q$select public.save_tontine_name(%L, null, 1, 'Nom 1', '[{"member_id": "%s", "fraction": 1}]')$q$,
    :'g1', :'m_bruno'),
  '42501', 'forbidden', 'un simple membre ne crée pas de nom'
);

select tests.authenticate_as(:'adele');
select public.save_tontine_name(:'g1', null, 1, 'Nom 1',
  format('[{"member_id": "%s", "fraction": 1}]', :'m_bruno')::jsonb) as n1 \gset
select is(
  (select fraction from public.tontine_name_shares where name_id = :'n1'), 1::numeric,
  'le bureau crée un nom et sa part'
);
select throws_ok(
  format($q$select public.save_tontine_name(%L, null, 2, 'Nom 2', '[{"member_id": "%s", "fraction": 0.5}, {"member_id": "%s", "fraction": 0.4}]')$q$,
    :'g1', :'m_adele', :'m_dina'),
  '22023', 'shares_must_total_one', 'la somme des parts doit faire 1'
);
select throws_ok(
  format($q$select public.save_tontine_name(%L, null, 2, 'Nom 2', '[{"member_id": "%s", "fraction": 1}]')$q$,
    :'g1', :'m_chantal'),
  '23503', null, 'une part ne peut pas désigner le membre d''un autre groupe'
);
select public.save_tontine_name(:'g1', null, 2, 'Nom 2',
  format('[{"member_id": "%s", "fraction": 0.5}, {"member_id": "%s", "fraction": 0.5}]', :'m_adele', :'m_dina')::jsonb
) as n2 \gset
select is((select count(*)::integer from public.tontine_name_shares where name_id = :'n2'), 2,
  'un nom peut être partagé en demies');
select public.save_tontine_name(:'g1', null, 3, 'Nom 3',
  format('[{"member_id": "%s", "fraction": 1}]', :'m_adele')::jsonb) as n3 \gset
select throws_ok(
  format($q$select public.save_tontine_name(%L, null, 4, 'Nom 4', '[{"member_id": "%s", "fraction": 1}]')$q$,
    :'g1', :'m_adele'),
  '23514', 'names_quota_exceeded', 'pas plus de noms que prévu'
);
select lives_ok(
  format($q$select public.save_tontine_name(%L, %L, 3, 'Nom 3', '[{"member_id": "%s", "fraction": 1}]')$q$,
    :'g1', :'n3', :'m_dina'),
  'modifier un nom existant reste possible une fois le quota atteint'
);
select is((select member_id from public.tontine_name_shares where name_id = :'n3'), :'m_dina'::uuid,
  'les parts sont remplacées d''un bloc');
select throws_ok(
  format('insert into public.tontine_names (group_id, position, label) values (%L, 9, %L)', :'g1', 'X'),
  '42501', null, 'les noms ne s''écrivent pas directement (RPC uniquement)'
);

-- ------------------------------------------------------------------- tours
select tests.authenticate_as(:'bruno');
select throws_ok(
  format($q$insert into public.tontine_turns (group_id, name_id, position, planned_date, status)
            values (%L, %L, 1, '2026-11-01', 'enCours')$q$, :'g1', :'n1'),
  '42501', null, 'un membre ne génère pas l''échéancier'
);
select tests.authenticate_as(:'adele');
insert into public.tontine_turns (group_id, name_id, position, planned_date, status) values
  (:'g1', :'n1', 1, '2026-11-01', 'enCours'),
  (:'g1', :'n2', 2, '2026-11-08', 'aVenir'),
  (:'g1', :'n3', 3, '2026-11-15', 'aVenir');
select id as t1 from public.tontine_turns where group_id = :'g1' and position = 1 \gset
select id as t2 from public.tontine_turns where group_id = :'g1' and position = 2 \gset
select id as t3 from public.tontine_turns where group_id = :'g1' and position = 3 \gset
select is((select count(*)::integer from public.tontine_turns where group_id = :'g1'), 3,
  'le bureau génère l''échéancier');

-- ----------------------------------------------------------------- preuves
select tests.authenticate_as(:'bruno');
insert into public.tontine_proofs (id, group_id, storage_path, size_bytes)
values ('00000000-0000-0000-0000-0000000000a1', :'g1', :'g1' || '/a1.jpg', 90000);
select is((select created_by from public.tontine_proofs where id = '00000000-0000-0000-0000-0000000000a1'),
  :'bruno'::uuid, 'un membre joint une preuve, à son nom');
select throws_ok(
  format('insert into public.tontine_proofs (group_id, storage_path, size_bytes) values (%L, %L, 200000)',
    :'g1', :'g1' || '/big.jpg'),
  '23514', null, 'une preuve trop lourde est refusée'
);
select throws_ok(
  format('insert into public.tontine_proofs (group_id, storage_path, size_bytes) values (%L, %L, 1000)',
    :'g1', :'g2' || '/x.jpg'),
  '23514', null, 'le chemin de stockage doit être dans le dossier du groupe'
);
select throws_ok(
  format('update public.tontine_proofs set size_bytes = 1 where id = %L', '00000000-0000-0000-0000-0000000000a1'),
  '42501', null, 'une preuve est immuable'
);

-- Stockage : dossier du groupe réservé à ses membres.
insert into storage.objects (bucket_id, name, owner) values ('proofs', :'g1' || '/a1.jpg', :'bruno');
select tests.authenticate_as(:'chantal');
select is((select count(*)::integer from storage.objects where name = :'g1' || '/a1.jpg'), 0,
  'une étrangère ne voit pas les preuves du groupe');
select throws_ok(
  format('insert into storage.objects (bucket_id, name) values (%L, %L)', 'proofs', :'g1' || '/intrus.jpg'),
  '42501', null, 'une étrangère ne dépose rien dans le dossier du groupe'
);

-- ------------------------------------------------------------- déclarations
select tests.authenticate_as(:'bruno');
insert into public.tontine_declarations (id, group_id, turn_id, name_id, member_id, amount_declared, payment_date, proof_id)
values ('00000000-0000-0000-0000-0000000000d1', :'g1', :'t1', :'n1', :'m_bruno', 25000, '2026-11-01',
        '00000000-0000-0000-0000-0000000000a1');
select is((select status from public.tontine_declarations where id = '00000000-0000-0000-0000-0000000000d1'),
  'enAttente', 'Bruno déclare un paiement pour son nom');

select throws_ok(
  format($q$insert into public.tontine_declarations (group_id, turn_id, name_id, member_id, amount_declared, payment_date, proof_id)
            values (%L, %L, %L, %L, 25000, '2026-11-01', '00000000-0000-0000-0000-0000000000a1')$q$,
    :'g1', :'t1', :'n3', :'m_bruno'),
  '42501', null, 'pas de déclaration pour un nom qu''on ne détient pas'
);
select throws_ok(
  format($q$insert into public.tontine_declarations (group_id, turn_id, name_id, member_id, amount_declared, payment_date, proof_id)
            values (%L, %L, %L, %L, 12500, '2026-11-01', '00000000-0000-0000-0000-0000000000a1')$q$,
    :'g1', :'t1', :'n2', :'m_dina'),
  '42501', null, 'pas de déclaration au nom d''un autre membre (usurpation)'
);
select throws_ok(
  format($q$insert into public.tontine_declarations (group_id, turn_id, name_id, member_id, amount_declared, payment_date, proof_id, status)
            values (%L, %L, %L, %L, 25000, '2026-11-01', '00000000-0000-0000-0000-0000000000a1', 'validee')$q$,
    :'g1', :'t1', :'n1', :'m_bruno'),
  '42501', null, 'une déclaration naît toujours « en attente »'
);
select throws_ok(
  format($q$insert into public.tontine_declarations (group_id, turn_id, name_id, member_id, amount_declared, payment_date, proof_id)
            values (%L, %L, %L, %L, 25000, '2026-11-01', '00000000-0000-0000-0000-0000000000a1')$q$,
    :'g1', :'t2', :'n1', :'m_bruno'),
  '42501', null, 'seul le tour en cours peut être déclaré'
);

update public.tontine_declarations set status = 'validee' where id = '00000000-0000-0000-0000-0000000000d1';
select is((select status from public.tontine_declarations where id = '00000000-0000-0000-0000-0000000000d1'),
  'enAttente', 'un membre ne valide pas sa propre déclaration');
select throws_ok(
  $$ select public.validate_declaration('00000000-0000-0000-0000-0000000000d1', 25000) $$,
  '42501', 'forbidden', 'la validation est réservée au bureau'
);
select throws_ok(
  format($q$insert into public.tontine_contributions (group_id, turn_id, name_id, member_id, amount_due, amount_paid, payment_date, origin, status, author_id)
            values (%L, %L, %L, %L, 25000, 25000, '2026-11-01', 'membre', 'validee', %L)$q$,
    :'g1', :'t1', :'n1', :'m_bruno', :'bruno'),
  '42501', null, 'un membre n''enregistre pas de cotisation officielle'
);

-- --------------------------------------------------------------- validation
select tests.authenticate_as(:'adele');
select throws_ok(
  $$ select public.validate_declaration('00000000-0000-0000-0000-0000000000d1', 20000) $$,
  '22023', 'amount_exceeds_due', 'le montant déclaré ne peut pas dépasser le dû'
);
select public.validate_declaration('00000000-0000-0000-0000-0000000000d1', 25000) as c1 \gset
select is(
  (select row(amount_paid, status, origin, author_id)::text from public.tontine_contributions where id = :'c1'),
  row(25000::bigint, 'validee'::text, 'membre'::text, :'adele'::uuid)::text,
  'la validation crée la cotisation officielle correspondante'
);
select is((select status from public.tontine_declarations where id = '00000000-0000-0000-0000-0000000000d1'),
  'validee', 'et passe la déclaration en « validée », d''un bloc');
select throws_ok(
  $$ select public.validate_declaration('00000000-0000-0000-0000-0000000000d1', 25000) $$,
  '55000', 'declaration_not_pending', 'une déclaration ne se valide qu''une fois'
);
select throws_ok(
  format('delete from public.tontine_contributions where id = %L', :'c1'),
  '42501', null, 'une cotisation enregistrée ne se supprime pas'
);

-- Contestation : motif obligatoire.
select tests.authenticate_as(:'bruno');
insert into public.tontine_declarations (id, group_id, turn_id, name_id, member_id, amount_declared, payment_date, proof_id)
values ('00000000-0000-0000-0000-0000000000d2', :'g1', :'t1', :'n1', :'m_bruno', 5000, '2026-11-02',
        '00000000-0000-0000-0000-0000000000a1');
select tests.authenticate_as(:'adele');
select throws_ok(
  $$ update public.tontine_declarations set status = 'contestee' where id = '00000000-0000-0000-0000-0000000000d2' $$,
  '23514', null, 'contester exige un motif'
);
select lives_ok(
  $$ update public.tontine_declarations set status = 'contestee', dispute_reason = 'Preuve illisible',
       updated_at = now() where id = '00000000-0000-0000-0000-0000000000d2' $$,
  'le bureau conteste avec un motif'
);

-- ------------------------------------------------------------ réorganisation
select tests.authenticate_as(:'bruno');
select throws_ok(
  format($q$select public.reorder_turn(%L, %L, 3, 2, 'Absence', '[]')$q$, :'g1', :'t3'),
  '42501', 'forbidden', 'un membre ne réorganise pas l''échéancier'
);
select throws_ok(
  format('insert into public.tontine_turn_changes (group_id, turn_id, old_position, new_position, reason) values (%L, %L, 3, 2, %L)',
    :'g1', :'t3', 'x'),
  '42501', null, 'l''historique ne s''écrit pas directement'
);
select tests.authenticate_as(:'adele');
select throws_ok(
  format($q$select public.reorder_turn(%L, %L, 3, 2, '  ', '[]')$q$, :'g1', :'t3'),
  '22023', 'reason_required', 'un motif est obligatoire'
);
select lives_ok(
  format($q$select public.reorder_turn(%L, %L, 3, 2, 'Demande du membre',
    '[{"id": "%s", "position": 2, "planned_date": "2026-11-08"}, {"id": "%s", "position": 3, "planned_date": "2026-11-15"}]')$q$,
    :'g1', :'t3', :'t3', :'t2'),
  'le bureau échange deux tours (positions uniques vérifiées en fin de transaction)'
);
select is(
  (select array_agg(position order by position) from public.tontine_turns where id in (:'t2', :'t3')),
  array[2, 3], 'les positions restent uniques'
);
select is((select position from public.tontine_turns where id = :'t3'), 2, 'le tour déplacé a sa nouvelle place');
select is((select reason from public.tontine_turn_changes where turn_id = :'t3'), 'Demande du membre',
  'le changement est historisé avec son motif');

-- ----------------------------------------------------------------- isolation
select tests.authenticate_as(:'chantal');
select is(
  (select count(*)::integer from public.tontine_turns where group_id = :'g1')
  + (select count(*)::integer from public.tontine_declarations where group_id = :'g1')
  + (select count(*)::integer from public.tontine_contributions where group_id = :'g1')
  + (select count(*)::integer from public.tontine_name_shares where group_id = :'g1'),
  0, 'rien du groupe 1 n''est visible depuis le groupe 2'
);

select tests.clear_authentication();
select * from finish();
rollback;
