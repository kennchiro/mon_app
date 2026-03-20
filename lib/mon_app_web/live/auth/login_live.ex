defmodule MonAppWeb.LoginLive do
  use MonAppWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:email, "")
     |> assign(:password, "")
     |> assign(:error, nil)
     |> assign(:show_password, false)
     |> assign(:trigger_submit, false)}
  end

  def render(assigns) do
    ~H"""
    <div class="min-h-screen flex items-center justify-center bg-base-200 auth-bg px-4">
      <!-- Blobs -->
      <div class="auth-blob auth-blob-1"></div>
      <div class="auth-blob auth-blob-2"></div>
      <div class="auth-blob auth-blob-3"></div>

      <!-- Floating hearts -->
      <div class="auth-hearts-container">
        <svg class="auth-heart" style="left: 8%; width: 20px; height: 20px; animation-duration: 12s; animation-delay: 1s;" viewBox="0 0 24 24" fill="rgba(236,72,153,0.25)"><path d="M12 21.35l-1.45-1.32C5.4 15.36 2 12.28 2 8.5 2 5.42 4.42 3 7.5 3c1.74 0 3.41.81 4.5 2.09C13.09 3.81 14.76 3 16.5 3 19.58 3 22 5.42 22 8.5c0 3.78-3.4 6.86-8.55 11.54L12 21.35z"/></svg>
        <svg class="auth-heart" style="left: 22%; width: 16px; height: 16px; animation-duration: 15s; animation-delay: 3s;" viewBox="0 0 24 24" fill="rgba(244,114,182,0.3)"><path d="M12 21.35l-1.45-1.32C5.4 15.36 2 12.28 2 8.5 2 5.42 4.42 3 7.5 3c1.74 0 3.41.81 4.5 2.09C13.09 3.81 14.76 3 16.5 3 19.58 3 22 5.42 22 8.5c0 3.78-3.4 6.86-8.55 11.54L12 21.35z"/></svg>
        <svg class="auth-heart" style="left: 40%; width: 22px; height: 22px; animation-duration: 10s; animation-delay: 0s;" viewBox="0 0 24 24" fill="rgba(251,113,133,0.2)"><path d="M12 21.35l-1.45-1.32C5.4 15.36 2 12.28 2 8.5 2 5.42 4.42 3 7.5 3c1.74 0 3.41.81 4.5 2.09C13.09 3.81 14.76 3 16.5 3 19.58 3 22 5.42 22 8.5c0 3.78-3.4 6.86-8.55 11.54L12 21.35z"/></svg>
        <svg class="auth-heart" style="left: 58%; width: 14px; height: 14px; animation-duration: 14s; animation-delay: 5s;" viewBox="0 0 24 24" fill="rgba(236,72,153,0.2)"><path d="M12 21.35l-1.45-1.32C5.4 15.36 2 12.28 2 8.5 2 5.42 4.42 3 7.5 3c1.74 0 3.41.81 4.5 2.09C13.09 3.81 14.76 3 16.5 3 19.58 3 22 5.42 22 8.5c0 3.78-3.4 6.86-8.55 11.54L12 21.35z"/></svg>
        <svg class="auth-heart" style="left: 72%; width: 18px; height: 18px; animation-duration: 11s; animation-delay: 2s;" viewBox="0 0 24 24" fill="rgba(244,114,182,0.25)"><path d="M12 21.35l-1.45-1.32C5.4 15.36 2 12.28 2 8.5 2 5.42 4.42 3 7.5 3c1.74 0 3.41.81 4.5 2.09C13.09 3.81 14.76 3 16.5 3 19.58 3 22 5.42 22 8.5c0 3.78-3.4 6.86-8.55 11.54L12 21.35z"/></svg>
        <svg class="auth-heart" style="left: 88%; width: 12px; height: 12px; animation-duration: 16s; animation-delay: 6s;" viewBox="0 0 24 24" fill="rgba(251,113,133,0.3)"><path d="M12 21.35l-1.45-1.32C5.4 15.36 2 12.28 2 8.5 2 5.42 4.42 3 7.5 3c1.74 0 3.41.81 4.5 2.09C13.09 3.81 14.76 3 16.5 3 19.58 3 22 5.42 22 8.5c0 3.78-3.4 6.86-8.55 11.54L12 21.35z"/></svg>
      </div>

      <div class="w-full max-w-md relative z-10">
        <!-- Header -->
        <div class="text-center mb-8">
          <div class="w-20 h-20 mx-auto bg-base-100 rounded-full flex items-center justify-center shadow-lg mb-4">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-10 w-10 text-pink-500" viewBox="0 0 24 24" fill="currentColor">
              <path d="M12 21.35l-1.45-1.32C5.4 15.36 2 12.28 2 8.5 2 5.42 4.42 3 7.5 3c1.74 0 3.41.81 4.5 2.09C13.09 3.81 14.76 3 16.5 3 19.58 3 22 5.42 22 8.5c0 3.78-3.4 6.86-8.55 11.54L12 21.35z" />
            </svg>
          </div>
          <h1 class="text-3xl font-bold text-base-content">Bon retour !</h1>
          <p class="text-base-content/50 mt-1">Connecte-toi pour continuer</p>
        </div>

        <!-- Card -->
        <div class="bg-base-100/90 backdrop-blur-sm rounded-2xl shadow-xl p-6 sm:p-8">
          <div :if={@error} class="bg-error/10 text-error text-sm rounded-xl px-4 py-3 mb-5 flex items-center gap-2">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
              <path stroke-linecap="round" stroke-linejoin="round" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
            </svg>
            <span>{@error}</span>
          </div>

          <.form
            for={%{}}
            id="login-form"
            phx-submit="login"
            phx-trigger-action={@trigger_submit}
            action={~p"/auth/login-session"}
            method="post"
            class="space-y-4"
          >
            <!-- Email -->
            <div>
              <label class="text-sm font-medium text-base-content/70 mb-1.5 block">Email</label>
              <div class="relative">
                <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 text-base-content/30 absolute left-3.5 top-1/2 -translate-y-1/2" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.5">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z" />
                </svg>
                <input
                  type="email"
                  name="email"
                  value={@email}
                  class="w-full pl-11 py-3 border border-gray-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-pink-500 focus:border-transparent transition-all"
                  placeholder="ton@email.com"
                  phx-debounce="300"
                  autocomplete="email"
                  required
                />
              </div>
            </div>

            <!-- Password -->
            <div>
              <label class="text-sm font-medium text-base-content/70 mb-1.5 block">Mot de passe</label>
              <div class="relative">
                <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 text-base-content/30 absolute left-3.5 top-1/2 -translate-y-1/2" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.5">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z" />
                </svg>
                <input
                  type={if @show_password, do: "text", else: "password"}
                  name="password"
                  value={@password}
                  class="w-full pl-11 pr-12 py-3 border border-gray-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-pink-500 focus:border-transparent transition-all"
                  placeholder="Ton mot de passe"
                  autocomplete="current-password"
                  required
                />
                <button
                  type="button"
                  phx-click="toggle_password"
                  class="absolute inset-y-0 right-0 pr-3.5 flex items-center text-base-content/30 hover:text-base-content/60 transition-colors"
                >
                  <svg :if={!@show_password} xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.5">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
                    <path stroke-linecap="round" stroke-linejoin="round" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" />
                  </svg>
                  <svg :if={@show_password} xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.5">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M13.875 18.825A10.05 10.05 0 0112 19c-4.478 0-8.268-2.943-9.543-7a9.97 9.97 0 011.563-3.029m5.858.908a3 3 0 114.243 4.243M9.878 9.878l4.242 4.242M9.88 9.88l-3.29-3.29m7.532 7.532l3.29 3.29M3 3l3.59 3.59m0 0A9.953 9.953 0 0112 5c4.478 0 8.268 2.943 9.543 7a10.025 10.025 0 01-4.132 5.411m0 0L21 21" />
                  </svg>
                </button>
              </div>
            </div>

            <button type="submit" class="w-full bg-pink-600 hover:bg-pink-700 text-white font-medium py-3 px-4 rounded-lg text-sm transition-colors mt-2">
              Se connecter
            </button>
          </.form>

          <p class="text-center text-base-content/50 text-sm mt-6">
            Pas encore de compte ?
            <.link navigate={~p"/register"} class="font-semibold text-base-content hover:text-pink-500 transition-colors">
              S'inscrire
            </.link>
          </p>
        </div>

        <p class="text-center text-base-content/30 text-xs mt-4">
          <a href="/terms" class="hover:text-base-content/50 transition-colors">CGU</a>
          <span class="mx-1">·</span>
          <a href="/privacy" class="hover:text-base-content/50 transition-colors">Confidentialité</a>
        </p>
      </div>
    </div>
    """
  end

  def handle_event("toggle_password", _, socket) do
    {:noreply, assign(socket, :show_password, !socket.assigns.show_password)}
  end

  def handle_event("login", %{"email" => email, "password" => password}, socket) do
    case MonApp.Accounts.authenticate_user(email, password) do
      {:ok, _user} ->
        {:noreply,
         socket
         |> assign(:email, email)
         |> assign(:password, password)
         |> assign(:trigger_submit, true)}

      {:error, _reason} ->
        {:noreply,
         socket
         |> assign(:email, email)
         |> assign(:error, "Email ou mot de passe invalide")}
    end
  end
end
