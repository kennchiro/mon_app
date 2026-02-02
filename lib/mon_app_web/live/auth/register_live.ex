defmodule MonAppWeb.RegisterLive do
  use MonAppWeb, :live_view

  alias MonApp.Accounts
  alias MonApp.Accounts.User

  def mount(_params, _session, socket) do
    changeset = Accounts.change_user(%User{})

    {:ok,
     socket
     |> assign(:form, to_form(changeset))
     |> assign(:show_password, false)
     |> assign(:trigger_submit, false)}
  end

  def render(assigns) do
    ~H"""
    <div class="min-h-screen flex items-center justify-center bg-gradient-to-br from-base-200 to-base-300 px-4 py-8">
      <div class="card bg-base-100 shadow-2xl w-full max-w-md border border-base-200">
        <div class="card-body p-8">
          <!-- Logo/Icon -->
          <div class="flex justify-center mb-2">
            <div class="w-16 h-16 rounded-full bg-gradient-to-br from-secondary to-primary flex items-center justify-center">
              <svg xmlns="http://www.w3.org/2000/svg" class="h-8 w-8 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M18 9v3m0 0v3m0-3h3m-3 0h-3m-2-5a4 4 0 11-8 0 4 4 0 018 0zM3 20a6 6 0 0112 0v1H3v-1z" />
              </svg>
            </div>
          </div>

          <h2 class="text-2xl font-bold text-center mb-1">Créer un compte</h2>
          <p class="text-center text-base-content/60 mb-6">Rejoignez-nous dès maintenant</p>

          <.form
            for={@form}
            id="register-form"
            phx-change="validate"
            phx-submit="save"
            phx-trigger-action={@trigger_submit}
            action={~p"/auth/login-session"}
            method="post"
            class="space-y-5"
          >
            <!-- Name Input -->
            <div class="form-control">
              <label class="label pb-1">
                <span class="label-text font-medium">Nom</span>
              </label>
              <div class="relative">
                <div class="absolute inset-y-0 left-0 pl-4 flex items-center pointer-events-none">
                  <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 text-base-content/40" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
                  </svg>
                </div>
                <input
                  type="text"
                  name="user[name]"
                  value={@form[:name].value}
                  class={"input input-bordered w-full pl-12 h-12 focus:input-primary transition-all #{if @form[:name].errors != [], do: "input-error"}"}
                  placeholder="Votre nom complet"
                  phx-debounce="300"
                  autocomplete="name"
                  required
                />
                <div :if={@form[:name].errors == [] && @form[:name].value && @form[:name].value != ""} class="absolute inset-y-0 right-0 pr-4 flex items-center pointer-events-none">
                  <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 text-success" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
                  </svg>
                </div>
              </div>
              <div :if={@form[:name].errors != []} class="mt-1.5">
                <span :for={{msg, _} <- @form[:name].errors} class="text-error text-sm flex items-center gap-1">
                  <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                  </svg>
                  {msg}
                </span>
              </div>
            </div>

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
                  name="user[email]"
                  value={@form[:email].value}
                  class={"input input-bordered w-full pl-12 h-12 focus:input-primary transition-all #{if @form[:email].errors != [], do: "input-error"}"}
                  placeholder="votre@email.com"
                  phx-debounce="300"
                  autocomplete="email"
                  required
                />
                <div :if={@form[:email].errors == [] && @form[:email].value && @form[:email].value != ""} class="absolute inset-y-0 right-0 pr-4 flex items-center pointer-events-none">
                  <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 text-success" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
                  </svg>
                </div>
              </div>
              <div :if={@form[:email].errors != []} class="mt-1.5">
                <span :for={{msg, _} <- @form[:email].errors} class="text-error text-sm flex items-center gap-1">
                  <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                  </svg>
                  {msg}
                </span>
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
                  name="user[password]"
                  value={@form[:password].value}
                  class={"input input-bordered w-full pl-12 pr-12 h-12 focus:input-primary transition-all #{if @form[:password].errors != [], do: "input-error"}"}
                  placeholder="Minimum 6 caractères"
                  phx-debounce="300"
                  autocomplete="new-password"
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
              <div :if={@form[:password].errors != []} class="mt-1.5">
                <span :for={{msg, _} <- @form[:password].errors} class="text-error text-sm flex items-center gap-1">
                  <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                  </svg>
                  {msg}
                </span>
              </div>
              <div :if={@form[:password].errors == [] && @form[:password].value} class="mt-2">
                <.password_strength password={@form[:password].value || ""} />
              </div>
            </div>

            <button type="submit" class="btn btn-primary w-full h-12 text-base font-semibold shadow-lg shadow-primary/25 hover:shadow-primary/40 transition-all">
              Créer mon compte
            </button>
          </.form>

          <div class="divider text-base-content/40 my-6">ou</div>

          <p class="text-center text-base-content/70">
            Déjà un compte ?
            <.link navigate={~p"/login"} class="link link-primary font-semibold hover:link-hover">
              Se connecter
            </.link>
          </p>
        </div>
      </div>
    </div>
    """
  end

  attr :password, :string, required: true

  defp password_strength(assigns) do
    length = String.length(assigns.password)
    has_upper = Regex.match?(~r/[A-Z]/, assigns.password)
    has_lower = Regex.match?(~r/[a-z]/, assigns.password)
    has_number = Regex.match?(~r/[0-9]/, assigns.password)

    score = Enum.count([length >= 6, length >= 8, has_upper, has_lower, has_number], & &1)

    {color, text} =
      cond do
        score <= 1 -> {"bg-error", "Faible"}
        score <= 2 -> {"bg-warning", "Moyen"}
        score <= 3 -> {"bg-info", "Bon"}
        true -> {"bg-success", "Fort"}
      end

    assigns =
      assigns
      |> assign(:score, score)
      |> assign(:color, color)
      |> assign(:text, text)

    ~H"""
    <div class="space-y-1">
      <div class="flex gap-1">
        <div class={"h-1 flex-1 rounded-full transition-all " <> if @score >= 1, do: @color, else: "bg-base-300"} />
        <div class={"h-1 flex-1 rounded-full transition-all " <> if @score >= 2, do: @color, else: "bg-base-300"} />
        <div class={"h-1 flex-1 rounded-full transition-all " <> if @score >= 3, do: @color, else: "bg-base-300"} />
        <div class={"h-1 flex-1 rounded-full transition-all " <> if @score >= 4, do: @color, else: "bg-base-300"} />
      </div>
      <p class="text-xs text-base-content/60">
        Force du mot de passe : <span class={"font-medium " <> String.replace(@color, "bg-", "text-")}>{@text}</span>
      </p>
    </div>
    """
  end

  def handle_event("toggle_password", _, socket) do
    {:noreply, assign(socket, :show_password, !socket.assigns.show_password)}
  end

  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset =
      %User{}
      |> User.registration_changeset(user_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :form, to_form(changeset))}
  end

  def handle_event("save", %{"user" => user_params}, socket) do
    case Accounts.register_user(user_params) do
      {:ok, _user} ->
        {:noreply,
         socket
         |> put_flash(:info, "Compte créé ! Connectez-vous.")
         |> push_navigate(to: ~p"/login")}

      {:error, changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end
end
