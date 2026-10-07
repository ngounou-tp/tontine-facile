import { assertEquals, assertMatch } from 'jsr:@std/assert@1';

import { type Depot, ErreurEnvoi, type Message, messageErreur, traiterNouvelleInvitation } from '../_shared/traitement.ts';

const silencieux = { info() {}, warn() {}, error() {} };

/** Base en mémoire qui reproduit `reserve_invitation_delivery`. */
function depotMemoire(membre: { email: string | null; userId?: string | null } = { email: 'dina@example.com' }) {
  const suivis = new Map<string, { code: string; statut: string; erreur?: string }>();
  const depot: Depot = {
    invitation: async (code) => (code === 'ABC234' ? { groupId: 'g1', memberId: 'm1', createdBy: 'uid-adele' } : null),
    groupe: async () => ({ nom: 'Cercle des amies', montantParNom: 25000 }),
    membre: async () => ({ nomComplet: 'Dina Mbarga', email: membre.email, userId: membre.userId ?? null }),
    inviteur: async () => ({ nom: 'Adèle Tchoumi', langue: 'fr' }),
    reserver: async ({ memberId, code }) => {
      const existant = suivis.get(memberId);
      if (existant && existant.code === code && ['envoye', 'simule', 'en_cours'].includes(existant.statut)) return false;
      suivis.set(memberId, { code, statut: 'en_cours' });
      return true;
    },
    consigner: async ({ memberId, code, statut, erreur }) => {
      suivis.set(memberId, { code, statut, erreur });
    },
  };
  return { depot, suivis };
}

Deno.test('envoie une seule fois, même si le webhook est livré deux fois', async () => {
  const { depot, suivis } = depotMemoire();
  const envoyes: Message[] = [];
  const envoyer = async (message: Message) => {
    envoyes.push(message);
    return 'envoye' as const;
  };

  assertEquals(await traiterNouvelleInvitation(depot, 'ABC234', envoyer, { journal: silencieux }), 'envoye');
  assertEquals(await traiterNouvelleInvitation(depot, 'ABC234', envoyer, { journal: silencieux }), 'ignore');

  assertEquals(envoyes.length, 1);
  assertEquals(envoyes[0].destinataire, 'dina@example.com');
  assertMatch(envoyes[0].texte, /Adèle Tchoumi vous a inscrit\(e\)/);
  assertEquals(suivis.get('m1')?.statut, 'envoye');
});

Deno.test('membre sans e-mail : consigné, rien n’est envoyé', async () => {
  const { depot, suivis } = depotMemoire({ email: '  ' });
  const resultat = await traiterNouvelleInvitation(depot, 'ABC234', () => {
    throw new Error('ne doit pas être appelé');
  }, { journal: silencieux });

  assertEquals(resultat, 'sans_email');
  assertEquals(suivis.get('m1')?.statut, 'sans_email');
});

Deno.test('membre déjà inscrit ou code inconnu : ignoré', async () => {
  const inscrit = depotMemoire({ email: 'x@y.z', userId: 'uid-dina' });
  assertEquals(await traiterNouvelleInvitation(inscrit.depot, 'ABC234', async () => 'envoye', { journal: silencieux }), 'ignore');
  assertEquals(await traiterNouvelleInvitation(inscrit.depot, 'ZZZZZZ', async () => 'envoye', { journal: silencieux }), 'ignore');
});

Deno.test("échec d'envoi : consigné avec un message clair pour le bureau", async () => {
  const { depot, suivis } = depotMemoire();
  const resultat = await traiterNouvelleInvitation(depot, 'ABC234', () => Promise.reject({ responseCode: 550 }), {
    journal: silencieux,
  });

  assertEquals(resultat, 'echec');
  assertMatch(suivis.get('m1')?.erreur ?? '', /adresse e-mail a été refusée/);
});

Deno.test('messageErreur traduit les erreurs SMTP', () => {
  assertMatch(messageErreur({ responseCode: 550 }), /adresse e-mail a été refusée/);
  assertMatch(messageErreur(new Error('ETIMEDOUT')), /n'a pas répondu/);
  assertMatch(messageErreur(new Error('ETIMEDOUT'), 'en'), /didn't respond/);
  assertEquals(messageErreur(new ErreurEnvoi('Message clair')), 'Message clair');
});
