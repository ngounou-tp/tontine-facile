import { construireEmailInvitation, type EmailInvitation, type Langue } from './email_invitation.ts';

/**
 * Statut consigné dans `invitation_deliveries`, lisible par le bureau du
 * groupe :
 * - `en_cours`   : envoi réservé, pas encore terminé ;
 * - `envoye`     : remis au serveur SMTP ;
 * - `simule`     : SMTP non configuré en développement (rien n'est envoyé) ;
 * - `echec`      : l'envoi a échoué (voir `error`) ;
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

/** Erreur dont le message peut être montré tel quel au bureau. */
export class ErreurEnvoi extends Error {}

/** Accès aux données nécessaires (service role : contourne la RLS). */
export interface Depot {
  invitation(code: string): Promise<{ groupId: string; memberId: string; createdBy: string | null } | null>;
  groupe(groupId: string): Promise<{ nom: string; montantParNom?: number } | null>;
  membre(memberId: string): Promise<{ nomComplet: string; email: string | null; userId: string | null } | null>;
  /** Nom et langue de la personne qui invite, si sa fiche est retrouvée. */
  inviteur(groupId: string, userId: string | null): Promise<{ nom?: string; langue?: Langue }>;
  /** Réserve l'envoi, atomiquement : `false` s'il est déjà fait ou en cours. */
  reserver(args: { memberId: string; groupId: string; code: string; email: string }): Promise<boolean>;
  consigner(args: {
    memberId: string;
    groupId: string;
    code: string;
    email: string | null;
    statut: StatutEnvoi;
    erreur?: string;
  }): Promise<void>;
}

export interface Journal {
  info(message: string, contexte?: Record<string, unknown>): void;
  warn(message: string, contexte?: Record<string, unknown>): void;
  error(message: string, contexte?: Record<string, unknown>): void;
}

/**
 * Traite la création d'une invitation (`group_invitations`) : envoie au
 * membre invité son code et la marche à suivre, une seule fois, et consigne
 * le résultat pour le bureau.
 *
 * Cas ignorés : invitation introuvable, membre introuvable ou déjà inscrit,
 * envoi déjà fait ou en cours.
 */
export async function traiterNouvelleInvitation(
  depot: Depot,
  code: string,
  envoyer: Envoyeur,
  options: { lienApplication?: string; journal?: Journal } = {},
): Promise<ResultatTraitement> {
  const journal = options.journal ?? console;
  const invitation = await depot.invitation(code);
  if (!invitation) {
    journal.warn('Invitation introuvable, ignorée', { code });
    return 'ignore';
  }
  const { groupId, memberId } = invitation;

  const groupe = await depot.groupe(groupId);
  if (!groupe) {
    journal.warn('Groupe introuvable pour une invitation', { code, groupId });
    return 'ignore';
  }

  const membre = await depot.membre(memberId);
  if (!membre || membre.userId) return 'ignore';

  const email = membre.email?.trim() ?? '';
  if (!email) {
    await depot.consigner({ memberId, groupId, code, email: null, statut: 'sans_email' });
    return 'sans_email';
  }

  // Un webhook peut être livré plus d'une fois pour le même événement : la
  // réservation atomique garantit un seul e-mail.
  if (!(await depot.reserver({ memberId, groupId, code, email }))) return 'ignore';

  const inviteur = await depot.inviteur(groupId, invitation.createdBy);
  const message = construireEmailInvitation({
    nomMembre: membre.nomComplet,
    nomTontine: groupe.nom,
    nomAdministratrice: inviteur.nom,
    code,
    montantParNom: groupe.montantParNom,
    lienApplication: options.lienApplication || undefined,
    langue: inviteur.langue,
  });

  try {
    const statut = await envoyer({ destinataire: email, ...message });
    await depot.consigner({ memberId, groupId, code, email, statut });
    journal.info("E-mail d'invitation traité", { groupId, memberId, statut });
    return statut;
  } catch (erreur) {
    journal.error("Échec de l'envoi de l'e-mail d'invitation", { groupId, memberId, erreur: String(erreur) });
    await depot.consigner({ memberId, groupId, code, email, statut: 'echec', erreur: messageErreur(erreur, inviteur.langue) });
    return 'echec';
  }
}

/** Message court et compréhensible pour le bureau (le détail technique
 * reste dans les journaux de la fonction). */
export function messageErreur(erreur: unknown, langue: Langue = 'fr'): string {
  if (erreur instanceof ErreurEnvoi) return erreur.message;
  const reponse = (erreur as { responseCode?: number } | null)?.responseCode;
  if (typeof reponse === 'number' && reponse >= 550 && reponse < 560) {
    return langue === 'en'
      ? 'The email address was rejected. Check it in the member’s profile.'
      : "L'adresse e-mail a été refusée. Vérifiez-la dans la fiche du membre.";
  }
  return langue === 'en'
    ? "The email server didn't respond. Share the code another way."
    : "Le serveur d'envoi n'a pas répondu. Partagez le code autrement.";
}
