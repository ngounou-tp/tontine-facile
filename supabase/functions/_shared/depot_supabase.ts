import type { Langue } from './email_invitation.ts';
import type { Depot } from './traitement.ts';

/** Ce dont le dépôt a besoin d'un client Supabase (ou PostgREST seul, en
 * test) : requêtes sur les tables et appels de fonctions SQL. */
// deno-lint-ignore no-explicit-any
export type ClientDonnees = { from: (table: string) => any; rpc: (fn: string, args?: Record<string, unknown>) => any };

/** [Depot] sur la base Supabase, avec le rôle service (contourne la RLS). */
export function depotSupabase(db: ClientDonnees): Depot {
  return {
    async invitation(code) {
      const { data, error } = await db
        .from('group_invitations')
        .select('group_id, member_id, created_by')
        .eq('code', code)
        .maybeSingle();
      if (error) throw error;
      return data ? { groupId: data.group_id, memberId: data.member_id, createdBy: data.created_by } : null;
    },
    async groupe(groupId) {
      const { data, error } = await db
        .from('groups')
        .select('name, tontine_settings(amount_per_name)')
        .eq('id', groupId)
        .maybeSingle();
      if (error) throw error;
      if (!data) return null;
      const reglages = Array.isArray(data.tontine_settings) ? data.tontine_settings[0] : data.tontine_settings;
      const montant = reglages?.amount_per_name;
      return { nom: data.name, montantParNom: montant == null ? undefined : Number(montant) };
    },
    async membre(memberId) {
      const { data, error } = await db
        .from('group_members')
        .select('full_name, email, user_id')
        .eq('id', memberId)
        .maybeSingle();
      if (error) throw error;
      return data ? { nomComplet: data.full_name, email: data.email, userId: data.user_id } : null;
    },
    async inviteur(groupId, userId) {
      if (!userId) return {};
      const [{ data: fiche }, { data: profil }] = await Promise.all([
        db.from('group_members').select('full_name').eq('group_id', groupId).eq('user_id', userId).maybeSingle(),
        db.from('profiles').select('locale').eq('id', userId).maybeSingle(),
      ]);
      const langue = profil?.locale === 'en' ? 'en' : profil?.locale === 'fr' ? 'fr' : undefined;
      return { nom: fiche?.full_name?.trim() || undefined, langue: langue as Langue | undefined };
    },
    async reserver({ memberId, groupId, code, email }) {
      const { data, error } = await db.rpc('reserve_invitation_delivery', {
        p_member_id: memberId,
        p_group_id: groupId,
        p_code: code,
        p_email: email,
      });
      if (error) throw error;
      return data === true;
    },
    async consigner({ memberId, groupId, code, email, statut, erreur }) {
      const maintenant = new Date().toISOString();
      const { error } = await db.from('invitation_deliveries').upsert({
        member_id: memberId,
        group_id: groupId,
        code,
        email,
        status: statut,
        error: erreur ?? null,
        updated_at: maintenant,
        sent_at: statut === 'envoye' || statut === 'simule' ? maintenant : null,
      });
      if (error) throw error;
    },
  };
}
