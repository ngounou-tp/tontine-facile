// Repris des tests Node de la Cloud Function d'origine (functions/test/).
import { assert, assertEquals, assertMatch, assertNotMatch } from 'jsr:@std/assert@1';

import {
  construireEmailInvitation,
  echapperHtml,
  formaterMontant,
  prenomDe,
} from '../_shared/email_invitation.ts';

const base = {
  nomMembre: 'Rose Domche Ateba',
  nomTontine: 'Cercle des amies',
  nomAdministratrice: 'Aïcha Ndiaye',
  code: 'ABC234',
  montantParNom: 25000,
};

Deno.test('donne le code et la procédure complète pour rejoindre le groupe', () => {
  const email = construireEmailInvitation(base);

  assertEquals(email.sujet, 'Votre code pour rejoindre « Cercle des amies » sur DjanguiBook');
  assertMatch(email.texte, /^Bonjour Rose,/);
  assertMatch(email.texte, /Aïcha Ndiaye vous a inscrit\(e\) dans la tontine « Cercle des amies »/);
  assertMatch(email.texte, /Votre code d'invitation : ABC234/);
  assertMatch(email.texte, /1\. Installez l'application DjanguiBook/);
  assertMatch(email.texte, /3\. Choisissez « Rejoindre une tontine », puis saisissez votre code : ABC234/);
  assertMatch(email.texte, /25 000 FCFA/);
  for (const caractere of 'ABC234') assert(email.html.includes(`>${caractere}</td>`));
});

Deno.test('en anglais quand la personne qui invite utilise l’anglais', () => {
  const email = construireEmailInvitation({ ...base, langue: 'en' });

  assertEquals(email.sujet, 'Your code to join "Cercle des amies" on DjanguiBook');
  assertMatch(email.texte, /^Hello Rose,/);
  assertMatch(email.texte, /Your invitation code: ABC234/);
  assertMatch(email.texte, /25,000 FCFA/);
  assertMatch(email.html, /<html lang="en">/);
});

Deno.test('inclut le lien de téléchargement quand il est configuré', () => {
  const email = construireEmailInvitation({ ...base, lienApplication: 'https://play.google.com/store/apps/details?id=x' });
  assertMatch(email.texte, /Installez l'application DjanguiBook : https:\/\/play\.google\.com/);
});

Deno.test("reste correct sans nom de l'inviteur ni montant", () => {
  const email = construireEmailInvitation({ nomMembre: 'Fatou', nomTontine: 'Groupe', code: 'XYZ789' });
  assertMatch(email.texte, /Vous avez été inscrit\(e\) dans la tontine « Groupe »/);
  assertNotMatch(email.texte, /FCFA/);
});

Deno.test('neutralise le HTML injecté dans un nom saisi librement', () => {
  const email = construireEmailInvitation({ ...base, nomTontine: '<script>alert(1)</script>' });
  assert(!email.html.includes('<script>'));
  assert(email.html.includes('&lt;script&gt;'));
});

Deno.test('utilitaires', () => {
  assertEquals(prenomDe('  Rose Domche Ateba '), 'Rose');
  assertEquals(prenomDe('Fatou'), 'Fatou');
  assertEquals(formaterMontant(1250000), '1 250 000 FCFA');
  assertEquals(formaterMontant(500, 'en'), '500 FCFA');
  assertEquals(
    echapperHtml(`<a href="x">L'été & co</a>`),
    '&lt;a href=&quot;x&quot;&gt;L&#39;été &amp; co&lt;/a&gt;',
  );
});
