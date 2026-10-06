// Test de bout en bout, exécuté uniquement contre la Local Emulator Suite
// (jamais un vrai projet) : `npm run test:emulateurs`.
//
// Crée des invitations comme le fait l'application, puis vérifie que la
// fonction `envoyerEmailInvitation` a consigné le bon statut pour chacune.
import assert from 'node:assert/strict';
import { initializeApp } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';

if (!process.env.FIRESTORE_EMULATOR_HOST) {
  console.error('FIRESTORE_EMULATOR_HOST absent : ce test ne tourne que sous les émulateurs.');
  process.exit(1);
}

initializeApp({ projectId: process.env.GCLOUD_PROJECT ?? 'demo-tontinefacile-functions' });
const db = getFirestore();

async function attendreStatut(chemin, attendu, delaiMs = 30000) {
  const debut = Date.now();
  while (Date.now() - debut < delaiMs) {
    const doc = await db.doc(chemin).get();
    if (doc.exists && doc.data().statut === attendu) return doc.data();
    await new Promise((resolve) => setTimeout(resolve, 500));
  }
  const doc = await db.doc(chemin).get();
  assert.fail(`${chemin} : statut attendu « ${attendu} », obtenu ${JSON.stringify(doc.data())}`);
}

// Scénario : une tontine, son administratrice (déjà inscrite) et deux
// nouveaux membres, l'un avec e-mail, l'autre avec WhatsApp seulement.
await db.doc('tontines/t1').set({
  nom: 'Cercle des amies',
  adminUid: 'uid-admin',
  codeInvitation: 'TONTIN',
  montantParNom: 25000,
});
await db.doc('tontines/t1/membres/m-admin').set({ nomComplet: 'Aïcha Ndiaye', uid: 'uid-admin', actif: true });
await db.doc('tontines/t1/membres/m-rose').set({ nomComplet: 'Rose Domche', email: 'rose@example.com', actif: true });
await db.doc('tontines/t1/membres/m-fatou').set({ nomComplet: 'Fatou Diallo', whatsapp: '+237600000000', actif: true });

await db.doc('invitations/TONTIN').set({ tontineId: 't1', membreId: 'm-admin', nomTontine: 'Cercle des amies', nombreMembres: 1 });
await db.doc('invitations/ABC234').set({ tontineId: 't1', membreId: 'm-rose', nomTontine: 'Cercle des amies', nombreMembres: 2 });
await db.doc('invitations/XYZ789').set({ tontineId: 't1', membreId: 'm-fatou', nomTontine: 'Cercle des amies', nombreMembres: 3 });

const rose = await attendreStatut('tontines/t1/envoisInvitation/m-rose', 'simule');
assert.equal(rose.code, 'ABC234');
assert.equal(rose.email, 'rose@example.com');
console.log('✔ membre avec e-mail : code envoyé (simulé sous émulateur)');

const fatou = await attendreStatut('tontines/t1/envoisInvitation/m-fatou', 'sans_email');
assert.equal(fatou.code, 'XYZ789');
console.log('✔ membre sans e-mail : signalé, rien envoyé');

// Laisse à la fonction le temps de traiter l'auto-invitation, puis vérifie
// qu'elle n'a rien écrit (l'administratrice ne reçoit pas son propre code).
await new Promise((resolve) => setTimeout(resolve, 3000));
assert.equal((await db.doc('tontines/t1/envoisInvitation/m-admin').get()).exists, false);
console.log("✔ auto-invitation de l'administratrice : ignorée");

console.log('Tous les scénarios de bout en bout sont passés.');
process.exit(0);
