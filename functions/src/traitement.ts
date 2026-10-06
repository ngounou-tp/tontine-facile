import { FieldValue, Firestore, Timestamp } from 'firebase-admin/firestore';
import { logger } from 'firebase-functions';

import { construireEmailInvitation, EmailInvitation } from './email_invitation';

/**
 * Statut suivi dans `tontines/{tontineId}/envoisInvitation/{membreId}`, lu
 * par l'application pour informer l'administratrice :
 * - `en_cours`   : envoi réservé, pas encore terminé ;
 * - `envoye`     : remis au serveur SMTP ;
 * - `simule`     : émulateur local sans SMTP (rien n'est réellement envoyé) ;
 * - `echec`      : l'envoi a échoué (voir `erreur`) ;
 * - `sans_email` : le membre n'a pas d'adresse e-mail (WhatsApp seul).
 */
export type StatutEnvoi = 'en_cours' | 'envoye' | 'simule' | 'echec' | 'sans_email';

/** Résultat du traitement : un statut, ou `ignore` si aucun e-mail n'est dû. */
export type ResultatTraitement = StatutEnvoi | 'ignore';

export interface Message extends EmailInvitation {
  destinataire: string;
}

/** Envoie le message ; renvoie `envoye`, ou `simule` hors production. */
export type Envoyeur = (message: Message) => Promise<'envoye' | 'simule'>;

/** Erreur dont le message peut être montré tel quel à l'administratrice. */
export class ErreurEnvoi extends Error {}

/** Au-delà, une réservation `en_cours` est considérée comme abandonnée
 * (instance arrêtée en plein envoi) et peut être reprise. */
const DELAI_RESERVATION_MS = 5 * 60 * 1000;

/**
 * Traite la création d'une invitation (`invitations/{code}`) : envoie au
 * membre invité son code et la marche à suivre, une seule fois, et consigne
 * le résultat pour l'application.
 *
 * Cas ignorés : l'auto-invitation de l'administratrice (code de la tontine,
 * créée avec la tontine elle-même), un membre introuvable ou déjà inscrit.
 */
export async function traiterNouvelleInvitation(
  db: Firestore,
  code: string,
  invitation: { tontineId?: unknown; membreId?: unknown },
  envoyer: Envoyeur,
  options: { lienApplication?: string } = {},
): Promise<ResultatTraitement> {
  const tontineId = typeof invitation.tontineId === 'string' ? invitation.tontineId : '';
  const membreId = typeof invitation.membreId === 'string' ? invitation.membreId : '';
  if (!tontineId || !membreId) {
    logger.warn('Invitation incomplète, ignorée', { code });
    return 'ignore';
  }

  const tontine = (await db.doc(`tontines/${tontineId}`).get()).data();
  if (!tontine) {
    logger.warn('Tontine introuvable pour une invitation', { code, tontineId });
    return 'ignore';
  }
  if (tontine.codeInvitation === code) {
    // Invitation que l'administratrice se crée à elle-même avec la tontine.
    return 'ignore';
  }

  const membre = (await db.doc(`tontines/${tontineId}/membres/${membreId}`).get()).data();
  if (!membre || membre.uid) return 'ignore';

  const suivi = db.doc(`tontines/${tontineId}/envoisInvitation/${membreId}`);
  const email = typeof membre.email === 'string' ? membre.email.trim() : '';
  if (!email) {
    await suivi.set({ code, statut: 'sans_email', majLe: FieldValue.serverTimestamp() });
    return 'sans_email';
  }

  // Un déclencheur Firestore peut s'exécuter plus d'une fois pour le même
  // événement : la réservation transactionnelle garantit un seul e-mail.
  const reserve = await db.runTransaction(async (transaction) => {
    const existant = (await transaction.get(suivi)).data();
    if (existant && existant.code === code) {
      if (existant.statut === 'envoye' || existant.statut === 'simule') return false;
      const majLe = existant.majLe instanceof Timestamp ? existant.majLe.toMillis() : 0;
      if (existant.statut === 'en_cours' && Date.now() - majLe < DELAI_RESERVATION_MS) return false;
    }
    transaction.set(suivi, { code, email, statut: 'en_cours', majLe: FieldValue.serverTimestamp() });
    return true;
  });
  if (!reserve) return 'ignore';

  const message = construireEmailInvitation({
    nomMembre: String(membre.nomComplet ?? ''),
    nomTontine: String(tontine.nom ?? invitation.tontineId),
    nomAdministratrice: await nomAdministratrice(db, tontineId, tontine.adminUid),
    code,
    montantParNom: typeof tontine.montantParNom === 'number' ? tontine.montantParNom : undefined,
    lienApplication: options.lienApplication || undefined,
  });

  try {
    const statut = await envoyer({ destinataire: email, ...message });
    await suivi.set(
      { code, email, statut, majLe: FieldValue.serverTimestamp(), envoyeLe: FieldValue.serverTimestamp() },
      { merge: true },
    );
    logger.info("E-mail d'invitation traité", { tontineId, membreId, statut });
    return statut;
  } catch (erreur) {
    logger.error("Échec de l'envoi de l'e-mail d'invitation", { tontineId, membreId, erreur });
    await suivi.set(
      { code, email, statut: 'echec', erreur: messageErreur(erreur), majLe: FieldValue.serverTimestamp() },
      { merge: true },
    );
    return 'echec';
  }
}

async function nomAdministratrice(db: Firestore, tontineId: string, adminUid: unknown): Promise<string | undefined> {
  if (typeof adminUid !== 'string') return undefined;
  const resultat = await db.collection(`tontines/${tontineId}/membres`).where('uid', '==', adminUid).limit(1).get();
  const nom = resultat.docs[0]?.data().nomComplet;
  return typeof nom === 'string' && nom.trim() ? nom.trim() : undefined;
}

/** Message court et compréhensible pour l'administratrice (le détail
 * technique reste dans les journaux de la fonction). */
export function messageErreur(erreur: unknown): string {
  if (erreur instanceof ErreurEnvoi) return erreur.message;
  const reponse = (erreur as { responseCode?: number } | null)?.responseCode;
  if (typeof reponse === 'number' && reponse >= 550 && reponse < 560) {
    return "L'adresse e-mail a été refusée. Vérifiez-la dans la fiche du membre.";
  }
  return "Le serveur d'envoi n'a pas répondu. Partagez le code autrement.";
}
