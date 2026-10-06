/**
 * Contenu de l'e-mail d'invitation envoyé à un nouveau membre : son code
 * personnel et la marche à suivre pour rejoindre son groupe dans
 * l'application. Fonction pure (aucun accès Firebase ni réseau), testée
 * isolément.
 */

export interface DonneesInvitation {
  /** Nom complet du membre invité, tel que saisi par l'administratrice. */
  nomMembre: string;
  nomTontine: string;
  /** Nom de l'administratrice, si sa fiche membre est retrouvée. */
  nomAdministratrice?: string;
  code: string;
  /** Montant d'un nom, en FCFA. */
  montantParNom?: number;
  /** Lien de téléchargement de l'application (Play Store…), si publié. */
  lienApplication?: string;
}

export interface EmailInvitation {
  sujet: string;
  texte: string;
  html: string;
}

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

/** `25000` → `25 000 FCFA` (espaces insécables, usage français). */
export function formaterMontant(montant: number): string {
  const chiffres = Math.round(Math.abs(montant)).toString();
  const groupes = chiffres.replace(/\B(?=(\d{3})+(?!\d))/g, ' ');
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

function etapes(d: DonneesInvitation): string[] {
  return [
    d.lienApplication
      ? `Installez l'application TontineFacile : ${d.lienApplication}`
      : "Installez l'application TontineFacile sur votre téléphone.",
    "Ouvrez-la et créez votre compte, avec cette adresse e-mail ou votre compte Google. " +
      "(Au tout premier lancement, vous pouvez aussi toucher directement « J'ai reçu un code d'invitation ».)",
    `Choisissez « Rejoindre une tontine », puis saisissez votre code : ${d.code}`,
    'Vérifiez que le groupe affiché est bien « ' + d.nomTontine + ' », puis validez. ' +
      'Vous retrouvez vos noms, le calendrier des tours et vos cotisations.',
  ];
}

export function construireEmailInvitation(d: DonneesInvitation): EmailInvitation {
  const prenom = prenomDe(d.nomMembre);
  const parQui = d.nomAdministratrice ? `${d.nomAdministratrice} vous a inscrit(e)` : 'Vous avez été inscrit(e)';
  const montant = d.montantParNom && d.montantParNom > 0 ? ` (montant d'un nom : ${formaterMontant(d.montantParNom)})` : '';
  const sujet = `Votre code pour rejoindre « ${d.nomTontine} » sur TontineFacile`;
  const liste = etapes(d);

  const texte = [
    `Bonjour ${prenom},`,
    '',
    `${parQui} dans la tontine « ${d.nomTontine} »${montant} sur TontineFacile.`,
    '',
    `Votre code d'invitation : ${d.code}`,
    '',
    'Pour rejoindre votre groupe :',
    ...liste.map((etape, i) => `${i + 1}. ${etape}`),
    '',
    'Ce code est personnel : il vous relie à votre propre fiche dans le groupe. Ne le partagez pas.',
    '',
    "Vous recevez cet e-mail parce que l'administratrice de ce groupe a indiqué votre adresse. " +
      "Si vous ne connaissez pas ce groupe, ignorez simplement ce message.",
    '',
    "— L'équipe TontineFacile",
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
<html lang="fr">
<head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>${e(sujet)}</title></head>
<body style="margin:0;padding:0;background:${toile};">
<table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background:${toile};padding:24px 12px;">
<tr><td align="center">
<table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="max-width:520px;background:#ffffff;border-radius:16px;border:1px solid ${trait};">
  <tr><td style="background:${encre};border-radius:16px 16px 0 0;padding:24px;">
    <div style="font:600 12px/16px Arial,Helvetica,sans-serif;letter-spacing:1px;color:${ambre};">INVITATION · TONTINEFACILE</div>
    <div style="font:600 22px/30px Arial,Helvetica,sans-serif;color:#ffffff;margin-top:8px;">${e(d.nomTontine)}</div>
  </td></tr>
  <tr><td style="padding:24px;">
    <p style="margin:0 0 12px;font:600 17px/24px Arial,Helvetica,sans-serif;color:${encre};">Bonjour ${e(prenom)},</p>
    <p style="margin:0 0 20px;font:400 15px/22px Arial,Helvetica,sans-serif;color:${ardoise};">
      ${e(parQui)} dans la tontine <strong style="color:${encre};">« ${e(d.nomTontine)} »</strong>${e(montant)}.
    </p>
    <div style="font:600 12px/16px Arial,Helvetica,sans-serif;letter-spacing:1px;color:${ardoise};margin-bottom:8px;">VOTRE CODE D'INVITATION</div>
    <table role="presentation" cellpadding="0" cellspacing="0" style="margin:0 0 24px;"><tr>${caracteres}</tr></table>
    <div style="font:600 16px/22px Arial,Helvetica,sans-serif;color:${encre};margin-bottom:4px;">Pour rejoindre votre groupe</div>
    <table role="presentation" cellpadding="0" cellspacing="0" style="margin:0 0 20px;">${etapesHtml}</table>
    <div style="background:${toile};border-radius:12px;padding:12px 14px;font:400 13px/19px Arial,Helvetica,sans-serif;color:${ardoise};">
      🔒 Ce code est personnel : il vous relie à votre propre fiche dans le groupe. Ne le partagez pas.
    </div>
  </td></tr>
  <tr><td style="padding:0 24px 24px;font:400 12px/18px Arial,Helvetica,sans-serif;color:${ardoise};">
    Vous recevez cet e-mail parce que l'administratrice de ce groupe a indiqué votre adresse.
    Si vous ne connaissez pas ce groupe, ignorez simplement ce message.
  </td></tr>
</table>
</td></tr>
</table>
</body>
</html>`;

  return { sujet, texte, html };
}
