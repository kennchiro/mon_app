defmodule MonAppWeb.LandingLive do
  use MonAppWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, socket, layout: false}
  end

  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-base-200 overflow-x-hidden">
      <!-- Navbar -->
      <nav class="fixed top-0 left-0 right-0 z-50 bg-base-100/80 backdrop-blur-lg border-b border-base-200/50">
        <div class="max-w-6xl mx-auto px-4 sm:px-6 h-16 flex items-center justify-between">
          <div class="flex items-center gap-2">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6 text-pink-500" viewBox="0 0 24 24" fill="currentColor">
              <path d="M12 21.35l-1.45-1.32C5.4 15.36 2 12.28 2 8.5 2 5.42 4.42 3 7.5 3c1.74 0 3.41.81 4.5 2.09C13.09 3.81 14.76 3 16.5 3 19.58 3 22 5.42 22 8.5c0 3.78-3.4 6.86-8.55 11.54L12 21.35z" />
            </svg>
            <span class="text-xl font-bold">Date<span class="text-pink-500">App</span></span>
          </div>
          <div class="flex items-center gap-2">
            <!-- Theme toggle -->
            <button
              id="landing-theme-toggle"
              onclick="
                var current = document.documentElement.getAttribute('data-theme');
                var next = current === 'dark' ? 'light' : 'dark';
                localStorage.setItem('phx:theme', next);
                document.documentElement.setAttribute('data-theme', next);
                document.getElementById('landing-sun').style.display = next === 'dark' ? 'block' : 'none';
                document.getElementById('landing-moon').style.display = next === 'dark' ? 'none' : 'block';
              "
              class="w-8 h-8 rounded-full bg-base-200 grid place-items-center hover:bg-base-300 transition-colors"
            >
              <svg id="landing-sun" style="display:none" class="h-4 w-4 text-base-content" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                <path stroke-linecap="round" stroke-linejoin="round" d="M12 3v1m0 16v1m9-9h-1M4 12H3m15.364 6.364l-.707-.707M6.343 6.343l-.707-.707m12.728 0l-.707.707M6.343 17.657l-.707.707M16 12a4 4 0 11-8 0 4 4 0 018 0z" />
              </svg>
              <svg id="landing-moon" class="h-4 w-4 text-base-content" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                <path stroke-linecap="round" stroke-linejoin="round" d="M20.354 15.354A9 9 0 018.646 3.646 9.003 9.003 0 0012 21a9.003 9.003 0 008.354-5.646z" />
              </svg>
            </button>
            <script>
              (function() {
                var t = document.documentElement.getAttribute('data-theme') || localStorage.getItem('phx:theme');
                if (t === 'dark') {
                  document.getElementById('landing-sun').style.display = 'block';
                  document.getElementById('landing-moon').style.display = 'none';
                }
              })();
            </script>

            <a href="/login" class="text-sm font-medium text-base-content/60 hover:text-base-content transition-colors">
              Se connecter
            </a>
            <a href="/register" class="btn btn-sm bg-base-content text-base-100 hover:bg-pink-500 hover:text-white border-none rounded-full px-5">
              S'inscrire
            </a>
          </div>
        </div>
      </nav>

      <!-- Hero Section -->
      <section class="relative pt-32 pb-20 sm:pt-40 sm:pb-28 px-4 auth-bg">
        <!-- Animated hearts background -->
        <div class="auth-hearts-container">
          <svg class="auth-heart" style="left: 10%; width: 20px; height: 20px; animation-duration: 12s; animation-delay: 0s;" viewBox="0 0 24 24" fill="rgba(236,72,153,0.2)"><path d="M12 21.35l-1.45-1.32C5.4 15.36 2 12.28 2 8.5 2 5.42 4.42 3 7.5 3c1.74 0 3.41.81 4.5 2.09C13.09 3.81 14.76 3 16.5 3 19.58 3 22 5.42 22 8.5c0 3.78-3.4 6.86-8.55 11.54L12 21.35z"/></svg>
          <svg class="auth-heart" style="left: 30%; width: 16px; height: 16px; animation-duration: 15s; animation-delay: 3s;" viewBox="0 0 24 24" fill="rgba(244,114,182,0.25)"><path d="M12 21.35l-1.45-1.32C5.4 15.36 2 12.28 2 8.5 2 5.42 4.42 3 7.5 3c1.74 0 3.41.81 4.5 2.09C13.09 3.81 14.76 3 16.5 3 19.58 3 22 5.42 22 8.5c0 3.78-3.4 6.86-8.55 11.54L12 21.35z"/></svg>
          <svg class="auth-heart" style="left: 55%; width: 22px; height: 22px; animation-duration: 10s; animation-delay: 1s;" viewBox="0 0 24 24" fill="rgba(251,113,133,0.15)"><path d="M12 21.35l-1.45-1.32C5.4 15.36 2 12.28 2 8.5 2 5.42 4.42 3 7.5 3c1.74 0 3.41.81 4.5 2.09C13.09 3.81 14.76 3 16.5 3 19.58 3 22 5.42 22 8.5c0 3.78-3.4 6.86-8.55 11.54L12 21.35z"/></svg>
          <svg class="auth-heart" style="left: 75%; width: 14px; height: 14px; animation-duration: 14s; animation-delay: 5s;" viewBox="0 0 24 24" fill="rgba(236,72,153,0.2)"><path d="M12 21.35l-1.45-1.32C5.4 15.36 2 12.28 2 8.5 2 5.42 4.42 3 7.5 3c1.74 0 3.41.81 4.5 2.09C13.09 3.81 14.76 3 16.5 3 19.58 3 22 5.42 22 8.5c0 3.78-3.4 6.86-8.55 11.54L12 21.35z"/></svg>
          <svg class="auth-heart" style="left: 90%; width: 18px; height: 18px; animation-duration: 16s; animation-delay: 7s;" viewBox="0 0 24 24" fill="rgba(244,114,182,0.2)"><path d="M12 21.35l-1.45-1.32C5.4 15.36 2 12.28 2 8.5 2 5.42 4.42 3 7.5 3c1.74 0 3.41.81 4.5 2.09C13.09 3.81 14.76 3 16.5 3 19.58 3 22 5.42 22 8.5c0 3.78-3.4 6.86-8.55 11.54L12 21.35z"/></svg>
        </div>
        <div class="auth-blob auth-blob-1"></div>
        <div class="auth-blob auth-blob-2"></div>

        <div class="max-w-4xl mx-auto text-center relative z-10">
          <div class="inline-flex items-center gap-2 px-4 py-1.5 bg-pink-500/10 rounded-full text-pink-500 text-sm font-medium mb-6">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" viewBox="0 0 24 24" fill="currentColor">
              <path d="M12 21.35l-1.45-1.32C5.4 15.36 2 12.28 2 8.5 2 5.42 4.42 3 7.5 3c1.74 0 3.41.81 4.5 2.09C13.09 3.81 14.76 3 16.5 3 19.58 3 22 5.42 22 8.5c0 3.78-3.4 6.86-8.55 11.54L12 21.35z" />
            </svg>
            Un espace libre pour tous
          </div>

          <h1 class="text-4xl sm:text-5xl md:text-6xl font-extrabold text-base-content leading-tight">
            Propose un date,<br/>
            <span class="text-pink-500">fais des rencontres</span>
          </h1>

          <p class="text-base-content/50 text-lg sm:text-xl mt-6 max-w-2xl mx-auto leading-relaxed">
            DateApp te permet de proposer des sorties et de rencontrer des personnes qui partagent tes envies. Restaurant, ciné, sport, voyage — c'est toi qui décides.
          </p>

          <div class="flex flex-col sm:flex-row items-center justify-center gap-3 mt-10">
            <a href="/register" class="btn bg-base-content text-base-100 hover:bg-pink-500 hover:text-white border-none rounded-full px-8 h-12 text-base font-semibold transition-all duration-300 w-full sm:w-auto">
              Commencer gratuitement
            </a>
            <a href="/login" class="btn btn-ghost rounded-full px-8 h-12 text-base font-medium w-full sm:w-auto">
              J'ai déjà un compte
            </a>
          </div>

          <p class="text-base-content/30 text-xs mt-4">Gratuit. Sans pub. Respectueux de ta vie privée.</p>
        </div>
      </section>

      <!-- Features Section -->
      <section class="py-16 sm:py-24 px-4">
        <div class="max-w-5xl mx-auto">
          <h2 class="text-2xl sm:text-3xl font-bold text-center mb-4">Comment ça marche ?</h2>
          <p class="text-base-content/50 text-center mb-12 sm:mb-16 max-w-xl mx-auto">En 3 étapes simples, passe de l'idée à la rencontre</p>

          <div class="grid grid-cols-1 md:grid-cols-3 gap-6 sm:gap-8">
            <!-- Step 1 -->
            <div class="bg-base-100 rounded-2xl p-6 sm:p-8 text-center shadow-sm">
              <div class="w-14 h-14 mx-auto bg-pink-500/10 rounded-2xl flex items-center justify-center mb-5">
                <svg xmlns="http://www.w3.org/2000/svg" class="h-7 w-7 text-pink-500" viewBox="0 0 24 24" fill="currentColor">
                  <path d="M12 21.35l-1.45-1.32C5.4 15.36 2 12.28 2 8.5 2 5.42 4.42 3 7.5 3c1.74 0 3.41.81 4.5 2.09C13.09 3.81 14.76 3 16.5 3 19.58 3 22 5.42 22 8.5c0 3.78-3.4 6.86-8.55 11.54L12 21.35z" />
                </svg>
              </div>
              <div class="text-pink-500 text-sm font-bold mb-2">01</div>
              <h3 class="text-lg font-bold mb-2">Propose un date</h3>
              <p class="text-base-content/50 text-sm leading-relaxed">
                Restaurant, cinéma, randonnée, brunch... Choisis une activité, un lieu et une date. C'est toi qui crées l'occasion.
              </p>
            </div>

            <!-- Step 2 -->
            <div class="bg-base-100 rounded-2xl p-6 sm:p-8 text-center shadow-sm">
              <div class="w-14 h-14 mx-auto bg-blue-500/10 rounded-2xl flex items-center justify-center mb-5">
                <svg xmlns="http://www.w3.org/2000/svg" class="h-7 w-7 text-blue-500" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0z" />
                </svg>
              </div>
              <div class="text-blue-500 text-sm font-bold mb-2">02</div>
              <h3 class="text-lg font-bold mb-2">Reçois des candidatures</h3>
              <p class="text-base-content/50 text-sm leading-relaxed">
                Les personnes intéressées postulent. Toi seul vois qui a postulé — c'est 100% confidentiel.
              </p>
            </div>

            <!-- Step 3 -->
            <div class="bg-base-100 rounded-2xl p-6 sm:p-8 text-center shadow-sm">
              <div class="w-14 h-14 mx-auto bg-green-500/10 rounded-2xl flex items-center justify-center mb-5">
                <svg xmlns="http://www.w3.org/2000/svg" class="h-7 w-7 text-green-500" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z" />
                </svg>
              </div>
              <div class="text-green-500 text-sm font-bold mb-2">03</div>
              <h3 class="text-lg font-bold mb-2">Accepte et discute</h3>
              <p class="text-base-content/50 text-sm leading-relaxed">
                Accepte la candidature qui te plaît. Une conversation s'ouvre automatiquement pour organiser votre rencontre.
              </p>
            </div>
          </div>
        </div>
      </section>

      <!-- Categories Section -->
      <section class="py-16 sm:py-24 px-4 bg-base-100">
        <div class="max-w-5xl mx-auto">
          <h2 class="text-2xl sm:text-3xl font-bold text-center mb-4">Tous les types de dates</h2>
          <p class="text-base-content/50 text-center mb-12 max-w-xl mx-auto">Peu importe ton envie du moment, il y a un date pour toi</p>

          <div class="flex flex-wrap justify-center gap-3">
            <div :for={{emoji, label} <- [
              {"🍽️", "Restaurant"},
              {"🎬", "Cinéma"},
              {"⚽", "Sport"},
              {"✈️", "Voyage"},
              {"☕", "Café"},
              {"🎉", "Soirée"},
              {"🎭", "Culture"},
              {"🌿", "Plein air"},
              {"🥾", "Randonnée"},
              {"🎵", "Musique"},
              {"🎮", "Gaming"},
              {"🛍️", "Shopping"},
              {"🥐", "Brunch"},
              {"🧘", "Bien-être"},
              {"🎨", "Art"},
              {"🏖️", "Plage"}
            ]} class="flex items-center gap-2 px-4 py-2.5 bg-base-200/60 rounded-full text-sm font-medium text-base-content/70 hover:bg-pink-500/10 hover:text-pink-500 transition-colors cursor-default">
              <span class="text-base">{emoji}</span>
              <span>{label}</span>
            </div>
          </div>
        </div>
      </section>

      <!-- Trust Section -->
      <section class="py-16 sm:py-24 px-4">
        <div class="max-w-5xl mx-auto">
          <h2 class="text-2xl sm:text-3xl font-bold text-center mb-12">Pourquoi DateApp ?</h2>

          <div class="grid grid-cols-1 sm:grid-cols-2 gap-4 sm:gap-6 max-w-3xl mx-auto">
            <div class="flex items-start gap-4 p-5 bg-base-100 rounded-2xl shadow-sm">
              <div class="w-10 h-10 rounded-xl bg-pink-500/10 flex items-center justify-center shrink-0">
                <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 text-pink-500" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z" />
                </svg>
              </div>
              <div>
                <h3 class="font-bold text-sm mb-1">Candidatures confidentielles</h3>
                <p class="text-base-content/50 text-xs leading-relaxed">Personne ne sait que tu as postulé. Seul le créateur du date voit les candidats.</p>
              </div>
            </div>

            <div class="flex items-start gap-4 p-5 bg-base-100 rounded-2xl shadow-sm">
              <div class="w-10 h-10 rounded-xl bg-blue-500/10 flex items-center justify-center shrink-0">
                <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 text-blue-500" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M18.364 18.364A9 9 0 005.636 5.636m12.728 12.728A9 9 0 015.636 5.636m12.728 12.728L5.636 5.636" />
                </svg>
              </div>
              <div>
                <h3 class="font-bold text-sm mb-1">Block et signalement</h3>
                <p class="text-base-content/50 text-xs leading-relaxed">Tu contrôles ton expérience. Bloque ou signale n'importe qui en un clic.</p>
              </div>
            </div>

            <div class="flex items-start gap-4 p-5 bg-base-100 rounded-2xl shadow-sm">
              <div class="w-10 h-10 rounded-xl bg-green-500/10 flex items-center justify-center shrink-0">
                <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 text-green-500" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                </svg>
              </div>
              <div>
                <h3 class="font-bold text-sm mb-1">100% gratuit</h3>
                <p class="text-base-content/50 text-xs leading-relaxed">Pas d'abonnement, pas de fonctionnalités cachées. Tout est accessible à tous.</p>
              </div>
            </div>

            <div class="flex items-start gap-4 p-5 bg-base-100 rounded-2xl shadow-sm">
              <div class="w-10 h-10 rounded-xl bg-orange-500/10 flex items-center justify-center shrink-0">
                <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 text-orange-500" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                </svg>
              </div>
              <div>
                <h3 class="font-bold text-sm mb-1">Pas de tracking</h3>
                <p class="text-base-content/50 text-xs leading-relaxed">Pas de géolocalisation, pas de pub, pas de revente de données. Ta vie privée respectée.</p>
              </div>
            </div>
          </div>
        </div>
      </section>

      <!-- CTA Section -->
      <section class="py-16 sm:py-24 px-4 bg-base-100">
        <div class="max-w-2xl mx-auto text-center">
          <div class="w-20 h-20 mx-auto bg-pink-500/10 rounded-full flex items-center justify-center mb-6">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-10 w-10 text-pink-500" viewBox="0 0 24 24" fill="currentColor">
              <path d="M12 21.35l-1.45-1.32C5.4 15.36 2 12.28 2 8.5 2 5.42 4.42 3 7.5 3c1.74 0 3.41.81 4.5 2.09C13.09 3.81 14.76 3 16.5 3 19.58 3 22 5.42 22 8.5c0 3.78-3.4 6.86-8.55 11.54L12 21.35z" />
            </svg>
          </div>
          <h2 class="text-2xl sm:text-3xl font-bold mb-4">Prêt à faire des rencontres ?</h2>
          <p class="text-base-content/50 mb-8 max-w-lg mx-auto">
            Rejoins DateApp et propose ton premier date dès aujourd'hui. C'est gratuit et ça prend 30 secondes.
          </p>
          <a href="/register" class="btn bg-base-content text-base-100 hover:bg-pink-500 hover:text-white border-none rounded-full px-10 h-12 text-base font-semibold transition-all duration-300">
            Créer mon compte
          </a>
        </div>
      </section>

      <!-- Footer -->
      <footer class="border-t border-base-200 bg-base-200 py-8 px-4">
        <div class="max-w-5xl mx-auto flex flex-col sm:flex-row items-center justify-between gap-4">
          <div class="flex items-center gap-2">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 text-pink-500" viewBox="0 0 24 24" fill="currentColor">
              <path d="M12 21.35l-1.45-1.32C5.4 15.36 2 12.28 2 8.5 2 5.42 4.42 3 7.5 3c1.74 0 3.41.81 4.5 2.09C13.09 3.81 14.76 3 16.5 3 19.58 3 22 5.42 22 8.5c0 3.78-3.4 6.86-8.55 11.54L12 21.35z" />
            </svg>
            <span class="text-sm font-bold">Date<span class="text-pink-500">App</span></span>
          </div>
          <div class="flex items-center gap-4 text-xs text-base-content/40">
            <a href="/terms" class="hover:text-base-content/60 transition-colors">CGU</a>
            <a href="/privacy" class="hover:text-base-content/60 transition-colors">Confidentialité</a>
            <span>© 2026 DateApp</span>
          </div>
        </div>
      </footer>
    </div>
    """
  end
end
