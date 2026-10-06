import { describe, it } from 'node:test';
import assert from 'node:assert/strict';

import {
  construireEmailInvitation,
  echapperHtml,
  formaterMontant,
  prenomDe,
} from '../lib/email_invitation.js';
import { messageErreur, ErreurEnvoi } from '../lib/traitement.js';

const base = {
  nomMembre: 'Rose Domche Ateba',
  nomTontine: 'Cercle des amies',
  nomAdministratrice: 'Aïcha Ndiaye',
  code: 'ABC234',
  montantParNom: 25000,
};

describe("E-mail d'invitation", () => {
  it('donne le code et la procédure complète pour rejoindre le groupe', () => {
    const email = construireEmailInvitation(base);

    assert.equal(email.sujet, 'Votre code pour rejoindre « Cercle des amies » sur TontineFacile');
    assert.match(email.texte, /^Bonjour Rose,/);
    assert.match(email.texte, /Aïcha Ndiaye vous a inscrit\(e\) dans la tontine « Cercle des amies »/);
    assert.match(email.texte, /Votre code d'invitation : ABC234/);
    assert.match(email.texte, /1\. Installez l'application TontineFacile/);
    assert.match(email.texte, /3\. Choisissez « Rejoindre une tontine », puis saisissez votre code : ABC234/);
    assert.match(email.texte, /25 000 FCFA/);
    // Le code apparaît caractère par caractère dans la version HTML.
    for (const caractere of 'ABC234') assert.ok(email.html.includes(`>${caractere}</td>`));
  });

  it('inclut le lien de téléchargement quand il est configuré', () => {
    const email = construireEmailInvitation({ ...base, lienApplication: 'https://play.google.com/store/apps/details?id=x' });
    assert.match(email.texte, /Installez l'application TontineFacile : https:\/\/play\.google\.com/);
  });

  it("reste correct sans nom d'administratrice ni montant", () => {
    const email = construireEmailInvitation({ nomMembre: 'Fatou', nomTontine: 'Groupe', code: 'XYZ789' });
    assert.match(email.texte, /Vous avez été inscrit\(e\) dans la tontine « Groupe » sur TontineFacile\./);
    assert.doesNotMatch(email.texte, /FCFA/);
  });

  it('neutralise le HTML injecté dans un nom saisi librement', () => {
    const email = construireEmailInvitation({ ...base, nomTontine: '<script>alert(1)</script>' });
    assert.ok(!email.html.includes('<script>'));
    assert.ok(email.html.includes('&lt;script&gt;'));
  });
});

describe('Utilitaires', () => {
  it('prenomDe', () => {
    assert.equal(prenomDe('  Rose Domche Ateba '), 'Rose');
    assert.equal(prenomDe('Fatou'), 'Fatou');
  });

  it('formaterMontant', () => {
    assert.equal(formaterMontant(25000), '25 000 FCFA');
    assert.equal(formaterMontant(500), '500 FCFA');
    assert.equal(formaterMontant(1250000), '1 250 000 FCFA');
  });

  it('echapperHtml', () => {
    assert.equal(echapperHtml(`<a href="x">L'été & co</a>`), '&lt;a href=&quot;x&quot;&gt;L&#39;été &amp; co&lt;/a&gt;');
  });

  it("messageErreur traduit les erreurs SMTP pour l'administratrice", () => {
    assert.match(messageErreur({ responseCode: 550 }), /adresse e-mail a été refusée/);
    assert.match(messageErreur(new Error('ETIMEDOUT')), /n'a pas répondu/);
    assert.equal(messageErreur(new ErreurEnvoi('Message clair')), 'Message clair');
  });
});
