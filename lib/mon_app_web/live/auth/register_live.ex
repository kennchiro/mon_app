defmodule MonAppWeb.RegisterLive do
  use MonAppWeb, :live_view

  alias MonApp.Accounts
  alias MonApp.Accounts.User

  def mount(_params, _session, socket) do
    changeset = Accounts.change_user(%User{})

    {:ok,
     socket
     |> assign(:form, to_form(changeset))
     |> assign(:trigger_submit, false)}
  end

  def render(assigns) do
    ~H"""
    <div class="min-h-screen flex items-center justify-center">
      <div class="card bg-base-100 shadow-xl w-full max-w-md">
        <div class="card-body">
          <h2 class="card-title text-2xl justify-center mb-4">Inscription</h2>

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
            <div>
              <label class="label">Nom</label>
              <input
                type="text"
                name="user[name]"
                value={@form[:name].value}
                class={"input input-bordered w-full #{if @form[:name].errors != [], do: "input-error"}"}
                placeholder="Votre nom"
                phx-debounce="300"
                required
              />
              <span :for={{msg, _} <- @form[:name].errors} class="text-error text-sm">{msg}</span>
            </div>

            <div>
              <label class="label">Email</label>
              <input
                type="email"
                name="user[email]"
                value={@form[:email].value}
                class={"input input-bordered w-full #{if @form[:email].errors != [], do: "input-error"}"}
                placeholder="votre@email.com"
                phx-debounce="300"
                required
              />
              <span :for={{msg, _} <- @form[:email].errors} class="text-error text-sm">{msg}</span>
            </div>

            <div>
              <label class="label">Mot de passe</label>
              <input
                type="password"
                name="user[password]"
                value={@form[:password].value}
                class={"input input-bordered w-full #{if @form[:password].errors != [], do: "input-error"}"}
                placeholder="Minimum 6 caractères"
                phx-debounce="300"
                required
              />
              <span :for={{msg, _} <- @form[:password].errors} class="text-error text-sm">{msg}</span>
            </div>

            <button type="submit" class="btn btn-primary w-full">
              S'inscrire
            </button>
          </.form>

          <div class="divider">ou</div>

          <p class="text-center">
            Déjà un compte ?
            <.link navigate={~p"/login"} class="link link-primary">
              Se connecter
            </.link>
          </p>
        </div>
      </div>
    </div>
    """
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
      {:ok, user} ->
        {:noreply,
         socket
         |> put_flash(:info, "Compte créé ! Connectez-vous.")
         |> push_navigate(to: ~p"/login")}

      {:error, changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end
end
