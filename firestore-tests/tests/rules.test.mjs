import { after, before, beforeEach, describe, it } from 'node:test';
import { assertFails, assertSucceeds } from '@firebase/rules-unit-testing';
import { creerEnvironnement, semerScenarioDeBase } from './helpers.mjs';

let testEnv;

before(async () => {
  testEnv = await creerEnvironnement();
});

after(async () => {
  await testEnv.cleanup();
});

beforeEach(async () => {
  await testEnv.clearFirestore();
  await semerScenarioDeBase(testEnv);
});

function commeM1() {
  return testEnv.authenticatedContext('uid-m1').firestore();
}

function commeM2() {
  return testEnv.authenticatedContext('uid-m2').firestore();
}

function commeAdmin() {
  return testEnv.authenticatedContext('admin-uid').firestore();
}

function commeAdmin2() {
  return testEnv.authenticatedContext('autre-admin-uid').firestore();
}

function sansCompte() {
  return testEnv.unauthenticatedContext().firestore();
}

describe('Cotisations — seule l’administratrice peut en créer', () => {
  it('un membre ne peut pas créer une cotisation officielle', async () => {
    await assertFails(
      commeM1().doc('tontines/t1/cotisations/c1').set({
        tourId: 'tour1',
        nomId: 'n1',
        membreId: 'm1',
        montantDu: 25000,
        montantVerse: 25000,
        datePaiement: new Date('2026-01-10'),
        origine: 'membre',
        statut: 'validee',
        auteurUid: 'uid-m1',
        penalite: 0,
      }),
    );
  });

  it('l’administratrice de la tontine peut créer une cotisation officielle', async () => {
    await assertSucceeds(
      commeAdmin().doc('tontines/t1/cotisations/c1').set({
        tourId: 'tour1',
        nomId: 'n1',
        membreId: 'm1',
        montantDu: 25000,
        montantVerse: 25000,
        datePaiement: new Date('2026-01-10'),
        origine: 'administratrice',
        statut: 'validee',
        auteurUid: 'admin-uid',
        penalite: 0,
      }),
    );
  });
});

describe('Déclarations — dépôt réservé au détenteur du nom', () => {
  it('un membre peut déclarer un paiement pour un nom qu’il détient', async () => {
    await assertSucceeds(
      commeM1().doc('tontines/t1/declarations/d1').set({
        tourId: 'tour1',
        nomId: 'n1',
        membreId: 'm1',
        montantDeclare: 25000,
        datePaiement: new Date('2026-01-10'),
        preuveId: 'preuve1',
        statut: 'enAttente',
        createdAt: new Date('2026-01-10'),
      }),
    );
  });

  it('un membre ne peut pas déclarer un paiement pour un nom qu’il ne détient pas', async () => {
    // n2 appartient à m2, pas à m1.
    await assertFails(
      commeM1().doc('tontines/t1/declarations/d1').set({
        tourId: 'tour1',
        nomId: 'n2',
        membreId: 'm1',
        montantDeclare: 25000,
        datePaiement: new Date('2026-01-10'),
        preuveId: 'preuve1',
        statut: 'enAttente',
        createdAt: new Date('2026-01-10'),
      }),
    );
  });

  it('un membre ne peut pas déclarer un paiement au nom d’un autre membre', async () => {
    // membreId ne correspond pas au profil de l'appelant (m1 usurpe m2).
    await assertFails(
      commeM1().doc('tontines/t1/declarations/d1').set({
        tourId: 'tour1',
        nomId: 'n2',
        membreId: 'm2',
        montantDeclare: 25000,
        datePaiement: new Date('2026-01-10'),
        preuveId: 'preuve1',
        statut: 'enAttente',
        createdAt: new Date('2026-01-10'),
      }),
    );
  });
});

describe('Déclarations — traitement réservé à l’administratrice', () => {
  async function semerDeclarationEnAttente() {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await context.firestore().doc('tontines/t1/declarations/d1').set({
        tourId: 'tour1',
        nomId: 'n1',
        membreId: 'm1',
        montantDeclare: 25000,
        datePaiement: new Date('2026-01-10'),
        preuveId: 'preuve1',
        statut: 'enAttente',
        createdAt: new Date('2026-01-10'),
      });
    });
  }

  it('un membre ne peut pas valider sa propre déclaration', async () => {
    await semerDeclarationEnAttente();
    await assertFails(
      commeM1().doc('tontines/t1/declarations/d1').update({ statut: 'validee' }),
    );
  });

  it('un membre ne peut pas refuser sa propre déclaration', async () => {
    await semerDeclarationEnAttente();
    await assertFails(
      commeM1()
        .doc('tontines/t1/declarations/d1')
        .update({ statut: 'contestee', motifContestation: 'test' }),
    );
  });

  it('l’administratrice de la tontine peut valider une déclaration', async () => {
    await semerDeclarationEnAttente();
    await assertSucceeds(
      commeAdmin().doc('tontines/t1/declarations/d1').update({ statut: 'validee' }),
    );
  });

  it('un membre ne peut pas modifier une déclaration déjà traitée', async () => {
    await semerDeclarationEnAttente();
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await context.firestore().doc('tontines/t1/declarations/d1').update({ statut: 'validee' });
    });
    await assertFails(
      commeM1().doc('tontines/t1/declarations/d1').update({ montantDeclare: 1 }),
    );
  });

  it('personne ne peut supprimer une déclaration, pas même l’administratrice', async () => {
    await semerDeclarationEnAttente();
    await assertFails(commeAdmin().doc('tontines/t1/declarations/d1').delete());
  });
});

describe('Preuves — jointes par leur auteur, immuables ensuite', () => {
  it('un membre peut joindre sa propre preuve', async () => {
    await assertSucceeds(
      commeM1().doc('tontines/t1/preuves/p1').set({
        imageEncodee: 'ZmFrZQ==',
        tailleOctets: 4,
        createdAt: new Date('2026-01-10'),
      }),
    );
  });

  it('une preuve ne peut pas être modifiée après création', async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await context.firestore().doc('tontines/t1/preuves/p1').set({
        imageEncodee: 'ZmFrZQ==',
        tailleOctets: 4,
        createdAt: new Date('2026-01-10'),
      });
    });
    await assertFails(
      commeAdmin().doc('tontines/t1/preuves/p1').update({ tailleOctets: 5 }),
    );
  });
});

describe('Isolation entre tontines', () => {
  it('un membre ne peut pas lire une autre tontine que la sienne', async () => {
    await assertFails(commeM1().doc('tontines/t2').get());
  });

  it('l’administratrice d’une tontine ne peut pas lire les membres d’une autre', async () => {
    await assertFails(commeAdmin().collection('tontines/t2/membres').get());
  });

  it('l’administratrice d’une tontine ne peut pas modifier une autre tontine', async () => {
    await assertFails(commeAdmin().doc('tontines/t2').update({ nom: 'Piraté' }));
  });

  it('une administratrice reste libre de lire et gérer sa propre tontine', async () => {
    await assertSucceeds(commeAdmin2().doc('tontines/t2').get());
  });

  it('un utilisateur non connecté ne peut rien lire', async () => {
    await assertFails(sansCompte().doc('tontines/t1').get());
  });
});

describe('Membres — lecture par tout membre, écriture réservée', () => {
  it('m2 peut lire la fiche de m1 (même tontine)', async () => {
    await assertSucceeds(commeM2().doc('tontines/t1/membres/m1').get());
  });

  it('un membre ne peut pas modifier la fiche d’un autre membre', async () => {
    await assertFails(
      commeM1().doc('tontines/t1/membres/m2').update({ nomComplet: 'Piraté' }),
    );
  });
});
