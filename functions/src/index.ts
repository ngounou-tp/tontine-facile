import { initializeApp } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';
import { logger } from 'firebase-functions';
import { defineInt, defineSecret, defineString } from 'firebase-functions/params';
import { onDocumentCreated } from 'firebase-functions/v2/firestore';
import nodemailer from 'nodemailer';

import { Envoyeur, ErreurEnvoi, traiterNouvelleInvitation } from './traitement';

initializeApp();

// Configuration SMTP (fournisseur au choix : Brevo, Gmail avec mot de passe
// d'application, Mailjet, SendGrid…). Valeurs non secrètes dans
// `functions/.env`, mot de passe dans Secret Manager — voir
// docs/EMAIL_INVITATIONS.md.
const SMTP_HOST = defineString('SMTP_HOST', { default: '' });
const SMTP_PORT = defineInt('SMTP_PORT', { default: 465 });
const SMTP_USER = defineString('SMTP_USER', { default: '' });
const SMTP_PASS = defineSecret('SMTP_PASS');
const MAIL_EXPEDITEUR = defineString('MAIL_EXPEDITEUR', { default: 'TontineFacile <no-reply@tontinefacile.app>' });
const LIEN_APPLICATION = defineString('LIEN_APPLICATION', { default: '' });

// Même région que la base Firestore (africa-south1) : un déclencheur
// Firestore doit s'exécuter dans la région de sa base.
const REGION = 'africa-south1';

function creerEnvoyeur(): Envoyeur {
  const host = SMTP_HOST.value();
  if (!host) {
    if (process.env.FUNCTIONS_EMULATOR === 'true') {
      // Émulateur sans SMTP : on journalise l'e-mail au lieu de l'envoyer.
      return async (message) => {
        logger.info('[simulation] E-mail d’invitation', {
          a: message.destinataire,
          sujet: message.sujet,
          texte: message.texte,
        });
        return 'simule';
      };
    }
    return async () => {
      throw new ErreurEnvoi("L'envoi d'e-mails n'est pas encore configuré. Partagez le code autrement.");
    };
  }

  const port = SMTP_PORT.value();
  const transport = nodemailer.createTransport({
    host,
    port,
    secure: port === 465,
    auth: { user: SMTP_USER.value(), pass: SMTP_PASS.value() },
  });
  return async (message) => {
    await transport.sendMail({
      from: MAIL_EXPEDITEUR.value(),
      to: message.destinataire,
      subject: message.sujet,
      text: message.texte,
      html: message.html,
    });
    return 'envoye';
  };
}

/**
 * Dès qu'une administratrice ajoute un membre (création de
 * `invitations/{code}` par l'application), envoie au membre son code
 * d'invitation et la procédure pour rejoindre le groupe. Le résultat est
 * consigné dans `tontines/{id}/envoisInvitation/{membreId}`.
 */
export const envoyerEmailInvitation = onDocumentCreated(
  {
    document: 'invitations/{code}',
    region: REGION,
    secrets: [SMTP_PASS],
    // Un e-mail ne vaut pas une instance chaude en permanence.
    maxInstances: 5,
    timeoutSeconds: 60,
  },
  async (event) => {
    const donnees = event.data?.data();
    if (!donnees) return;
    await traiterNouvelleInvitation(getFirestore(), event.params.code, donnees, creerEnvoyeur(), {
      lienApplication: LIEN_APPLICATION.value(),
    });
  },
);
