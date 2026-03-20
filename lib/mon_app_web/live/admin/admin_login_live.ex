defmodule MonAppWeb.AdminLoginLive do
  use MonAppWeb, :live_view

  alias MonApp.Accounts

  def mount(_params, _session, socket) do
    {:ok, assign(socket, form: to_form(%{"email" => "", "password" => ""}), error: nil)}
  end

  def handle_event("login", %{"email" => email, "password" => password}, socket) do
    case Accounts.authenticate_user(email, password) do
      {:ok, user} when user.role in ["admin", "moderator"] ->
        {:noreply,
         socket
         |> put_flash(:info, "Bienvenue #{user.name}")
         |> redirect(to: "/admin/session?user_id=#{user.id}")}

      {:ok, _user} ->
        {:noreply, assign(socket, error: "Accès non autorisé — compte admin requis")}

      {:error, _} ->
        {:noreply, assign(socket, error: "Email ou mot de passe invalide")}
    end
  end

  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gray-900 flex items-center justify-center px-4">
      <div class="w-full max-w-sm">
        <!-- Logo -->
        <div class="text-center mb-8">
          <div class="inline-flex w-12 h-12 bg-pink-500 rounded-xl items-center justify-center mb-4">
            <span class="text-white font-bold text-xl">D</span>
          </div>
          <h1 class="text-2xl font-bold text-white">Administration</h1>
          <p class="text-gray-400 text-sm mt-1">DateApp</p>
        </div>

        <!-- Card -->
        <div class="bg-white rounded-2xl shadow-xl p-8">
          <h2 class="text-lg font-semibold text-gray-900 mb-6">Connexion admin</h2>

          <div :if={@error} class="mb-4 p-3 bg-red-50 border border-red-200 rounded-lg text-sm text-red-700">
            {@error}
          </div>

          <.form for={@form} phx-submit="login" class="space-y-4">
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1">Email</label>
              <input
                type="email"
                name="email"
                value={@form["email"].value}
                required
                class="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-pink-500 focus:border-transparent"
                placeholder="admin@example.com"
              />
            </div>

            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1">Mot de passe</label>
              <input
                type="password"
                name="password"
                required
                class="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-pink-500 focus:border-transparent"
                placeholder="••••••••"
              />
            </div>

            <button
              type="submit"
              class="w-full bg-pink-600 hover:bg-pink-700 text-white font-medium py-2 px-4 rounded-lg text-sm transition-colors"
            >
              Se connecter
            </button>
          </.form>
        </div>

        <p class="text-center text-gray-500 text-xs mt-6">
          <.link href="/" class="hover:text-gray-300 transition-colors">← Retour à l'app</.link>
        </p>
      </div>
    </div>
    """
  end
end
