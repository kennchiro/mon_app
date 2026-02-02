defmodule MonAppWeb.LoginLive do
  use MonAppWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:email, "")
     |> assign(:password, "")
     |> assign(:error, nil)
     |> assign(:trigger_submit, false)}
  end

  def render(assigns) do
    ~H"""
    <div class="min-h-screen flex items-center justify-center">
      <div class="card bg-base-100 shadow-xl w-full max-w-md">
        <div class="card-body">
          <h2 class="card-title text-2xl justify-center mb-4">Connexion</h2>

          <div :if={@error} class="alert alert-error mb-4">
            {@error}
          </div>

          <form
            id="login-form"
            phx-submit="login"
            phx-trigger-action={@trigger_submit}
            action={~p"/auth/login-session"}
            method="get"
            class="space-y-4"
          >
            <div>
              <label class="label">Email</label>
              <input
                type="email"
                name="email"
                value={@email}
                class="input input-bordered w-full"
                placeholder="votre@email.com"
                phx-debounce="300"
                required
              />
            </div>

            <div>
              <label class="label">Mot de passe</label>
              <input
                type="password"
                name="password"
                value={@password}
                class="input input-bordered w-full"
                placeholder="Votre mot de passe"
                required
              />
            </div>

            <button type="submit" class="btn btn-primary w-full">
              Se connecter
            </button>
          </form>

          <div class="divider">ou</div>

          <p class="text-center">
            Pas encore de compte ?
            <.link navigate={~p"/register"} class="link link-primary">
              S'inscrire
            </.link>
          </p>
        </div>
      </div>
    </div>
    """
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
