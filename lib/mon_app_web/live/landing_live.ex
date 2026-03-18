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
          <div class="flex items-center gap-1.5 sm:gap-2">
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
              class="w-8 h-8 rounded-full bg-base-200 grid place-items-center hover:bg-base-300 transition-colors shrink-0"
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

            <a href="/login" class="hidden sm:inline text-sm font-medium text-base-content/60 hover:text-base-content transition-colors">
              Se connecter
            </a>
            <a href="/login" class="sm:hidden w-8 h-8 rounded-full bg-base-200 grid place-items-center hover:bg-base-300 transition-colors shrink-0">
              <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 text-base-content/60" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                <path stroke-linecap="round" stroke-linejoin="round" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
              </svg>
            </a>
            <a href="/register" class="btn btn-sm bg-base-content text-base-100 hover:bg-pink-500 hover:text-white border-none rounded-full px-4 sm:px-5 text-xs sm:text-sm">
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

          <p class="text-base-content/30 text-xs mt-4">
            Gratuit. Sans pub. Respectueux de ta vie privée.
            <span class="inline-flex items-center gap-1 ml-2 px-2 py-0.5 bg-base-content/10 rounded text-[10px] font-bold text-base-content/40">18+</span>
          </p>
        </div>
      </section>

      <!-- Stats Section -->
      <section class="py-10 sm:py-14 px-4 bg-base-100 border-y border-base-200">
        <div class="max-w-4xl mx-auto grid grid-cols-2 sm:grid-cols-4 gap-6 sm:gap-8">
          <div class="text-center">
            <div class="text-3xl sm:text-4xl font-extrabold text-pink-500">100%</div>
            <div class="text-xs sm:text-sm text-base-content/50 mt-1">Gratuit</div>
          </div>
          <div class="text-center">
            <div class="text-3xl sm:text-4xl font-extrabold text-base-content">16</div>
            <div class="text-xs sm:text-sm text-base-content/50 mt-1">Catégories de dates</div>
          </div>
          <div class="text-center">
            <div class="text-3xl sm:text-4xl font-extrabold text-base-content">0</div>
            <div class="text-xs sm:text-sm text-base-content/50 mt-1">Publicités</div>
          </div>
          <div class="text-center">
            <div class="text-3xl sm:text-4xl font-extrabold text-pink-500">30s</div>
            <div class="text-xs sm:text-sm text-base-content/50 mt-1">Pour s'inscrire</div>
          </div>
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

      <!-- Safety Section -->
      <section class="py-16 sm:py-24 px-4 bg-base-100">
        <div class="max-w-3xl mx-auto">
          <div class="text-center mb-10">
            <h2 class="text-2xl sm:text-3xl font-bold mb-3">Ta sécurité, notre priorité</h2>
            <p class="text-base-content/50 max-w-lg mx-auto">DateApp est réservé aux personnes de 18 ans et plus. Nous mettons tout en place pour que tes rencontres se passent bien.</p>
          </div>

          <div class="bg-base-200/50 rounded-2xl p-6 sm:p-8 space-y-4">
            <div class="flex items-start gap-3">
              <div class="w-8 h-8 rounded-full bg-green-500/10 grid place-items-center shrink-0 mt-0.5">
                <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 text-green-500" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M5 13l4 4L19 7" />
                </svg>
              </div>
              <div>
                <h4 class="text-sm font-semibold">Rencontrez-vous dans un lieu public</h4>
                <p class="text-xs text-base-content/50 mt-0.5">Pour un premier date, privilégiez toujours un café, un restaurant ou un lieu fréquenté.</p>
              </div>
            </div>
            <div class="flex items-start gap-3">
              <div class="w-8 h-8 rounded-full bg-green-500/10 grid place-items-center shrink-0 mt-0.5">
                <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 text-green-500" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M5 13l4 4L19 7" />
                </svg>
              </div>
              <div>
                <h4 class="text-sm font-semibold">Informez un proche</h4>
                <p class="text-xs text-base-content/50 mt-0.5">Dites à un ami ou un membre de votre famille où vous allez et avec qui.</p>
              </div>
            </div>
            <div class="flex items-start gap-3">
              <div class="w-8 h-8 rounded-full bg-green-500/10 grid place-items-center shrink-0 mt-0.5">
                <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 text-green-500" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M5 13l4 4L19 7" />
                </svg>
              </div>
              <div>
                <h4 class="text-sm font-semibold">Signalez tout comportement suspect</h4>
                <p class="text-xs text-base-content/50 mt-0.5">Utilisez le bouton signaler sur chaque profil et publication. Notre équipe examine chaque signalement.</p>
              </div>
            </div>
            <div class="flex items-start gap-3">
              <div class="w-8 h-8 rounded-full bg-green-500/10 grid place-items-center shrink-0 mt-0.5">
                <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 text-green-500" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M5 13l4 4L19 7" />
                </svg>
              </div>
              <div>
                <h4 class="text-sm font-semibold">18+ obligatoire</h4>
                <p class="text-xs text-base-content/50 mt-0.5">DateApp est strictement réservé aux adultes. Tout profil mineur sera immédiatement supprimé.</p>
              </div>
            </div>
          </div>
        </div>
      </section>

      <!-- Multi-device Section -->
      <section class="py-16 sm:py-24 px-4">
        <div class="max-w-4xl mx-auto text-center">
          <h2 class="text-2xl sm:text-3xl font-bold mb-4">Disponible partout</h2>
          <p class="text-base-content/50 mb-10 max-w-lg mx-auto">DateApp fonctionne sur tous tes appareils. Installe-la comme une app native, sans passer par un store.</p>

          <div class="grid grid-cols-1 sm:grid-cols-3 gap-4 max-w-2xl mx-auto">
            <a href="/install?p=iphone" class="bg-base-100 rounded-2xl p-5 shadow-sm text-center hover:shadow-md hover:scale-[1.02] transition-all">
              <div class="w-12 h-12 mx-auto bg-base-200 rounded-xl flex items-center justify-center mb-3">
                <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6 text-base-content/60" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.5">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M10.5 1.5H8.25A2.25 2.25 0 006 3.75v16.5a2.25 2.25 0 002.25 2.25h7.5A2.25 2.25 0 0018 20.25V3.75a2.25 2.25 0 00-2.25-2.25H13.5m-3 0V3h3V1.5m-3 0h3m-3 18.75h3" />
                </svg>
              </div>
              <h3 class="font-bold text-sm">iPhone</h3>
              <p class="text-[11px] text-base-content/40 mt-1">Voir les étapes</p>
            </a>
            <a href="/install?p=android" class="bg-base-100 rounded-2xl p-5 shadow-sm text-center hover:shadow-md hover:scale-[1.02] transition-all">
              <div class="w-12 h-12 mx-auto bg-base-200 rounded-xl flex items-center justify-center mb-3">
                <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6 text-base-content/60" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.5">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M10.5 1.5H8.25A2.25 2.25 0 006 3.75v16.5a2.25 2.25 0 002.25 2.25h7.5A2.25 2.25 0 0018 20.25V3.75a2.25 2.25 0 00-2.25-2.25H13.5m-3 0V3h3V1.5m-3 0h3m-3 18.75h3" />
                </svg>
              </div>
              <h3 class="font-bold text-sm">Android</h3>
              <p class="text-[11px] text-base-content/40 mt-1">Voir les étapes</p>
            </a>
            <a href="/install?p=desktop" class="bg-base-100 rounded-2xl p-5 shadow-sm text-center hover:shadow-md hover:scale-[1.02] transition-all">
              <div class="w-12 h-12 mx-auto bg-base-200 rounded-xl flex items-center justify-center mb-3">
                <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6 text-base-content/60" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.5">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M9 17.25v1.007a3 3 0 01-.879 2.122L7.5 21h9l-.621-.621A3 3 0 0115 18.257V17.25m6-12V15a2.25 2.25 0 01-2.25 2.25H5.25A2.25 2.25 0 013 15V5.25m18 0A2.25 2.25 0 0018.75 3H5.25A2.25 2.25 0 003 5.25m18 0V12a2.25 2.25 0 01-2.25 2.25H5.25A2.25 2.25 0 013 12V5.25" />
                </svg>
              </div>
              <h3 class="font-bold text-sm">Desktop</h3>
              <p class="text-[11px] text-base-content/40 mt-1">Voir les étapes</p>
            </a>
          </div>

          <p class="text-center text-base-content/30 text-xs mt-6">
            L'installation est optionnelle — DateApp fonctionne aussi directement dans ton navigateur.
          </p>
        </div>
      </section>

      <!-- FAQ Section -->
      <section class="py-16 sm:py-24 px-4 bg-base-100">
        <div class="max-w-2xl mx-auto">
          <h2 class="text-2xl sm:text-3xl font-bold text-center mb-10">Questions fréquentes</h2>

          <div class="space-y-3">
            <details class="group bg-base-200/40 rounded-xl">
              <summary class="flex items-center justify-between cursor-pointer px-5 py-4 text-sm font-medium">
                C'est quoi un "date" sur DateApp ?
                <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 text-base-content/40 group-open:rotate-180 transition-transform" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M19 9l-7 7-7-7" />
                </svg>
              </summary>
              <div class="px-5 pb-4 text-sm text-base-content/60 leading-relaxed">
                Un date est une proposition de sortie ou d'activité que tu crées. Tu choisis le type (restaurant, sport, cinéma...), le lieu, la date et le nombre de places. D'autres personnes peuvent ensuite postuler pour t'accompagner.
              </div>
            </details>

            <details class="group bg-base-200/40 rounded-xl">
              <summary class="flex items-center justify-between cursor-pointer px-5 py-4 text-sm font-medium">
                Est-ce que les autres voient que j'ai postulé ?
                <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 text-base-content/40 group-open:rotate-180 transition-transform" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M19 9l-7 7-7-7" />
                </svg>
              </summary>
              <div class="px-5 pb-4 text-sm text-base-content/60 leading-relaxed">
                <strong>Non, jamais.</strong> Seul le créateur du date peut voir qui a postulé. Les autres utilisateurs voient uniquement un compteur anonyme ("X personnes intéressées"). Tes candidatures restent 100% confidentielles.
              </div>
            </details>

            <details class="group bg-base-200/40 rounded-xl">
              <summary class="flex items-center justify-between cursor-pointer px-5 py-4 text-sm font-medium">
                C'est vraiment gratuit ?
                <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 text-base-content/40 group-open:rotate-180 transition-transform" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M19 9l-7 7-7-7" />
                </svg>
              </summary>
              <div class="px-5 pb-4 text-sm text-base-content/60 leading-relaxed">
                Oui, DateApp est 100% gratuit. Pas d'abonnement premium, pas de fonctionnalités cachées, pas de pub. Toutes les fonctionnalités sont accessibles à tous les utilisateurs.
              </div>
            </details>

            <details class="group bg-base-200/40 rounded-xl">
              <summary class="flex items-center justify-between cursor-pointer px-5 py-4 text-sm font-medium">
                Que se passe-t-il quand ma candidature est acceptée ?
                <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 text-base-content/40 group-open:rotate-180 transition-transform" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M19 9l-7 7-7-7" />
                </svg>
              </summary>
              <div class="px-5 pb-4 text-sm text-base-content/60 leading-relaxed">
                Tu reçois une notification et une conversation s'ouvre automatiquement avec le créateur du date. Vous devenez aussi amis sur la plateforme. Vous pouvez alors discuter pour organiser votre rencontre.
              </div>
            </details>

            <details class="group bg-base-200/40 rounded-xl">
              <summary class="flex items-center justify-between cursor-pointer px-5 py-4 text-sm font-medium">
                Mes données sont-elles protégées ?
                <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 text-base-content/40 group-open:rotate-180 transition-transform" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M19 9l-7 7-7-7" />
                </svg>
              </summary>
              <div class="px-5 pb-4 text-sm text-base-content/60 leading-relaxed">
                Oui. Nous ne collectons pas de géolocalisation, nous ne diffusons pas de pub, et nous ne revendons jamais vos données. Les mots de passe sont chiffrés et vous pouvez supprimer votre compte à tout moment.
                <a href="/privacy" class="text-pink-500 hover:underline ml-1">En savoir plus</a>
              </div>
            </details>

            <details class="group bg-base-200/40 rounded-xl">
              <summary class="flex items-center justify-between cursor-pointer px-5 py-4 text-sm font-medium">
                Je peux supprimer mon compte ?
                <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 text-base-content/40 group-open:rotate-180 transition-transform" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M19 9l-7 7-7-7" />
                </svg>
              </summary>
              <div class="px-5 pb-4 text-sm text-base-content/60 leading-relaxed">
                Oui, à tout moment depuis les paramètres de votre profil. La suppression est effective après 30 jours. Pendant ce délai, vous pouvez annuler en vous reconnectant. Après 30 jours, toutes vos données sont supprimées définitivement.
              </div>
            </details>
          </div>
        </div>
      </section>

      <!-- CTA Section -->
      <section class="py-16 sm:py-24 px-4">
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
