// Edge Function : e-mail d'invitation envoyé au membre que le bureau vient
// d'ajouter. Appelée par un Database Webhook Supabase sur l'insertion dans
// `group_invitations` (voir README, section « E-mails d'invitation »).
//
// Secrets (supabase secrets set ...) :
//   INVITATION_WEBHOOK_SECRET  secret partagé, envoyé par le webhook dans
//                              l'en-tête `x-webhook-secret`
//   SMTP_HOST, SMTP_PORT, SMTP_USER, SMTP_PASS, MAIL_EXPEDITEUR
//   LIEN_APPLICATION           lien Play Store / App Store (facultatif)
// SUPABASE_URL et SUPABASE_SERVICE_ROLE_KEY sont fournis par la plateforme.
import { createClient } from 'npm:@supabase/supabase-js@2';
import nodemailer from 'npm:nodemailer@6';

import { depotSupabase } from '../_shared/depot_supabase.ts';
import {
  type Envoyeur,
  ErreurEnvoi,
  traiterNouvelleInvitation,
} from '../_shared/traitement.ts';

function creerEnvoyeur(): Envoyeur {
  const host = Deno.env.get('SMTP_HOST') ?? '';
  if (!host) {
    if (Deno.env.get('SUPABASE_URL')?.includes('127.0.0.1') || Deno.env.get('SUPABASE_URL')?.includes('localhost')) {
      // Développement local sans SMTP : on journalise au lieu d'envoyer.
      return async (message) => {
        console.info('[simulation] E-mail d’invitation', { a: message.destinataire, sujet: message.sujet });
        return 'simule';
      };
    }
    return async () => {
      throw new ErreurEnvoi("L'envoi d'e-mails n'est pas encore configuré. Partagez le code autrement.");
    };
  }

  const port = Number(Deno.env.get('SMTP_PORT') ?? '465');
  const transport = nodemailer.createTransport({
    host,
    port,
    secure: port === 465,
    auth: { user: Deno.env.get('SMTP_USER') ?? '', pass: Deno.env.get('SMTP_PASS') ?? '' },
  });
  return async (message) => {
    await transport.sendMail({
      from: Deno.env.get('MAIL_EXPEDITEUR') ?? 'DjanguiBook <no-reply@djanguibook.app>',
      to: message.destinataire,
      subject: message.sujet,
      text: message.texte,
      html: message.html,
    });
    return 'envoye';
  };
}

/** Comparaison en temps constant du secret du webhook. */
function memeSecret(a: string, b: string): boolean {
  if (a.length !== b.length) return false;
  let difference = 0;
  for (let i = 0; i < a.length; i++) difference |= a.charCodeAt(i) ^ b.charCodeAt(i);
  return difference === 0;
}

Deno.serve(async (requete) => {
  const attendu = Deno.env.get('INVITATION_WEBHOOK_SECRET') ?? '';
  if (!attendu || !memeSecret(requete.headers.get('x-webhook-secret') ?? '', attendu)) {
    return new Response('forbidden', { status: 403 });
  }

  const charge = await requete.json().catch(() => null);
  const code = charge?.type === 'INSERT' && charge?.table === 'group_invitations' ? charge.record?.code : null;
  if (typeof code !== 'string') return new Response('ignored', { status: 200 });

  const db = createClient(Deno.env.get('SUPABASE_URL')!, Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!, {
    auth: { persistSession: false },
  });
  const resultat = await traiterNouvelleInvitation(depotSupabase(db), code, creerEnvoyeur(), {
    lienApplication: Deno.env.get('LIEN_APPLICATION') ?? undefined,
  });
  return Response.json({ resultat });
});
