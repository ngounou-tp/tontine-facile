/**
 * Contenu de l'e-mail d'invitation envoyé à un nouveau membre : son code
 * personnel et la marche à suivre pour rejoindre son groupe dans
 * l'application. Fonction pure (aucun accès réseau ni base), testée
 * isolément.
 *
 * Reprise de la Cloud Function Firebase d'origine, désormais servie par une
 * Edge Function Supabase, en français ou en anglais selon la langue de la
 * personne qui invite.
 */

export type Langue = 'fr' | 'en';

export interface DonneesInvitation {
  /** Nom complet du membre invité, tel que saisi par le bureau. */
  nomMembre: string;
  nomTontine: string;
  /** Nom de la personne qui invite, si sa fiche est retrouvée. */
  nomAdministratrice?: string;
  code: string;
  /** Montant d'un nom, en FCFA. */
  montantParNom?: number;
  /** Lien de téléchargement de l'application (Play Store…), si publié. */
  lienApplication?: string;
  langue?: Langue;
}

export interface EmailInvitation {
  sujet: string;
  texte: string;
  html: string;
}

const APP = 'DjanguiBook';

// Couleurs de la charte (voir lib/app/theme.dart côté Flutter).
const encre = '#16255A';
const ardoise = '#4A4F5C';
const toile = '#EEF0F6';
const ambre = '#E2A03F';
const trait = '#D3D8E4';

/** `Rose Domche Ateba` → `Rose`. */
export function prenomDe(nomComplet: string): string {
  const prenom = nomComplet.trim().split(/\s+/)[0];
  return prenom && prenom.length > 0 ? prenom : nomComplet.trim();
}

/** `25000` → `25 000 FCFA` (espaces insécables) ou `25,000 FCFA` en anglais. */
export function formaterMontant(montant: number, langue: Langue = 'fr'): string {
  const separateur = langue === 'en' ? ',' : ' ';
  const chiffres = Math.round(Math.abs(montant)).toString();
  const groupes = chiffres.replace(/\B(?=(\d{3})+(?!\d))/g, separateur);
  return `${montant < 0 ? '-' : ''}${groupes} FCFA`;
}

/** Échappe le texte injecté dans le HTML (noms saisis librement). */
export function echapperHtml(valeur: string): string {
  return valeur
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;');
}

interface Textes {
  sujet: (d: DonneesInvitation) => string;
  bonjour: (prenom: string) => string;
  parQui: (d: DonneesInvitation) => string;
  dansLaTontine: (nom: string) => string;
  montant: (m: string) => string;
  code: string;
  ligneCode: (code: string) => string;
  pourRejoindre: string;
  etapes: (d: DonneesInvitation) => string[];
  personnel: string;
  pourquoi: string;
  signature: string;
  bandeau: string;
}

const TEXTES: Record<Langue, Textes> = {
  fr: {
    sujet: (d) => `Votre code pour rejoindre « ${d.nomTontine} » sur ${APP}`,
    bonjour: (prenom) => `Bonjour ${prenom},`,
    parQui: (d) => (d.nomAdministratrice ? `${d.nomAdministratrice} vous a inscrit(e)` : 'Vous avez été inscrit(e)'),
    dansLaTontine: (nom) => ` dans la tontine « ${nom} »`,
    montant: (m) => ` (montant d'un nom : ${m})`,
    code: "Votre code d'invitation",
    ligneCode: (code) => `Votre code d'invitation : ${code}`,
    pourRejoindre: 'Pour rejoindre votre groupe',
    etapes: (d) => [
      d.lienApplication
        ? `Installez l'application ${APP} : ${d.lienApplication}`
        : `Installez l'application ${APP} sur votre téléphone.`,
      'Ouvrez-la et créez votre compte, avec cette adresse e-mail ou votre compte Google. ' +
        "(Au tout premier lancement, vous pouvez aussi toucher directement « J'ai reçu un code d'invitation ».)",
      `Choisissez « Rejoindre une tontine », puis saisissez votre code : ${d.code}`,
      `Vérifiez que le groupe affiché est bien « ${d.nomTontine} », puis validez. ` +
        'Vous retrouvez vos noms, le calendrier des tours et vos cotisations.',
    ],
    personnel: 'Ce code est personnel : il vous relie à votre propre fiche dans le groupe. Ne le partagez pas.',
    pourquoi:
      'Vous recevez cet e-mail parce que le bureau de ce groupe a indiqué votre adresse. ' +
      'Si vous ne connaissez pas ce groupe, ignorez simplement ce message.',
    signature: `— L'équipe ${APP}`,
    bandeau: `INVITATION · ${APP.toUpperCase()}`,
  },
  en: {
    sujet: (d) => `Your code to join "${d.nomTontine}" on ${APP}`,
    bonjour: (prenom) => `Hello ${prenom},`,
    parQui: (d) => (d.nomAdministratrice ? `${d.nomAdministratrice} has added you` : 'You have been added'),
    dansLaTontine: (nom) => ` to the tontine "${nom}"`,
    montant: (m) => ` (amount per name: ${m})`,
    code: 'Your invitation code',
    ligneCode: (code) => `Your invitation code: ${code}`,
    pourRejoindre: 'To join your group',
    etapes: (d) => [
      d.lienApplication
        ? `Install the ${APP} app: ${d.lienApplication}`
        : `Install the ${APP} app on your phone.`,
      'Open it and create your account, with this email address or your Google account. ' +
        '(On the very first launch, you can also tap "I received an invitation code" directly.)',
      `Choose "Join a tontine", then enter your code: ${d.code}`,
      `Check that the group shown is "${d.nomTontine}", then confirm. ` +
        "You'll find your names, the turn calendar and your contributions.",
    ],
    personnel: "This code is personal: it links you to your own record in the group. Don't share it.",
    pourquoi:
      "You're receiving this email because this group's committee entered your address. " +
      "If you don't know this group, simply ignore this message.",
    signature: `— The ${APP} team`,
    bandeau: `INVITATION · ${APP.toUpperCase()}`,
  },
};

export function construireEmailInvitation(d: DonneesInvitation): EmailInvitation {
  const langue: Langue = d.langue ?? 'fr';
  const t = TEXTES[langue];
  const prenom = prenomDe(d.nomMembre);
  const parQui = t.parQui(d);
  const montant =
    d.montantParNom && d.montantParNom > 0 ? t.montant(formaterMontant(d.montantParNom, langue)) : '';
  const sujet = t.sujet(d);
  const liste = t.etapes(d);

  const texte = [
    t.bonjour(prenom),
    '',
    `${parQui}${t.dansLaTontine(d.nomTontine)}${montant} — ${APP}.`,
    '',
    t.ligneCode(d.code),
    '',
    langue === 'en' ? `${t.pourRejoindre}:` : `${t.pourRejoindre} :`,
    ...liste.map((etape, i) => `${i + 1}. ${etape}`),
    '',
    t.personnel,
    '',
    t.pourquoi,
    '',
    t.signature,
  ].join('\n');

  const e = echapperHtml;
  const caracteres = d.code
    .split('')
    .map(
      (c) =>
        `<td style="width:40px;height:52px;background:${toile};border-radius:8px;text-align:center;` +
        `font:600 26px/52px Arial,Helvetica,sans-serif;color:${encre};">${e(c)}</td><td style="width:6px"></td>`,
    )
    .join('');
  const etapesHtml = liste
    .map(
      (etape, i) =>
        `<tr><td valign="top" style="width:28px;padding:6px 0;"><div style="width:22px;height:22px;border-radius:11px;` +
        `background:${encre};color:#ffffff;font:600 12px/22px Arial,Helvetica,sans-serif;text-align:center;">${i + 1}</div></td>` +
        `<td style="padding:6px 0 6px 8px;font:400 15px/22px Arial,Helvetica,sans-serif;color:${encre};">${e(etape)}</td></tr>`,
    )
    .join('');

  const html = `<!doctype html>
<html lang="${langue}">
<head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>${e(sujet)}</title></head>
<body style="margin:0;padding:0;background:${toile};">
<table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background:${toile};padding:24px 12px;">
<tr><td align="center">
<table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="max-width:520px;background:#ffffff;border-radius:16px;border:1px solid ${trait};">
  <tr><td style="background:${encre};border-radius:16px 16px 0 0;padding:24px;">
    <div style="font:600 12px/16px Arial,Helvetica,sans-serif;letter-spacing:1px;color:${ambre};">${e(t.bandeau)}</div>
    <div style="font:600 22px/30px Arial,Helvetica,sans-serif;color:#ffffff;margin-top:8px;">${e(d.nomTontine)}</div>
  </td></tr>
  <tr><td style="padding:24px;">
    <p style="margin:0 0 12px;font:600 17px/24px Arial,Helvetica,sans-serif;color:${encre};">${e(t.bonjour(prenom))}</p>
    <p style="margin:0 0 20px;font:400 15px/22px Arial,Helvetica,sans-serif;color:${ardoise};">
      ${e(parQui)}<strong style="color:${encre};">${e(t.dansLaTontine(d.nomTontine))}</strong>${e(montant)}.
    </p>
    <div style="font:600 12px/16px Arial,Helvetica,sans-serif;letter-spacing:1px;color:${ardoise};margin-bottom:8px;">${e(t.code.toUpperCase())}</div>
    <table role="presentation" cellpadding="0" cellspacing="0" style="margin:0 0 24px;"><tr>${caracteres}</tr></table>
    <div style="font:600 16px/22px Arial,Helvetica,sans-serif;color:${encre};margin-bottom:4px;">${e(t.pourRejoindre)}</div>
    <table role="presentation" cellpadding="0" cellspacing="0" style="margin:0 0 20px;">${etapesHtml}</table>
    <div style="background:${toile};border-radius:12px;padding:12px 14px;font:400 13px/19px Arial,Helvetica,sans-serif;color:${ardoise};">
      🔒 ${e(t.personnel)}
    </div>
  </td></tr>
  <tr><td style="padding:0 24px 24px;font:400 12px/18px Arial,Helvetica,sans-serif;color:${ardoise};">
    ${e(t.pourquoi)}
  </td></tr>
</table>
</td></tr>
</table>
</body>
</html>`;

  return { sujet, texte, html };
}
