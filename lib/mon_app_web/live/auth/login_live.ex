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
    <div class="min-h-screen flex items-center justify-center bg-gradient-to-br from-base-200 to-base-300 px-4">
      <div class="card bg-base-100 shadow-2xl w-full max-w-md border border-base-200">
        <div class="card-body p-8">
          <!-- Logo/Icon -->
          <div class="flex justify-center mb-2">
            <div class="w-16 h-16 rounded-full bg-gradient-to-br from-primary to-secondary flex items-center justify-center">
              <svg xmlns="http://www.w3.org/2000/svg" class="h-8 w-8 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
              </svg>
            </div>
          </div>

          <h2 class="text-2xl font-bold text-center mb-1">Bon retour !</h2>
          <p class="text-center text-base-content/60 mb-6">Connectez-vous pour continuer</p>

          <div :if={@error} class="alert alert-error mb-4 py-3">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
            </svg>
            <span>{@error}</span>
          </div>

          <form
            id="login-form"
            phx-submit="login"
            phx-trigger-action={@trigger_submit}
            action={~p"/auth/login-session"}
            method="get"
            class="space-y-5"
          >
            <!-- Email Input -->
            <div class="form-control">
              <label class="label pb-1">
                <span class="label-text font-medium">Email</span>
              </label>
              <div class="relative">
                <div class="absolute inset-y-0 left-0 pl-4 flex items-center pointer-events-none">
                  <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 text-base-content/40" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 12a4 4 0 10-8 0 4 4 0 008 0zm0 0v1.5a2.5 2.5 0 005 0V12a9 9 0 10-9 9m4.5-1.206a8.959 8.959 0 01-4.5 1.207" />
                  </svg>
                </div>
                <input
                  type="email"
                  name="email"
                  value={@email}
                  class="input input-bordered w-full pl-12 h-12 focus:input-primary transition-all"
                  placeholder="votre@email.com"
                  phx-debounce="300"
                  autocomplete="email"
                  required
                />
              </div>
            </div>

            <!-- Password Input -->
            <div class="form-control">
              <label class="label pb-1">
                <span class="label-text font-medium">Mot de passe</span>
              </label>
              <div class="relative">
                <div class="absolute inset-y-0 left-0 pl-4 flex items-center pointer-events-none">
                  <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 text-base-content/40" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z" />
                  </svg>
                </div>
                <input
                  type={if @show_password, do: "text", else: "password"}
                  name="password"
                  value={@password}
                  class="input input-bordered w-full pl-12 pr-12 h-12 focus:input-primary transition-all"
                  placeholder="Votre mot de passe"
                  autocomplete="current-password"
                  required
                />
                <button
                  type="button"
                  phx-click="toggle_password"
                  class="absolute inset-y-0 right-0 pr-4 flex items-center text-base-content/40 hover:text-base-content transition-colors"
                >
                  <svg :if={!@show_password} xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" />
                  </svg>
                  <svg :if={@show_password} xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13.875 18.825A10.05 10.05 0 0112 19c-4.478 0-8.268-2.943-9.543-7a9.97 9.97 0 011.563-3.029m5.858.908a3 3 0 114.243 4.243M9.878 9.878l4.242 4.242M9.88 9.88l-3.29-3.29m7.532 7.532l3.29 3.29M3 3l3.59 3.59m0 0A9.953 9.953 0 0112 5c4.478 0 8.268 2.943 9.543 7a10.025 10.025 0 01-4.132 5.411m0 0L21 21" />
                  </svg>
                </button>
              </div>
            </div>

            <button type="submit" class="btn btn-primary w-full h-12 text-base font-semibold shadow-lg shadow-primary/25 hover:shadow-primary/40 transition-all">
              Se connecter
            </button>
          </form>

          <div class="divider text-base-content/40 my-6">ou</div>

          <p class="text-center text-base-content/70">
            Pas encore de compte ?
            <.link navigate={~p"/register"} class="link link-primary font-semibold hover:link-hover">
              S'inscrire
            </.link>
          </p>
        </div>
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
        # Soumettre le formulaire au controller
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
