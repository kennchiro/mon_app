defmodule MonAppWeb.TermsLive do
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
            <svg xmlns="http://www.w3.org/2000/svg" class="h-8 w-8 text-pink-500" viewBox="0 0 24 24" fill="currentColor">
              <path d="M12 21.35l-1.45-1.32C5.4 15.36 2 12.28 2 8.5 2 5.42 4.42 3 7.5 3c1.74 0 3.41.81 4.5 2.09C13.09 3.81 14.76 3 16.5 3 19.58 3 22 5.42 22 8.5c0 3.78-3.4 6.86-8.55 11.54L12 21.35z" />
            </svg>
            <h1 class="text-2xl sm:text-3xl font-bold">Conditions d'utilisation</h1>
          </div>

          <p class="text-base-content/50 text-sm mb-8">Dernière mise à jour : 18 mars 2026</p>

          <div class="prose prose-sm max-w-none text-base-content/80 space-y-6">
            <section>
              <h2 class="text-lg font-bold text-base-content">1. Acceptation des conditions</h2>
              <p>En créant un compte sur DateApp, vous acceptez les présentes conditions d'utilisation dans leur intégralité. Si vous n'êtes pas d'accord avec ces conditions, veuillez ne pas utiliser l'application.</p>
            </section>

            <section>
              <h2 class="text-lg font-bold text-base-content">2. Description du service</h2>
              <p>DateApp est un réseau social de rencontres permettant aux utilisateurs de :</p>
              <ul class="list-disc pl-5 space-y-1">
                <li>Créer un profil avec pseudo, photo et informations personnelles</li>
                <li>Proposer des dates (sorties, activités) et recevoir des candidatures</li>
                <li>Postuler aux dates proposés par d'autres utilisateurs</li>
                <li>Communiquer via un système de messagerie en temps réel</li>
                <li>Ajouter des amis et interagir via des publications</li>
              </ul>
            </section>

            <section>
              <h2 class="text-lg font-bold text-base-content">3. Inscription et compte</h2>
              <ul class="list-disc pl-5 space-y-1">
                <li>Vous devez avoir au moins <strong>18 ans</strong> pour utiliser DateApp</li>
                <li>Un seul compte par personne est autorisé</li>
                <li>Le pseudo choisi à l'inscription ne peut pas être modifié</li>
                <li>Vous êtes responsable de la confidentialité de vos identifiants</li>
                <li>Toute information fausse ou trompeuse peut entraîner la suspension du compte</li>
              </ul>
            </section>

            <section>
              <h2 class="text-lg font-bold text-base-content">4. Système de Dates</h2>
              <p>Le système de dates est au cœur de DateApp. Voici les règles :</p>
              <ul class="list-disc pl-5 space-y-1">
                <li><strong>Confidentialité des candidatures :</strong> Lorsqu'un utilisateur postule à un date, cette information est strictement confidentielle. Seul le créateur du date peut voir la liste des candidats. Les autres utilisateurs ne voient qu'un compteur anonyme ("X personnes intéressées").</li>
                <li><strong>Acceptation :</strong> Le créateur du date décide librement d'accepter ou non les candidatures</li>
                <li><strong>Amitié automatique :</strong> Lorsqu'une candidature est acceptée, une connexion d'amitié est créée automatiquement entre les deux utilisateurs et une conversation est ouverte</li>
                <li><strong>Expiration :</strong> Les dates dont la date et l'heure sont dépassées sont automatiquement marqués comme terminés</li>
                <li>Un date complet (toutes les places prises) n'accepte plus de nouvelles candidatures</li>
              </ul>
            </section>

            <section>
              <h2 class="text-lg font-bold text-base-content">5. Comportement des utilisateurs</h2>
              <p>Il est interdit de :</p>
              <ul class="list-disc pl-5 space-y-1">
                <li>Harceler, menacer ou intimider d'autres utilisateurs</li>
                <li>Publier du contenu à caractère sexuel, violent ou haineux</li>
                <li>Créer de faux profils ou usurper l'identité d'autrui</li>
                <li>Utiliser l'application à des fins commerciales ou d'arnaque</li>
                <li>Envoyer du spam ou des messages non sollicités en masse</li>
                <li>Collecter les données personnelles d'autres utilisateurs</li>
              </ul>
            </section>

            <section>
              <h2 class="text-lg font-bold text-base-content">6. Modération et signalement</h2>
              <ul class="list-disc pl-5 space-y-1">
                <li>Tout utilisateur peut signaler un profil, une publication ou un date</li>
                <li>Vous pouvez bloquer un utilisateur à tout moment — il ne pourra plus voir votre profil ni vous contacter</li>
                <li>L'équipe DateApp se réserve le droit de supprimer tout contenu inapproprié et de suspendre les comptes en infraction</li>
              </ul>
            </section>

            <section>
              <h2 class="text-lg font-bold text-base-content">7. Limites d'utilisation</h2>
              <ul class="list-disc pl-5 space-y-1">
                <li>Maximum de 20 demandes d'ami par jour</li>
                <li>Les images uploadées sont limitées en taille (5 Mo pour les avatars, 10 Mo pour les publications)</li>
              </ul>
            </section>

            <section>
              <h2 class="text-lg font-bold text-base-content">8. Suppression du compte</h2>
              <ul class="list-disc pl-5 space-y-1">
                <li>Vous pouvez demander la suppression de votre compte à tout moment depuis les paramètres du profil</li>
                <li>La suppression est effective après un délai de <strong>30 jours</strong></li>
                <li>Pendant ce délai, vous pouvez annuler la suppression en vous reconnectant</li>
                <li>Après 30 jours, toutes vos données sont supprimées définitivement : profil, dates, messages, amis</li>
              </ul>
            </section>

            <section>
              <h2 class="text-lg font-bold text-base-content">9. Propriété intellectuelle</h2>
              <p>Les contenus que vous publiez sur DateApp vous appartiennent. En les publiant, vous accordez à DateApp une licence non exclusive pour les afficher dans le cadre du service. Vous ne pouvez pas copier ou redistribuer les contenus d'autres utilisateurs sans leur consentement.</p>
            </section>

            <section>
              <h2 class="text-lg font-bold text-base-content">10. Limitation de responsabilité</h2>
              <p>DateApp facilite les rencontres entre utilisateurs mais ne peut être tenu responsable du comportement des utilisateurs lors de rencontres en personne. Nous vous recommandons de toujours vous rencontrer dans un lieu public et d'informer un proche.</p>
            </section>

            <section>
              <h2 class="text-lg font-bold text-base-content">11. Modification des conditions</h2>
              <p>DateApp se réserve le droit de modifier ces conditions à tout moment. Les utilisateurs seront informés des changements significatifs. L'utilisation continue du service après modification vaut acceptation des nouvelles conditions.</p>
            </section>

            <section>
              <h2 class="text-lg font-bold text-base-content">12. Contact</h2>
              <p>Pour toute question concernant ces conditions, vous pouvez nous contacter via l'application ou par email.</p>
            </section>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
