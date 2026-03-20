defmodule MonAppWeb.AdminSettingsLive do
  use MonAppWeb, :live_view

  import Ecto.Query

  alias MonApp.Accounts
  alias MonApp.Admin
  alias MonApp.Social
  alias MonApp.Repo

  @impl true
  def mount(_params, _session, socket) do
    current_user = socket.assigns.current_admin

    pending_reports_count =
      Social.report_stats_by_status() |> Map.get("pending", 0)

    {:ok,
     socket
     |> assign(:page_title, "Paramètres")
     |> assign(:current_path, "/admin/settings")
     |> assign(:pending_reports_count, pending_reports_count)
     |> assign(:tab, "account")
     |> assign(:current_user, current_user)
     |> assign(:pw_current, "")
     |> assign(:pw_new, "")
     |> assign(:pw_confirm, "")
     |> assign(:pw_error, nil)
     |> assign(:pw_success, false)
     |> assign(:promote_email, "")
     |> assign(:promote_role, "moderator")
     |> assign(:promote_error, nil)
     |> assign(:promote_success, nil)
     |> load_admins()
     |> load_system_stats()}
  end

  @impl true
  def handle_event("set_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, :tab, tab)}
  end

  def handle_event("pw_change", params, socket) do
    {:noreply,
     socket
     |> assign(:pw_current, Map.get(params, "current", ""))
     |> assign(:pw_new, Map.get(params, "new", ""))
     |> assign(:pw_confirm, Map.get(params, "confirm", ""))
     |> assign(:pw_error, nil)
     |> assign(:pw_success, false)}
  end

  def handle_event("change_password", %{"current" => current, "new" => new_pw, "confirm" => confirm}, socket) do
    user = socket.assigns.current_user

    cond do
      !Bcrypt.verify_pass(current, user.password_hash) ->
        {:noreply, assign(socket, :pw_error, "Mot de passe actuel incorrect")}

      String.length(new_pw) < 6 ->
        {:noreply, assign(socket, :pw_error, "Le nouveau mot de passe doit contenir au moins 6 caractères")}

      new_pw != confirm ->
        {:noreply, assign(socket, :pw_error, "Les mots de passe ne correspondent pas")}

      true ->
        case Accounts.admin_change_password(user, new_pw) do
          {:ok, _} ->
            Admin.log_action(user.id, "change_own_password")

            {:noreply,
             socket
             |> assign(:pw_success, true)
             |> assign(:pw_error, nil)
             |> assign(:pw_current, "")
             |> assign(:pw_new, "")
             |> assign(:pw_confirm, "")}

          {:error, _} ->
            {:noreply, assign(socket, :pw_error, "Erreur lors de la mise à jour")}
        end
    end
  end

  def handle_event("promote_change", params, socket) do
    {:noreply,
     socket
     |> assign(:promote_email, Map.get(params, "email", ""))
     |> assign(:promote_role, Map.get(params, "role", "moderator"))
     |> assign(:promote_error, nil)
     |> assign(:promote_success, nil)}
  end

  def handle_event("promote_user", %{"email" => email, "role" => role}, socket) do
    admin = socket.assigns.current_user

    if admin.role != "admin" do
      {:noreply, assign(socket, :promote_error, "Seul un super-admin peut promouvoir des utilisateurs")}
    else
      case Accounts.get_user_by_email(String.trim(email)) do
        nil ->
          {:noreply, assign(socket, :promote_error, "Aucun utilisateur trouvé avec cet email")}

        user when user.id == admin.id ->
          {:noreply, assign(socket, :promote_error, "Vous ne pouvez pas modifier votre propre rôle ici")}

        user ->
          case Accounts.update_user_role(user, role) do
            {:ok, updated} ->
              Admin.log_action(admin.id, "promote_user",
                target_type: "user",
                target_id: updated.id,
                metadata: %{role: role}
              )

              {:noreply,
               socket
               |> assign(:promote_success, "#{user.name} est maintenant #{role_label(role)}")
               |> assign(:promote_error, nil)
               |> assign(:promote_email, "")
               |> load_admins()}

            {:error, _} ->
              {:noreply, assign(socket, :promote_error, "Erreur lors de la mise à jour du rôle")}
          end
      end
    end
  end

  def handle_event("demote", %{"id" => id}, socket) do
    admin = socket.assigns.current_user

    if admin.role != "admin" do
      {:noreply, socket}
    else
      user = Accounts.get_user(String.to_integer(id))

      if user && user.id != admin.id do
        {:ok, _} = Accounts.update_user_role(user, "user")

        Admin.log_action(admin.id, "demote_user",
          target_type: "user",
          target_id: user.id
        )

        {:noreply, load_admins(socket)}
      else
        {:noreply, socket}
      end
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <!-- Tabs -->
    <div class="flex gap-1 mb-6 border-b border-gray-200">
      <.tab_btn label="Mon compte" tab="account" current={@tab} icon="hero-user-circle" />
      <.tab_btn label="Équipe admin" tab="team" current={@tab} icon="hero-shield-check" />
      <.tab_btn label="Système" tab="system" current={@tab} icon="hero-server" />
    </div>

    <!-- TAB: Mon compte -->
    <div :if={@tab == "account"} class="max-w-lg">
      <div class="bg-white rounded-xl border border-gray-200 p-6 mb-6">
        <h2 class="text-base font-semibold text-gray-900 mb-1">Profil</h2>
        <p class="text-sm text-gray-500 mb-4">Informations de votre compte admin</p>
        <div class="flex items-center gap-4 p-4 bg-gray-50 rounded-lg">
          <div class="w-12 h-12 rounded-full bg-pink-100 flex items-center justify-center text-pink-600 font-bold text-lg">
            {String.first(@current_user.name) |> String.upcase()}
          </div>
          <div>
            <p class="font-semibold text-gray-900">{@current_user.name}</p>
            <p class="text-sm text-gray-500">{@current_user.email}</p>
            <span class={["text-xs font-semibold px-2 py-0.5 rounded-full mt-1 inline-block", role_badge_class(@current_user.role)]}>
              {role_label(@current_user.role)}
            </span>
          </div>
        </div>
      </div>

      <div class="bg-white rounded-xl border border-gray-200 p-6">
        <h2 class="text-base font-semibold text-gray-900 mb-1">Changer le mot de passe</h2>
        <p class="text-sm text-gray-500 mb-4">Minimum 6 caractères</p>

        <div :if={@pw_success} class="mb-4 p-3 bg-green-50 border border-green-200 rounded-lg text-sm text-green-700 flex items-center gap-2">
          <.icon name="hero-check-circle" class="w-4 h-4" />
          Mot de passe mis à jour avec succès
        </div>

        <div :if={@pw_error} class="mb-4 p-3 bg-red-50 border border-red-200 rounded-lg text-sm text-red-700 flex items-center gap-2">
          <.icon name="hero-exclamation-circle" class="w-4 h-4" />
          {@pw_error}
        </div>

        <form phx-submit="change_password" phx-change="pw_change" class="space-y-4">
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">Mot de passe actuel</label>
            <input
              type="password"
              name="current"
              value={@pw_current}
              class="w-full px-3 py-2 text-sm border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-pink-500 focus:border-transparent"
              placeholder="••••••••"
              autocomplete="current-password"
            />
          </div>
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">Nouveau mot de passe</label>
            <input
              type="password"
              name="new"
              value={@pw_new}
              class="w-full px-3 py-2 text-sm border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-pink-500 focus:border-transparent"
              placeholder="••••••••"
              autocomplete="new-password"
            />
          </div>
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">Confirmer le nouveau mot de passe</label>
            <input
              type="password"
              name="confirm"
              value={@pw_confirm}
              class="w-full px-3 py-2 text-sm border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-pink-500 focus:border-transparent"
              placeholder="••••••••"
              autocomplete="new-password"
            />
          </div>
          <button
            type="submit"
            class="w-full py-2 px-4 bg-pink-600 hover:bg-pink-700 text-white text-sm font-semibold rounded-lg transition-colors"
          >
            Mettre à jour le mot de passe
          </button>
        </form>
      </div>
    </div>

    <!-- TAB: Équipe admin -->
    <div :if={@tab == "team"}>
      <!-- Promote form -->
      <div class="bg-white rounded-xl border border-gray-200 p-6 mb-6 max-w-lg">
        <h2 class="text-base font-semibold text-gray-900 mb-1">Promouvoir un utilisateur</h2>
        <p class="text-sm text-gray-500 mb-4">Accorder un rôle admin ou modérateur à un utilisateur existant</p>

        <div :if={@current_user.role != "admin"} class="p-3 bg-yellow-50 border border-yellow-200 rounded-lg text-sm text-yellow-700 mb-4">
          Seul un super-admin peut promouvoir des utilisateurs.
        </div>

        <div :if={@promote_success} class="mb-4 p-3 bg-green-50 border border-green-200 rounded-lg text-sm text-green-700 flex items-center gap-2">
          <.icon name="hero-check-circle" class="w-4 h-4" />
          {@promote_success}
        </div>

        <div :if={@promote_error} class="mb-4 p-3 bg-red-50 border border-red-200 rounded-lg text-sm text-red-700 flex items-center gap-2">
          <.icon name="hero-exclamation-circle" class="w-4 h-4" />
          {@promote_error}
        </div>

        <form phx-submit="promote_user" phx-change="promote_change" class="space-y-3">
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">Email de l'utilisateur</label>
            <input
              type="email"
              name="email"
              value={@promote_email}
              class="w-full px-3 py-2 text-sm border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-pink-500 focus:border-transparent"
              placeholder="user@example.com"
            />
          </div>
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">Rôle</label>
            <select
              name="role"
              class="w-full px-3 py-2 text-sm border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-pink-500"
            >
              <option value="moderator" selected={@promote_role == "moderator"}>Modérateur</option>
              <option value="admin" selected={@promote_role == "admin"}>Admin</option>
              <option value="user" selected={@promote_role == "user"}>Utilisateur (rétrograder)</option>
            </select>
          </div>
          <button
            type="submit"
            disabled={@current_user.role != "admin"}
            class="w-full py-2 px-4 bg-pink-600 hover:bg-pink-700 disabled:opacity-50 disabled:cursor-not-allowed text-white text-sm font-semibold rounded-lg transition-colors"
          >
            Appliquer
          </button>
        </form>
      </div>

      <!-- Team list -->
      <div class="bg-white rounded-xl border border-gray-200 overflow-hidden">
        <div class="px-6 py-4 border-b border-gray-100">
          <h2 class="text-base font-semibold text-gray-900">Membres de l'équipe</h2>
          <p class="text-sm text-gray-500">{length(@admins)} compte{if length(@admins) > 1, do: "s", else: ""} avec accès admin</p>
        </div>

        <div :if={@admins == []} class="py-12 text-center text-gray-400 text-sm">
          Aucun admin trouvé
        </div>

        <div class="divide-y divide-gray-100">
          <%= for user <- @admins do %>
            <div class="flex items-center gap-4 px-6 py-4">
              <div class="w-9 h-9 rounded-full bg-gray-100 flex items-center justify-center text-gray-600 font-semibold text-sm shrink-0">
                {String.first(user.name) |> String.upcase()}
              </div>
              <div class="flex-1 min-w-0">
                <div class="flex items-center gap-2">
                  <p class="font-medium text-gray-900 truncate">{user.name}</p>
                  <span :if={user.id == @current_user.id} class="text-xs text-gray-400">(vous)</span>
                </div>
                <p class="text-sm text-gray-500 truncate">{user.email}</p>
              </div>
              <div class="flex items-center gap-3 shrink-0">
                <span class={["text-xs font-semibold px-2.5 py-1 rounded-full", role_badge_class(user.role)]}>
                  {role_label(user.role)}
                </span>
                <button
                  :if={@current_user.role == "admin" && user.id != @current_user.id}
                  phx-click="demote"
                  phx-value-id={user.id}
                  data-confirm={"Rétrograder #{user.name} en utilisateur standard ?"}
                  class="text-xs text-gray-400 hover:text-red-500 transition-colors"
                  title="Rétrograder en utilisateur"
                >
                  <.icon name="hero-x-mark" class="w-4 h-4" />
                </button>
              </div>
            </div>
          <% end %>
        </div>
      </div>
    </div>

    <!-- TAB: Système -->
    <div :if={@tab == "system"}>
      <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
        <!-- Statistiques globales -->
        <div class="bg-white rounded-xl border border-gray-200 p-6">
          <h2 class="text-base font-semibold text-gray-900 mb-4 flex items-center gap-2">
            <.icon name="hero-chart-bar" class="w-4 h-4 text-gray-400" />
            Statistiques globales
          </h2>
          <div class="space-y-3">
            <.sys_row label="Utilisateurs" value={@stats.users.total} />
            <.sys_row label="Posts" value={@stats.posts.total} />
            <.sys_row label="Rapports en attente" value={@stats.reports.pending} highlight={@stats.reports.pending > 0} />
            <.sys_row label="Rapports total" value={@stats.reports.total} />
            <.sys_row label="Posts de type date" value={@stats.posts.date_posts} />
          </div>
        </div>

        <!-- Activité récente -->
        <div class="bg-white rounded-xl border border-gray-200 p-6">
          <h2 class="text-base font-semibold text-gray-900 mb-4 flex items-center gap-2">
            <.icon name="hero-clock" class="w-4 h-4 text-gray-400" />
            Activité récente (7 jours)
          </h2>
          <div class="space-y-3">
            <.sys_row label="Nouveaux utilisateurs" value={@stats.users.new_week} />
            <.sys_row label="Nouveaux posts" value={@stats.posts.new_week} />
            <.sys_row label="Nouveaux rapports" value={@recent.new_reports} />
          </div>
        </div>

        <!-- Logs d'audit récents -->
        <div class="bg-white rounded-xl border border-gray-200 overflow-hidden md:col-span-2">
          <div class="px-6 py-4 border-b border-gray-100">
            <h2 class="text-base font-semibold text-gray-900 flex items-center gap-2">
              <.icon name="hero-document-magnifying-glass" class="w-4 h-4 text-gray-400" />
              Dernières actions admin
            </h2>
          </div>
          <div :if={@audit_logs == []} class="py-10 text-center text-sm text-gray-400">
            Aucune action enregistrée
          </div>
          <div class="divide-y divide-gray-50">
            <%= for log <- @audit_logs do %>
              <div class="flex items-center gap-4 px-6 py-3 text-sm">
                <div class="w-7 h-7 rounded-full bg-gray-100 flex items-center justify-center shrink-0">
                  <.icon name="hero-bolt" class="w-3.5 h-3.5 text-gray-500" />
                </div>
                <div class="flex-1 min-w-0">
                  <span class="font-mono text-xs bg-gray-100 text-gray-700 px-1.5 py-0.5 rounded">{log.action}</span>
                  <span :if={log.target_type} class="ml-2 text-gray-500">
                    → {log.target_type} #{log.target_id}
                  </span>
                </div>
                <div class="text-right shrink-0">
                  <p class="font-medium text-gray-700">{log.admin && log.admin.name}</p>
                  <p class="text-gray-400 text-xs">{format_log_date(log.inserted_at)}</p>
                </div>
              </div>
            <% end %>
          </div>
        </div>
      </div>
    </div>
    """
  end

  # ── Subcomponents ─────────────────────────────────────────────────────────────

  attr :label, :string, required: true
  attr :tab, :string, required: true
  attr :current, :string, required: true
  attr :icon, :string, required: true

  defp tab_btn(assigns) do
    ~H"""
    <button
      phx-click="set_tab"
      phx-value-tab={@tab}
      class={[
        "flex items-center gap-2 px-4 py-2.5 text-sm font-medium border-b-2 -mb-px transition-colors",
        if(@current == @tab,
          do: "border-pink-600 text-pink-600",
          else: "border-transparent text-gray-500 hover:text-gray-700"
        )
      ]}
    >
      <.icon name={@icon} class="w-4 h-4" />
      {@label}
    </button>
    """
  end

  attr :label, :string, required: true
  attr :value, :any, required: true
  attr :highlight, :boolean, default: false

  defp sys_row(assigns) do
    ~H"""
    <div class="flex justify-between text-sm py-1">
      <span class="text-gray-600">{@label}</span>
      <span class={["font-semibold", if(@highlight, do: "text-red-600", else: "text-gray-900")]}>
        {@value}
      </span>
    </div>
    """
  end

  # ── Helpers ──────────────────────────────────────────────────────────────────

  defp load_admins(socket) do
    assign(socket, :admins, Accounts.list_admins())
  end

  defp load_system_stats(socket) do
    stats = Admin.dashboard_stats()
    audit_logs = Admin.list_audit_logs(15)

    week_ago = NaiveDateTime.add(NaiveDateTime.utc_now(), -7 * 86400)

    new_reports =
      from(r in MonApp.Social.UserReport, where: r.inserted_at >= ^week_ago)
      |> Repo.aggregate(:count, :id)

    socket
    |> assign(:stats, stats)
    |> assign(:audit_logs, audit_logs)
    |> assign(:recent, %{new_reports: new_reports})
  end

  defp role_label("admin"), do: "Admin"
  defp role_label("moderator"), do: "Modérateur"
  defp role_label("user"), do: "Utilisateur"
  defp role_label(r), do: r

  defp role_badge_class("admin"), do: "bg-pink-50 text-pink-700"
  defp role_badge_class("moderator"), do: "bg-blue-50 text-blue-700"
  defp role_badge_class(_), do: "bg-gray-100 text-gray-600"

  defp format_log_date(nil), do: "—"
  defp format_log_date(dt), do: Calendar.strftime(dt, "%d/%m %H:%M")
end
