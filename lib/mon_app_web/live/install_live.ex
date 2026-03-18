defmodule MonAppWeb.InstallLive do
  use MonAppWeb, :live_view

  def mount(params, _session, socket) do
    platform = case params["p"] do
      "android" -> "android"
      "desktop" -> "desktop"
      _ -> "iphone"
    end
    {:ok, assign(socket, :platform, platform), layout: false}
  end

  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-base-200">
      <!-- Header -->
      <nav class="bg-base-100 border-b border-base-200 sticky top-0 z-50">
        <div class="max-w-3xl mx-auto px-4 h-14 flex items-center justify-between">
          <a href="/welcome" class="flex items-center gap-2 text-base-content/50 hover:text-pink-500 transition-colors">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
              <path stroke-linecap="round" stroke-linejoin="round" d="M15 19l-7-7 7-7" />
            </svg>
            <span class="text-sm">Retour</span>
          </a>
          <div class="flex items-center gap-2">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 text-pink-500" viewBox="0 0 24 24" fill="currentColor">
              <path d="M12 21.35l-1.45-1.32C5.4 15.36 2 12.28 2 8.5 2 5.42 4.42 3 7.5 3c1.74 0 3.41.81 4.5 2.09C13.09 3.81 14.76 3 16.5 3 19.58 3 22 5.42 22 8.5c0 3.78-3.4 6.86-8.55 11.54L12 21.35z" />
            </svg>
            <span class="font-bold text-sm">Date<span class="text-pink-500">App</span></span>
          </div>
          <div class="w-16"></div>
        </div>
      </nav>

      <div class="max-w-2xl mx-auto p-4 sm:p-6 pb-20">
        <!-- Title -->
        <div class="text-center mb-8 mt-4">
          <h1 class="text-2xl sm:text-3xl font-bold">Installer DateApp</h1>
          <p class="text-base-content/50 text-sm mt-2">Installe l'app sur ton appareil pour une expérience optimale — ou reste sur le navigateur, c'est toi qui choisis !</p>
        </div>

        <!-- Platform tabs -->
        <div class="flex gap-1 bg-base-100 rounded-xl p-1 mb-6 shadow-sm">
          <button
            phx-click="switch_platform"
            phx-value-platform="iphone"
            class={"flex-1 py-2.5 px-3 rounded-lg text-sm font-medium transition-all flex items-center justify-center gap-1.5 #{if @platform == "iphone", do: "bg-pink-500 text-white shadow-sm", else: "text-base-content/50 hover:text-base-content"}"}
          >
            <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
              <path stroke-linecap="round" stroke-linejoin="round" d="M10.5 1.5H8.25A2.25 2.25 0 006 3.75v16.5a2.25 2.25 0 002.25 2.25h7.5A2.25 2.25 0 0018 20.25V3.75a2.25 2.25 0 00-2.25-2.25H13.5m-3 0V3h3V1.5m-3 0h3m-3 18.75h3" />
            </svg>
            iPhone
          </button>
          <button
            phx-click="switch_platform"
            phx-value-platform="android"
            class={"flex-1 py-2.5 px-3 rounded-lg text-sm font-medium transition-all flex items-center justify-center gap-1.5 #{if @platform == "android", do: "bg-pink-500 text-white shadow-sm", else: "text-base-content/50 hover:text-base-content"}"}
          >
            <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
              <path stroke-linecap="round" stroke-linejoin="round" d="M10.5 1.5H8.25A2.25 2.25 0 006 3.75v16.5a2.25 2.25 0 002.25 2.25h7.5A2.25 2.25 0 0018 20.25V3.75a2.25 2.25 0 00-2.25-2.25H13.5m-3 0V3h3V1.5m-3 0h3m-3 18.75h3" />
            </svg>
            Android
          </button>
          <button
            phx-click="switch_platform"
            phx-value-platform="desktop"
            class={"flex-1 py-2.5 px-3 rounded-lg text-sm font-medium transition-all flex items-center justify-center gap-1.5 #{if @platform == "desktop", do: "bg-pink-500 text-white shadow-sm", else: "text-base-content/50 hover:text-base-content"}"}
          >
            <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
              <path stroke-linecap="round" stroke-linejoin="round" d="M9 17.25v1.007a3 3 0 01-.879 2.122L7.5 21h9l-.621-.621A3 3 0 0115 18.257V17.25m6-12V15a2.25 2.25 0 01-2.25 2.25H5.25A2.25 2.25 0 013 15V5.25m18 0A2.25 2.25 0 0018.75 3H5.25A2.25 2.25 0 003 5.25m18 0V12a2.25 2.25 0 01-2.25 2.25H5.25A2.25 2.25 0 013 12V5.25" />
            </svg>
            Desktop
          </button>
        </div>

        <!-- iPhone Instructions -->
        <div :if={@platform == "iphone"} class="space-y-4">
          <div class="bg-base-100 rounded-2xl shadow-sm overflow-hidden">
            <div class="p-5 border-b border-base-200">
              <div class="flex items-center gap-2 text-pink-500 text-xs font-bold uppercase tracking-wider mb-1">
                <svg xmlns="http://www.w3.org/2000/svg" class="h-3.5 w-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                </svg>
                Important
              </div>
              <p class="text-sm text-base-content/60">Sur iPhone, l'installation fonctionne <strong class="text-base-content">uniquement avec Safari</strong>. Chrome et Brave ne supportent pas cette fonctionnalité sur iOS.</p>
            </div>
          </div>

          <!-- Step 1 -->
          <div class="bg-base-100 rounded-2xl shadow-sm p-5">
            <div class="flex items-start gap-4">
              <div class="w-10 h-10 rounded-full bg-pink-500 text-white flex items-center justify-center text-sm font-bold shrink-0">1</div>
              <div class="flex-1">
                <h3 class="font-bold text-base mb-2">Ouvre Safari</h3>
                <p class="text-sm text-base-content/60 mb-3">Ouvre <strong>Safari</strong> (pas Brave, pas Chrome) et va sur le site DateApp.</p>
                <div class="bg-base-200/50 rounded-xl p-3 flex items-center gap-2">
                  <div class="w-8 h-8 bg-blue-500 rounded-lg flex items-center justify-center shrink-0">
                    <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                      <path stroke-linecap="round" stroke-linejoin="round" d="M21 12a9 9 0 01-9 9m9-9a9 9 0 00-9-9m9 9H3m9 9a9 9 0 01-9-9m9 9c1.657 0 3-4.03 3-9s-1.343-9-3-9m0 18c-1.657 0-3-4.03-3-9s1.343-9 3-9m-9 9a9 9 0 019-9" />
                    </svg>
                  </div>
                  <span class="text-xs text-base-content/50 font-mono">dateapp.com</span>
                </div>
              </div>
            </div>
          </div>

          <!-- Step 2 -->
          <div class="bg-base-100 rounded-2xl shadow-sm p-5">
            <div class="flex items-start gap-4">
              <div class="w-10 h-10 rounded-full bg-pink-500 text-white flex items-center justify-center text-sm font-bold shrink-0">2</div>
              <div class="flex-1">
                <h3 class="font-bold text-base mb-2">Appuie sur le bouton Partager</h3>
                <p class="text-sm text-base-content/60 mb-3">En bas de l'écran, appuie sur l'icône <strong>Partager</strong> (le carré avec une flèche vers le haut).</p>
                <div class="bg-base-200/50 rounded-xl p-4 flex items-center justify-center">
                  <div class="w-12 h-12 bg-base-300 rounded-xl flex items-center justify-center">
                    <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6 text-blue-500" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                      <path stroke-linecap="round" stroke-linejoin="round" d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-8l-4-4m0 0L8 8m4-4v12" />
                    </svg>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <!-- Step 3 -->
          <div class="bg-base-100 rounded-2xl shadow-sm p-5">
            <div class="flex items-start gap-4">
              <div class="w-10 h-10 rounded-full bg-pink-500 text-white flex items-center justify-center text-sm font-bold shrink-0">3</div>
              <div class="flex-1">
                <h3 class="font-bold text-base mb-2">Sélectionne "Sur l'écran d'accueil"</h3>
                <p class="text-sm text-base-content/60 mb-3">Fais défiler le menu vers le bas et appuie sur <strong>"Sur l'écran d'accueil"</strong>.</p>
                <div class="bg-base-200/50 rounded-xl p-3">
                  <div class="flex items-center gap-3 px-2 py-2">
                    <div class="w-7 h-7 bg-base-300 rounded-lg flex items-center justify-center shrink-0">
                      <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 text-base-content/60" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                        <path stroke-linecap="round" stroke-linejoin="round" d="M12 4v16m8-8H4" />
                      </svg>
                    </div>
                    <span class="text-sm font-medium">Sur l'écran d'accueil</span>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <!-- Step 4 -->
          <div class="bg-base-100 rounded-2xl shadow-sm p-5">
            <div class="flex items-start gap-4">
              <div class="w-10 h-10 rounded-full bg-green-500 text-white flex items-center justify-center shrink-0">
                <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M5 13l4 4L19 7" />
                </svg>
              </div>
              <div class="flex-1">
                <h3 class="font-bold text-base mb-2">Appuie sur "Ajouter"</h3>
                <p class="text-sm text-base-content/60 mb-3">L'icône DateApp apparaît sur ton écran d'accueil. Ouvre-la comme une app native — plein écran, sans barre d'adresse !</p>
                <div class="bg-base-200/50 rounded-xl p-4 flex items-center justify-center">
                  <div class="flex flex-col items-center gap-1.5">
                    <div class="w-14 h-14 bg-pink-500 rounded-2xl flex items-center justify-center shadow-md">
                      <svg xmlns="http://www.w3.org/2000/svg" class="h-7 w-7 text-white" viewBox="0 0 24 24" fill="currentColor">
                        <path d="M12 21.35l-1.45-1.32C5.4 15.36 2 12.28 2 8.5 2 5.42 4.42 3 7.5 3c1.74 0 3.41.81 4.5 2.09C13.09 3.81 14.76 3 16.5 3 19.58 3 22 5.42 22 8.5c0 3.78-3.4 6.86-8.55 11.54L12 21.35z" />
                      </svg>
                    </div>
                    <span class="text-[10px] text-base-content/50">DateApp</span>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- Android Instructions -->
        <div :if={@platform == "android"} class="space-y-4">
          <div class="bg-base-100 rounded-2xl shadow-sm p-5">
            <div class="flex items-start gap-4">
              <div class="w-10 h-10 rounded-full bg-pink-500 text-white flex items-center justify-center text-sm font-bold shrink-0">1</div>
              <div class="flex-1">
                <h3 class="font-bold text-base mb-2">Ouvre Chrome</h3>
                <p class="text-sm text-base-content/60">Ouvre <strong>Google Chrome</strong> et va sur le site DateApp.</p>
              </div>
            </div>
          </div>

          <div class="bg-base-100 rounded-2xl shadow-sm p-5">
            <div class="flex items-start gap-4">
              <div class="w-10 h-10 rounded-full bg-pink-500 text-white flex items-center justify-center text-sm font-bold shrink-0">2</div>
              <div class="flex-1">
                <h3 class="font-bold text-base mb-2">Appuie sur le menu</h3>
                <p class="text-sm text-base-content/60 mb-3">Appuie sur les <strong>3 points verticaux</strong> en haut à droite de Chrome.</p>
                <div class="bg-base-200/50 rounded-xl p-4 flex items-center justify-center">
                  <div class="w-8 h-8 bg-base-300 rounded-full flex items-center justify-center">
                    <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 text-base-content/60" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                      <path stroke-linecap="round" stroke-linejoin="round" d="M12 5v.01M12 12v.01M12 19v.01" />
                    </svg>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <div class="bg-base-100 rounded-2xl shadow-sm p-5">
            <div class="flex items-start gap-4">
              <div class="w-10 h-10 rounded-full bg-pink-500 text-white flex items-center justify-center text-sm font-bold shrink-0">3</div>
              <div class="flex-1">
                <h3 class="font-bold text-base mb-2">Sélectionne "Installer l'application"</h3>
                <p class="text-sm text-base-content/60 mb-3">Dans le menu, appuie sur <strong>"Installer l'application"</strong> ou <strong>"Ajouter à l'écran d'accueil"</strong>.</p>
                <div class="bg-base-200/50 rounded-xl p-3">
                  <div class="flex items-center gap-3 px-2 py-2">
                    <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 text-base-content/50" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                      <path stroke-linecap="round" stroke-linejoin="round" d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4" />
                    </svg>
                    <span class="text-sm font-medium">Installer l'application</span>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <div class="bg-base-100 rounded-2xl shadow-sm p-5">
            <div class="flex items-start gap-4">
              <div class="w-10 h-10 rounded-full bg-green-500 text-white flex items-center justify-center shrink-0">
                <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M5 13l4 4L19 7" />
                </svg>
              </div>
              <div class="flex-1">
                <h3 class="font-bold text-base mb-2">Confirme l'installation</h3>
                <p class="text-sm text-base-content/60">Appuie sur <strong>"Installer"</strong>. L'app DateApp apparaît dans ton tiroir d'applications et sur l'écran d'accueil.</p>
              </div>
            </div>
          </div>
        </div>

        <!-- Desktop Instructions -->
        <div :if={@platform == "desktop"} class="space-y-4">
          <div class="bg-base-100 rounded-2xl shadow-sm p-5">
            <div class="flex items-start gap-4">
              <div class="w-10 h-10 rounded-full bg-pink-500 text-white flex items-center justify-center text-sm font-bold shrink-0">1</div>
              <div class="flex-1">
                <h3 class="font-bold text-base mb-2">Ouvre Chrome ou Edge</h3>
                <p class="text-sm text-base-content/60">Va sur le site DateApp avec <strong>Google Chrome</strong> ou <strong>Microsoft Edge</strong>. (Firefox et Safari desktop ne supportent pas l'installation PWA)</p>
              </div>
            </div>
          </div>

          <div class="bg-base-100 rounded-2xl shadow-sm p-5">
            <div class="flex items-start gap-4">
              <div class="w-10 h-10 rounded-full bg-pink-500 text-white flex items-center justify-center text-sm font-bold shrink-0">2</div>
              <div class="flex-1">
                <h3 class="font-bold text-base mb-2">Clique sur l'icône d'installation</h3>
                <p class="text-sm text-base-content/60 mb-3">Dans la <strong>barre d'adresse</strong>, à droite, tu verras une petite icône d'installation (un écran avec une flèche). Clique dessus.</p>
                <div class="bg-base-200/50 rounded-xl p-3">
                  <div class="flex items-center gap-2 bg-base-100 rounded-lg px-3 py-2 border border-base-300">
                    <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 text-base-content/30" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                      <path stroke-linecap="round" stroke-linejoin="round" d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z" />
                    </svg>
                    <span class="text-xs text-base-content/40 flex-1 font-mono">dateapp.com</span>
                    <div class="w-6 h-6 bg-base-200 rounded flex items-center justify-center">
                      <svg xmlns="http://www.w3.org/2000/svg" class="h-3.5 w-3.5 text-base-content/60" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                        <path stroke-linecap="round" stroke-linejoin="round" d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4" />
                      </svg>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <div class="bg-base-100 rounded-2xl shadow-sm p-5">
            <div class="flex items-start gap-4">
              <div class="w-10 h-10 rounded-full bg-green-500 text-white flex items-center justify-center shrink-0">
                <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M5 13l4 4L19 7" />
                </svg>
              </div>
              <div class="flex-1">
                <h3 class="font-bold text-base mb-2">Clique sur "Installer"</h3>
                <p class="text-sm text-base-content/60">DateApp s'ouvre comme une application native — avec sa propre fenêtre, sans barre d'adresse. Un raccourci est ajouté à ton bureau.</p>
              </div>
            </div>
          </div>
        </div>

        <!-- Stay on web option -->
        <div class="bg-base-100 rounded-2xl shadow-sm p-5 mt-6">
          <div class="flex items-start gap-4">
            <div class="w-10 h-10 rounded-full bg-base-200 flex items-center justify-center shrink-0">
              <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 text-base-content/50" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                <path stroke-linecap="round" stroke-linejoin="round" d="M21 12a9 9 0 01-9 9m9-9a9 9 0 00-9-9m9 9H3m9 9a9 9 0 01-9-9m9 9c1.657 0 3-4.03 3-9s-1.343-9-3-9m0 18c-1.657 0-3-4.03-3-9s1.343-9 3-9m-9 9a9 9 0 019-9" />
              </svg>
            </div>
            <div class="flex-1">
              <h3 class="font-bold text-base mb-1">Tu préfères rester sur le navigateur ?</h3>
              <p class="text-sm text-base-content/60 mb-3">
                Pas de souci ! DateApp fonctionne parfaitement dans ton navigateur web.
                L'installation est optionnelle — elle offre juste une expérience plein écran et un accès plus rapide depuis ton écran d'accueil.
              </p>
              <a href="/register" class="inline-flex items-center gap-2 text-sm font-medium text-pink-500 hover:text-pink-600 transition-colors">
                Continuer sur le web
                <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M14 5l7 7m0 0l-7 7m7-7H3" />
                </svg>
              </a>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("switch_platform", %{"platform" => platform}, socket) do
    {:noreply, assign(socket, :platform, platform)}
  end
end
