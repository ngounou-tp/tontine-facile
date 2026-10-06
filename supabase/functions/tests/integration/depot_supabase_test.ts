// Intégration : le dépôt de l'Edge Function contre une vraie API PostgREST
// et la base migrée. Lancé par `supabase/tests/run_api_local.sh`.
import { assertEquals, assertMatch } from 'jsr:@std/assert@1';
import { PostgrestClient } from 'npm:@supabase/postgrest-js@2';

import { depotSupabase } from '../../_shared/depot_supabase.ts';
import { type Message, traiterNouvelleInvitation } from '../../_shared/traitement.ts';

const url = Deno.env.get('POSTGREST_URL');
const secret = Deno.env.get('POSTGREST_JWT_SECRET');
const ignore = !url || !secret;

const ADELE = '11111111-1111-1111-1111-111111111111';
const BRUNO = '22222222-2222-2222-2222-222222222222';

function b64(octets: Uint8Array): string {
  return btoa(String.fromCharCode(...octets)).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
}

async function jwt(claims: Record<string, unknown>): Promise<string> {
  const encodeur = new TextEncoder();
  const entete = b64(encodeur.encode(JSON.stringify({ alg: 'HS256', typ: 'JWT' })));
  const contenu = b64(encodeur.encode(JSON.stringify({ ...claims, exp: Math.floor(Date.now() / 1000) + 3600 })));
  const cle = await crypto.subtle.importKey('raw', encodeur.encode(secret!), { name: 'HMAC', hash: 'SHA-256' }, false, ['sign']);
  const signature = new Uint8Array(await crypto.subtle.sign('HMAC', cle, encodeur.encode(`${entete}.${contenu}`)));
  return `${entete}.${contenu}.${b64(signature)}`;
}

async function client(claims: Record<string, unknown>) {
  return new PostgrestClient(url!, { headers: { Authorization: `Bearer ${await jwt(claims)}` } });
}

const silencieux = { info() {}, warn() {}, error() {} };

Deno.test({
  name: "e-mail d'invitation : envoyé une fois, suivi lisible par le bureau seul, dans la langue de l'inviteur",
  ignore,
  async fn() {
    const adele = await client({ sub: ADELE, role: 'authenticated' });
    const bruno = await client({ sub: BRUNO, role: 'authenticated' });
    const serveur = await client({ role: 'service_role' });

    const { data: groupId, error: e1 } = await adele.rpc('create_tontine', {
      p_name: 'Njangi des e-mails',
      p_admin_full_name: 'Adèle Tchoumi',
      p_settings: {
        amount_per_name: 25000, names_count: 3, first_due_date: '2026-11-01',
        periodicity: { type: 'tousLesNJours', jours: 7 }, penalty_rule: 'aucune',
        grace_days: 0, shares_mode: 'FIXED_AMOUNT',
      },
    });
    if (e1) throw e1;
    const { data: invites, error: e2 } = await adele.rpc('invite_member', {
      p_group_id: groupId, p_full_name: 'Dina Mbarga', p_email: 'dina@example.com',
    });
    if (e2) throw e2;
    const { code, member_id: memberId } = invites[0];

    // L'inviteur utilise l'application en anglais.
    const { error: e3 } = await serveur.from('profiles').update({ locale: 'en' }).eq('id', ADELE);
    if (e3) throw e3;

    const envoyes: Message[] = [];
    const envoyer = (message: Message) => {
      envoyes.push(message);
      return Promise.resolve('envoye' as const);
    };
    const depot = depotSupabase(serveur);
    assertEquals(await traiterNouvelleInvitation(depot, code, envoyer, { journal: silencieux }), 'envoye');
    assertEquals(await traiterNouvelleInvitation(depot, code, envoyer, { journal: silencieux }), 'ignore');

    assertEquals(envoyes.length, 1);
    assertEquals(envoyes[0].destinataire, 'dina@example.com');
    assertEquals(envoyes[0].sujet, 'Your code to join "Njangi des e-mails" on DjanguiBook');
    assertMatch(envoyes[0].texte, /Adèle Tchoumi has added you/);
    assertMatch(envoyes[0].texte, /25,000 FCFA/);

    const { data: suivi } = await adele.from('invitation_deliveries').select('status, email').eq('member_id', memberId);
    assertEquals(suivi, [{ status: 'envoye', email: 'dina@example.com' }]);

    const { data: vuParBruno } = await bruno.from('invitation_deliveries').select('*').eq('member_id', memberId);
    assertEquals(vuParBruno, []);

    const { error: falsification } = await adele.from('invitation_deliveries')
      .update({ status: 'echec' }).eq('member_id', memberId);
    assertEquals(falsification?.code, '42501');

    await serveur.from('profiles').update({ locale: null }).eq('id', ADELE);
  },
});
