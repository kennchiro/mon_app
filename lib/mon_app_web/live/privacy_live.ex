defmodule MonAppWeb.PrivacyLive do
  use MonAppWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-base-200">
      <div class="max-w-3xl mx-auto p-4 sm:p-8 pb-20">
        <a href="/" class="inline-flex items-center gap-2 text-sm text-base-content/50 hover:text-pink-500 transition-colors mb-6">
          <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
            <path stroke-linecap="round" stroke-linejoin="round" d="M15 19l-7-7 7-7" />
          </svg>
          Retour
        </a>

        <div class="bg-base-100 rounded-2xl shadow-sm p-6 sm:p-10">
          <div class="flex items-center gap-3 mb-8">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-8 w-8 text-pink-500" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
              <path stroke-linecap="round" stroke-linejoin="round" d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z" />
            </svg>
            <h1 class="text-2xl sm:text-3xl font-bold">Politique de confidentialité</h1>
          </div>

          <p class="text-base-content/50 text-sm mb-8">Dernière mise à jour : 18 mars 2026</p>

          <div class="prose prose-sm max-w-none text-base-content/80 space-y-6">
            <section>
              <h2 class="text-lg font-bold text-base-content">1. Données collectées</h2>
              <p>DateApp collecte les données suivantes :</p>

              <h3 class="text-base font-semibold text-base-content mt-4">Données fournies par vous :</h3>
              <ul class="list-disc pl-5 space-y-1">
                <li><strong>Compte :</strong> pseudo, adresse email, mot de passe (chiffré)</li>
                <li><strong>Profil :</strong> photo de profil, bio, genre, date de naissance, nationalité, localisation (saisie manuellement), préférences de recherche</li>
                <li><strong>Contenu :</strong> publications, dates proposés, messages, images, commentaires, réactions</li>
              </ul>

              <h3 class="text-base font-semibold text-base-content mt-4">Données générées par l'utilisation :</h3>
              <ul class="list-disc pl-5 space-y-1">
                <li>Statut en ligne (indicateur de présence)</li>
                <li>Date et heure de connexion</li>
                <li>Candidatures aux dates</li>
                <li>Relations d'amitié</li>
                <li>Signalements et blocages</li>
              </ul>

              <div class="bg-pink-500/5 border border-pink-500/10 rounded-xl p-4 mt-4">
                <p class="text-sm font-medium text-base-content">
                  <strong>Ce que nous ne collectons PAS :</strong>
                </p>
                <ul class="list-disc pl-5 space-y-1 mt-2 text-sm">
                  <li>Pas de géolocalisation automatique</li>
                  <li>Pas de suivi publicitaire</li>
                  <li>Pas d'accès aux contacts téléphoniques</li>
                  <li>Pas de données bancaires</li>
                </ul>
              </div>
            </section>

            <section>
              <h2 class="text-lg font-bold text-base-content">2. Utilisation des données</h2>
              <p>Vos données sont utilisées pour :</p>
              <ul class="list-disc pl-5 space-y-1">
                <li>Permettre le fonctionnement du service (profil, dates, messagerie)</li>
                <li>Afficher votre profil aux autres utilisateurs</li>
                <li>Envoyer des notifications en temps réel (messages, candidatures, demandes d'ami)</li>
                <li>Assurer la sécurité et la modération de la plateforme</li>
              </ul>
              <p class="mt-2"><strong>Vos données ne sont jamais vendues à des tiers.</strong></p>
            </section>

            <section>
              <h2 class="text-lg font-bold text-base-content">3. Confidentialité des candidatures aux dates</h2>
              <div class="bg-base-200/50 rounded-xl p-4">
                <p class="text-sm">
                  La confidentialité des candidatures est un principe fondamental de DateApp :
                </p>
                <ul class="list-disc pl-5 space-y-1 mt-2 text-sm">
                  <li><strong>Seul le créateur</strong> d'un date peut voir qui a postulé</li>
                  <li>Les autres utilisateurs voient uniquement un compteur anonyme ("X personnes intéressées")</li>
                  <li>Le nom, la photo et les informations du candidat ne sont <strong>jamais affichés publiquement</strong></li>
                  <li>Cette confidentialité s'applique aussi bien aux candidatures en attente qu'aux candidatures refusées</li>
                  <li>Lorsqu'une candidature est acceptée, seuls les deux utilisateurs concernés en sont informés</li>
                </ul>
              </div>
            </section>

            <section>
              <h2 class="text-lg font-bold text-base-content">4. Visibilité du profil</h2>
              <p>Vous contrôlez la visibilité de vos données :</p>
              <ul class="list-disc pl-5 space-y-1">
                <li>Vous pouvez choisir de masquer vos dates et/ou publications de votre profil public</li>
                <li>Les publications peuvent être réglées en mode public, amis uniquement, ou privé</li>
                <li>Votre statut en ligne est visible par tous les utilisateurs connectés</li>
                <li>Le blocage d'un utilisateur le rend invisible pour vous et vous rend invisible pour lui</li>
              </ul>
            </section>

            <section>
              <h2 class="text-lg font-bold text-base-content">5. Stockage et sécurité</h2>
              <ul class="list-disc pl-5 space-y-1">
                <li>Les mots de passe sont chiffrés avec Bcrypt (jamais stockés en clair)</li>
                <li>Les données sont stockées sur des serveurs sécurisés</li>
                <li>Les communications en temps réel sont gérées par WebSocket</li>
                <li>Les sessions utilisateur sont protégées par des tokens CSRF</li>
              </ul>
            </section>

            <section>
              <h2 class="text-lg font-bold text-base-content">6. Conservation des données</h2>
              <ul class="list-disc pl-5 space-y-1">
                <li>Vos données sont conservées tant que votre compte est actif</li>
                <li>En cas de demande de suppression, vos données sont conservées 30 jours (période d'annulation) puis supprimées définitivement</li>
                <li>Les signalements peuvent être conservés après la suppression du compte à des fins de sécurité</li>
              </ul>
            </section>

            <section>
              <h2 class="text-lg font-bold text-base-content">7. Vos droits</h2>
              <p>Conformément à la réglementation applicable, vous disposez des droits suivants :</p>
              <ul class="list-disc pl-5 space-y-1">
                <li><strong>Droit d'accès :</strong> consulter toutes les données associées à votre compte</li>
                <li><strong>Droit de rectification :</strong> modifier vos informations de profil à tout moment</li>
                <li><strong>Droit de suppression :</strong> supprimer votre compte et toutes les données associées</li>
                <li><strong>Droit de portabilité :</strong> demander l'export de vos données</li>
                <li><strong>Droit de blocage :</strong> bloquer tout utilisateur pour empêcher tout contact</li>
              </ul>
            </section>

            <section>
              <h2 class="text-lg font-bold text-base-content">8. Mineurs</h2>
              <p>DateApp est strictement réservé aux personnes de <strong>18 ans et plus</strong>. Si nous apprenons qu'un mineur a créé un compte, celui-ci sera immédiatement supprimé. Tout utilisateur peut signaler un profil suspecté d'appartenir à un mineur.</p>
            </section>

            <section>
              <h2 class="text-lg font-bold text-base-content">9. Cookies et données locales</h2>
              <p>DateApp utilise :</p>
              <ul class="list-disc pl-5 space-y-1">
                <li><strong>Cookie de session :</strong> nécessaire pour maintenir votre connexion (obligatoire)</li>
                <li><strong>LocalStorage :</strong> préférence de thème (clair/sombre)</li>
                <li><strong>Service Worker :</strong> pour le fonctionnement hors-ligne de l'application (PWA)</li>
              </ul>
              <p class="mt-2">Aucun cookie publicitaire ou de suivi n'est utilisé.</p>
            </section>

            <section>
              <h2 class="text-lg font-bold text-base-content">10. Modifications</h2>
              <p>Cette politique peut être mise à jour. En cas de changements significatifs, les utilisateurs seront informés via une notification dans l'application.</p>
            </section>

            <section>
              <h2 class="text-lg font-bold text-base-content">11. Contact</h2>
              <p>Pour toute question relative à vos données personnelles ou pour exercer vos droits, contactez-nous via l'application ou par email.</p>
            </section>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
