import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, resolve } from 'node:path';
import { initializeTestEnvironment } from '@firebase/rules-unit-testing';

const __dirname = dirname(fileURLToPath(import.meta.url));
const rulesPath = resolve(__dirname, '../../firestore.rules');

const [host, portString] = (process.env.FIRESTORE_EMULATOR_HOST ?? '127.0.0.1:8081').split(':');
const port = Number(portString);

/** Un environnement de test par fichier de test, avec les règles actuelles. */
export function creerEnvironnement() {
  return initializeTestEnvironment({
    projectId: 'demo-tontinefacile-tests',
    firestore: {
      rules: readFileSync(rulesPath, 'utf8'),
      host,
      port,
    },
  });
}

/**
 * Scénario de base partagé par la plupart des tests : deux tontines
 * distinctes (t1, t2), chacune avec son administratrice et deux membres
 * détenant chacun un nom entier. Écrit hors règles (withSecurityRulesDisabled)
 * — ces documents sont des préalables, pas ce qu'on teste.
 */
export async function semerScenarioDeBase(testEnv) {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();

    // t1 : admin-uid, m1 (uid-m1, nom n1), m2 (uid-m2, nom n2)
    await db.doc('tontines/t1').set({ nom: 'Tontine 1', adminUid: 'admin-uid', nombreDeNoms: 2 });
    await db.doc('utilisateurs/admin-uid').set({ tontineId: 't1', membreId: 'admin-membre' });
    await db.doc('utilisateurs/uid-m1').set({ tontineId: 't1', membreId: 'm1' });
    await db.doc('utilisateurs/uid-m2').set({ tontineId: 't1', membreId: 'm2' });
    await db.doc('tontines/t1/membres/admin-membre').set({ nomComplet: 'Admin', actif: true, uid: 'admin-uid' });
    await db.doc('tontines/t1/membres/m1').set({ nomComplet: 'Membre Un', actif: true, uid: 'uid-m1' });
    await db.doc('tontines/t1/membres/m2').set({ nomComplet: 'Membre Deux', actif: true, uid: 'uid-m2' });
    await db.doc('tontines/t1/noms/n1').set({
      position: 1,
      libelle: 'Nom 1',
      parts: [{ membreId: 'm1', fraction: 1 }],
      membreIds: ['m1'],
    });
    await db.doc('tontines/t1/noms/n2').set({
      position: 2,
      libelle: 'Nom 2',
      parts: [{ membreId: 'm2', fraction: 1 }],
      membreIds: ['m2'],
    });
    await db.doc('tontines/t1/tours/tour1').set({
      nomId: 'n1',
      position: 1,
      datePrevue: new Date('2026-01-10'),
      statut: 'enCours',
    });

    // t2 : tontine étrangère, pour vérifier l'isolation entre tontines.
    await db.doc('tontines/t2').set({ nom: 'Tontine 2', adminUid: 'autre-admin-uid', nombreDeNoms: 1 });
    await db.doc('utilisateurs/autre-admin-uid').set({ tontineId: 't2', membreId: 'admin-membre-2' });
    await db.doc('tontines/t2/membres/admin-membre-2').set({
      nomComplet: 'Admin 2',
      actif: true,
      uid: 'autre-admin-uid',
    });
  });
}
