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
     |> assign(:trigger_submit, false)
     |> assign(:login_email, "")
     |> assign(:login_password, "")
     |> assign(:show_info, false)
     |> assign(:terms_accepted, false)}
  end

  def render(assigns) do
    ~H"""
    <div class="min-h-screen flex items-center justify-center bg-base-200 auth-bg px-4 py-8">
      <!-- Blobs -->
      <div class="auth-blob auth-blob-1"></div>
      <div class="auth-blob auth-blob-2"></div>
      <div class="auth-blob auth-blob-3"></div>

      <!-- Floating hearts -->
      <div class="auth-hearts-container">
        <svg class="auth-heart" style="left: 5%; width: 24px; height: 24px; animation-duration: 10s; animation-delay: 0s;" viewBox="0 0 24 24" fill="rgba(236,72,153,0.25)"><path d="M12 21.35l-1.45-1.32C5.4 15.36 2 12.28 2 8.5 2 5.42 4.42 3 7.5 3c1.74 0 3.41.81 4.5 2.09C13.09 3.81 14.76 3 16.5 3 19.58 3 22 5.42 22 8.5c0 3.78-3.4 6.86-8.55 11.54L12 21.35z"/></svg>
        <svg class="auth-heart" style="left: 18%; width: 16px; height: 16px; animation-duration: 14s; animation-delay: 2s;" viewBox="0 0 24 24" fill="rgba(244,114,182,0.3)"><path d="M12 21.35l-1.45-1.32C5.4 15.36 2 12.28 2 8.5 2 5.42 4.42 3 7.5 3c1.74 0 3.41.81 4.5 2.09C13.09 3.81 14.76 3 16.5 3 19.58 3 22 5.42 22 8.5c0 3.78-3.4 6.86-8.55 11.54L12 21.35z"/></svg>
        <svg class="auth-heart" style="left: 35%; width: 20px; height: 20px; animation-duration: 12s; animation-delay: 4s;" viewBox="0 0 24 24" fill="rgba(251,113,133,0.2)"><path d="M12 21.35l-1.45-1.32C5.4 15.36 2 12.28 2 8.5 2 5.42 4.42 3 7.5 3c1.74 0 3.41.81 4.5 2.09C13.09 3.81 14.76 3 16.5 3 19.58 3 22 5.42 22 8.5c0 3.78-3.4 6.86-8.55 11.54L12 21.35z"/></svg>
        <svg class="auth-heart" style="left: 50%; width: 14px; height: 14px; animation-duration: 16s; animation-delay: 1s;" viewBox="0 0 24 24" fill="rgba(236,72,153,0.2)"><path d="M12 21.35l-1.45-1.32C5.4 15.36 2 12.28 2 8.5 2 5.42 4.42 3 7.5 3c1.74 0 3.41.81 4.5 2.09C13.09 3.81 14.76 3 16.5 3 19.58 3 22 5.42 22 8.5c0 3.78-3.4 6.86-8.55 11.54L12 21.35z"/></svg>
        <svg class="auth-heart" style="left: 65%; width: 22px; height: 22px; animation-duration: 11s; animation-delay: 3s;" viewBox="0 0 24 24" fill="rgba(244,114,182,0.25)"><path d="M12 21.35l-1.45-1.32C5.4 15.36 2 12.28 2 8.5 2 5.42 4.42 3 7.5 3c1.74 0 3.41.81 4.5 2.09C13.09 3.81 14.76 3 16.5 3 19.58 3 22 5.42 22 8.5c0 3.78-3.4 6.86-8.55 11.54L12 21.35z"/></svg>
        <svg class="auth-heart" style="left: 80%; width: 18px; height: 18px; animation-duration: 13s; animation-delay: 5s;" viewBox="0 0 24 24" fill="rgba(251,113,133,0.3)"><path d="M12 21.35l-1.45-1.32C5.4 15.36 2 12.28 2 8.5 2 5.42 4.42 3 7.5 3c1.74 0 3.41.81 4.5 2.09C13.09 3.81 14.76 3 16.5 3 19.58 3 22 5.42 22 8.5c0 3.78-3.4 6.86-8.55 11.54L12 21.35z"/></svg>
        <svg class="auth-heart" style="left: 92%; width: 12px; height: 12px; animation-duration: 15s; animation-delay: 7s;" viewBox="0 0 24 24" fill="rgba(236,72,153,0.2)"><path d="M12 21.35l-1.45-1.32C5.4 15.36 2 12.28 2 8.5 2 5.42 4.42 3 7.5 3c1.74 0 3.41.81 4.5 2.09C13.09 3.81 14.76 3 16.5 3 19.58 3 22 5.42 22 8.5c0 3.78-3.4 6.86-8.55 11.54L12 21.35z"/></svg>
      </div>

      <div class="w-full max-w-md relative z-10">
        <!-- Header -->
        <div class="text-center mb-8">
          <div class="w-20 h-20 mx-auto bg-base-100 rounded-full flex items-center justify-center shadow-lg mb-4">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-10 w-10 text-pink-500" viewBox="0 0 24 24" fill="currentColor">
              <path d="M12 21.35l-1.45-1.32C5.4 15.36 2 12.28 2 8.5 2 5.42 4.42 3 7.5 3c1.74 0 3.41.81 4.5 2.09C13.09 3.81 14.76 3 16.5 3 19.58 3 22 5.42 22 8.5c0 3.78-3.4 6.86-8.55 11.54L12 21.35z" />
            </svg>
          </div>
          <h1 class="text-3xl font-bold text-base-content">Rejoins-nous</h1>
          <p class="text-base-content/50 mt-1">Crée ton compte et fais des rencontres</p>
        </div>

        <!-- Card -->
        <div class="bg-base-100/90 backdrop-blur-sm rounded-2xl shadow-xl p-6 sm:p-8">
          <.form
            for={@form}
            id="register-form"
            phx-change="validate"
            phx-submit="save"
            phx-trigger-action={@trigger_submit}
            action={~p"/auth/login-session"}
            method="post"
            class="space-y-4"
          >
            <!-- Hidden fields for session controller auto-login -->
            <input type="hidden" name="email" value={@login_email} />
            <input type="hidden" name="password" value={@login_password} />

            <!-- Pseudo -->
            <div>
              <label class="text-sm font-medium text-base-content/70 mb-1.5 block">Pseudo</label>
              <div class="relative">
                <span class="text-base-content/30 absolute left-3.5 top-1/2 -translate-y-1/2 text-lg font-medium">@</span>
                <input
                  type="text"
                  name="user[name]"
                  value={@form[:name].value}
                  class={"input w-full pl-11 h-12 bg-base-200/50 border border-base-300 focus:border-pink-400 focus:outline-none transition-all #{if @form[:name].errors != [], do: "border-error"}"}
                  placeholder="ton_pseudo"
                  phx-debounce="300"
                  autocomplete="username"
                  required
                />
              </div>
              <.field_error errors={@form[:name].errors} />
            </div>

            <!-- Email -->
            <div>
              <div class="flex items-center gap-1.5 mb-1.5">
                <label class="text-sm font-medium text-base-content/70">Email</label>
                <button
                  type="button"
                  phx-click="show_info_modal"
                  class="text-base-content/30 hover:text-pink-500 transition-colors"
                >
                  <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                  </svg>
                </button>
              </div>
              <div class="relative">
                <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 text-base-content/30 absolute left-3.5 top-1/2 -translate-y-1/2" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.5">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z" />
                </svg>
                <input
                  type="email"
                  name="user[email]"
                  value={@form[:email].value}
                  class={"input w-full pl-11 h-12 bg-base-200/50 border border-base-300 focus:border-pink-400 focus:outline-none transition-all #{if @form[:email].errors != [], do: "border-error"}"}
                  placeholder="ton@email.com"
                  phx-debounce="300"
                  autocomplete="email"
                  required
                />
              </div>
              <.field_error errors={@form[:email].errors} />
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
                  name="user[password]"
                  value={@form[:password].value}
                  class={"input w-full pl-11 pr-12 h-12 bg-base-200/50 border border-base-300 focus:border-pink-400 focus:outline-none transition-all #{if @form[:password].errors != [], do: "border-error"}"}
                  placeholder="6 caractères minimum"
                  phx-debounce="300"
                  autocomplete="new-password"
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
              <.field_error errors={@form[:password].errors} />
              <div :if={@form[:password].errors == [] && @form[:password].value} class="mt-2">
                <.password_strength password={@form[:password].value || ""} />
              </div>
            </div>

            <label class="flex items-start gap-2.5 mt-4 cursor-pointer">
              <input
                type="checkbox"
                name="user[terms]"
                value="true"
                checked={@terms_accepted}
                required
                class="checkbox checkbox-sm mt-0.5 shrink-0"
              />
              <span class="text-xs text-base-content/50 leading-relaxed">
                J'accepte les
                <a href="/terms" target="_blank" class="underline text-base-content/70 hover:text-pink-500">Conditions d'utilisation</a>
                et la
                <a href="/privacy" target="_blank" class="underline text-base-content/70 hover:text-pink-500">Politique de confidentialité</a>
              </span>
            </label>

            <button type="submit" class="btn w-full h-12 text-base font-semibold bg-base-content text-base-100 hover:bg-pink-500 hover:text-white border-none transition-all duration-300 mt-3">
              Créer mon compte
            </button>
          </.form>

          <p class="text-center text-base-content/50 text-sm mt-6">
            Déjà un compte ?
            <.link navigate={~p"/login"} class="font-semibold text-base-content hover:text-pink-500 transition-colors">
              Se connecter
            </.link>
          </p>
        </div>

        <p class="text-center text-base-content/30 text-xs mt-4">
          <a href="/terms" class="hover:text-base-content/50 transition-colors">CGU</a>
          <span class="mx-1">·</span>
          <a href="/privacy" class="hover:text-base-content/50 transition-colors">Confidentialité</a>
        </p>
      </div>

      <!-- Info Modal -->
      <div :if={@show_info} class="fixed inset-0 z-50 flex items-center justify-center px-4" phx-click="close_info_modal">
        <div class="absolute inset-0 bg-black/40 backdrop-blur-sm"></div>
        <div class="bg-base-100 rounded-2xl shadow-2xl p-6 max-w-sm w-full relative z-10" phx-click-away="close_info_modal">
          <div class="text-center">
            <div class="w-14 h-14 mx-auto bg-pink-500/10 rounded-full flex items-center justify-center mb-4">
              <svg xmlns="http://www.w3.org/2000/svg" class="h-7 w-7 text-pink-500" viewBox="0 0 24 24" fill="currentColor">
                <path d="M12 21.35l-1.45-1.32C5.4 15.36 2 12.28 2 8.5 2 5.42 4.42 3 7.5 3c1.74 0 3.41.81 4.5 2.09C13.09 3.81 14.76 3 16.5 3 19.58 3 22 5.42 22 8.5c0 3.78-3.4 6.86-8.55 11.54L12 21.35z" />
              </svg>
            </div>
            <h3 class="text-lg font-bold text-base-content mb-2">Un espace libre pour tous</h3>
            <p class="text-base-content/60 text-sm leading-relaxed">
              Notre plateforme est ouverte à tous. Il te suffit d'un email pour créer ton compte gratuitement et commencer à faire des rencontres. Pas de numéro de téléphone, pas de vérification compliquée — juste toi et ta curiosité.
            </p>
            <button
              type="button"
              phx-click="close_info_modal"
              class="btn btn-sm bg-base-content text-base-100 hover:bg-pink-500 hover:text-white border-none mt-5 px-6"
            >
              Compris !
            </button>
          </div>
        </div>
      </div>
    </div>
    """
  end

  attr :errors, :list, required: true

  defp field_error(assigns) do
    ~H"""
    <div :if={@errors != []} class="mt-1">
      <span :for={{msg, _} <- @errors} class="text-error text-xs">{msg}</span>
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
      <p class="text-xs text-base-content/50">
        Force : <span class={"font-medium " <> String.replace(@color, "bg-", "text-")}>{@text}</span>
      </p>
    </div>
    """
  end

  def handle_event("show_info_modal", _, socket) do
    {:noreply, assign(socket, :show_info, true)}
  end

  def handle_event("close_info_modal", _, socket) do
    {:noreply, assign(socket, :show_info, false)}
  end

  def handle_event("toggle_password", _, socket) do
    {:noreply, assign(socket, :show_password, !socket.assigns.show_password)}
  end

  def handle_event("validate", %{"user" => user_params}, socket) do
    terms = Map.get(user_params, "terms", "false") == "true"

    changeset =
      %User{}
      |> User.registration_changeset(user_params)
      |> Map.put(:action, :validate)

    {:noreply,
     socket
     |> assign(:form, to_form(changeset))
     |> assign(:terms_accepted, terms)}
  end

  def handle_event("save", %{"user" => user_params}, socket) do
    case Accounts.register_user(user_params) do
      {:ok, _user} ->
        # Auto-login : on déclenche le submit vers le session controller
        {:noreply,
         socket
         |> assign(:login_email, user_params["email"])
         |> assign(:login_password, user_params["password"])
         |> assign(:trigger_submit, true)}

      {:error, changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end
end
