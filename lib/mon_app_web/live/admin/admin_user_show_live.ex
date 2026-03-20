defmodule MonAppWeb.AdminUserShowLive do
  use MonAppWeb, :live_view

  alias MonApp.Accounts
  alias MonApp.Admin

  def mount(%{"id" => id}, _session, socket) do
    user = Accounts.get_user!(id)
    stats = Accounts.get_user_stats(user.id)
    reports = Accounts.list_reports_against_user(user.id)

    {:ok,
     socket
     |> assign(:page_title, "#{user.name}")
     |> assign(:current_path, "/admin/users")
     |> assign(:pending_reports_count, 0)
     |> assign(:user, user)
     |> assign(:stats, stats)
     |> assign(:reports, reports)
     |> assign(:confirm_delete, false)}
  end

  def handle_event("change_role", %{"role" => role}, socket) do
    user = socket.assigns.user

    if user.id == socket.assigns.current_admin.id do
      {:noreply, put_flash(socket, :error, "Vous ne pouvez pas modifier votre propre rôle")}
    else
      case Accounts.update_user_role(user, role) do
        {:ok, updated} ->
          Admin.log_action(socket.assigns.current_admin.id, "change_role",
            target_type: "user", target_id: user.id, metadata: %{role: role}
          )
          {:noreply, socket |> assign(:user, updated) |> put_flash(:info, "Rôle mis à jour")}

        {:error, _} ->
          {:noreply, put_flash(socket, :error, "Erreur lors de la mise à jour")}
      end
    end
  end

  def handle_event("cancel_deletion", _, socket) do
    case Accounts.cancel_deletion(socket.assigns.user) do
      {:ok, updated} ->
        {:noreply, socket |> assign(:user, updated) |> put_flash(:info, "Suppression annulée")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Erreur")}
    end
  end

  def handle_event("confirm_delete", _, socket) do
    {:noreply, assign(socket, :confirm_delete, true)}
  end

  def handle_event("cancel_confirm_delete", _, socket) do
    {:noreply, assign(socket, :confirm_delete, false)}
  end

  def handle_event("delete_user", _, socket) do
    user = socket.assigns.user

    if user.id == socket.assigns.current_admin.id do
      {:noreply, put_flash(socket, :error, "Vous ne pouvez pas supprimer votre propre compte")}
    else
      case Accounts.admin_delete_user(user) do
        {:ok, _} ->
          Admin.log_action(socket.assigns.current_admin.id, "delete_user",
            target_type: "user", target_id: user.id,
            metadata: %{name: user.name, email: user.email}
          )
          {:noreply,
           socket
           |> put_flash(:info, "Utilisateur \"#{user.name}\" supprimé")
           |> redirect(to: "/admin/users")}

        {:error, _} ->
          {:noreply, put_flash(socket, :error, "Erreur lors de la suppression")}
      end
    end
  end

  def render(assigns) do
    ~H"""
    <!-- Breadcrumb -->
    <div class="flex items-center gap-2 text-sm text-gray-500 mb-6">
      <.link navigate="/admin/users" class="hover:text-pink-600 transition-colors">Utilisateurs</.link>
      <.icon name="hero-chevron-right" class="w-4 h-4" />
      <span class="text-gray-900 font-medium">{@user.name}</span>
    </div>

    <div class="grid grid-cols-1 xl:grid-cols-3 gap-6">
      <!-- Colonne principale -->
      <div class="xl:col-span-2 space-y-6">

        <!-- Profil -->
        <div class="bg-white rounded-xl border border-gray-200 p-6">
          <div class="flex items-start justify-between mb-6">
            <div class="flex items-center gap-4">
              <div class="w-16 h-16 rounded-full bg-pink-100 flex items-center justify-center text-pink-600 font-bold text-2xl">
                {String.first(@user.name) |> String.upcase()}
              </div>
              <div>
                <h2 class="text-xl font-bold text-gray-900">{@user.name}</h2>
                <p class="text-gray-500 text-sm">{@user.email}</p>
                <div class="flex items-center gap-2 mt-1">
                  <span class={["text-xs px-2 py-0.5 rounded-full font-medium", role_badge_class(@user.role)]}>
                    {@user.role}
                  </span>
                  <span :if={@user.scheduled_deletion_at} class="text-xs px-2 py-0.5 rounded-full bg-red-50 text-red-600 font-medium">
                    Suppression planifiée
                  </span>
                </div>
              </div>
            </div>

            <!-- Changer le rôle -->
            <div :if={@user.id != @current_admin.id} class="flex items-center gap-2">
              <label class="text-xs text-gray-500">Rôle :</label>
              <select
                id="user-role-select"
                phx-change="change_role"
                name="role"
                class="text-sm px-3 py-1.5 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-pink-500"
              >
                <option value="user" selected={@user.role == "user"}>Utilisateur</option>
                <option value="moderator" selected={@user.role == "moderator"}>Modérateur</option>
                <option value="admin" selected={@user.role == "admin"}>Admin</option>
              </select>
            </div>
          </div>

          <!-- Infos profil -->
          <div class="grid grid-cols-2 gap-4 text-sm">
            <.info_row label="Âge" value={if @user.age, do: "#{@user.age} ans", else: "—"} />
            <.info_row label="Genre" value={gender_label(@user.gender)} />
            <.info_row label="Localisation" value={@user.location || "—"} />
            <.info_row label="Nationalité" value={nationality_label(@user.nationality)} />
            <.info_row label="Cherche" value={looking_for_label(@user.looking_for)} />
            <.info_row label="Inscrit le" value={format_datetime(@user.inserted_at)} />
          </div>

          <div :if={@user.bio} class="mt-4 p-3 bg-gray-50 rounded-lg">
            <p class="text-xs text-gray-400 mb-1">Bio</p>
            <p class="text-sm text-gray-700">{@user.bio}</p>
          </div>

          <div :if={@user.interests != []} class="mt-4 flex flex-wrap gap-1">
            <span :for={interest <- @user.interests} class="text-xs px-2 py-1 bg-pink-50 text-pink-700 rounded-full">
              {interest}
            </span>
          </div>
        </div>

        <!-- Reports reçus -->
        <div class="bg-white rounded-xl border border-gray-200 overflow-hidden">
          <div class="px-6 py-4 border-b border-gray-100 flex items-center justify-between">
            <h3 class="font-semibold text-gray-900">Reports reçus</h3>
            <span class={[
              "text-xs px-2 py-0.5 rounded-full font-medium",
              if(@stats.reports_received > 0, do: "bg-red-50 text-red-600", else: "bg-gray-100 text-gray-500")
            ]}>
              {@stats.reports_received}
            </span>
          </div>

          <div :if={@reports == []} class="py-8 text-center text-gray-400 text-sm">
            Aucun report reçu
          </div>

          <div :if={@reports != []} class="divide-y divide-gray-100">
            <div :for={report <- @reports} class="px-6 py-4">
              <div class="flex items-start justify-between gap-4">
                <div class="flex-1 min-w-0">
                  <div class="flex items-center gap-2 mb-1">
                    <span class={["text-xs px-2 py-0.5 rounded-full font-medium", report_type_class(report.report_type)]}>
                      {report.report_type}
                    </span>
                    <span class="text-xs font-medium text-gray-700">
                      {MonApp.Social.UserReport.reason_label(report.reason)}
                    </span>
                  </div>
                  <p :if={report.details} class="text-xs text-gray-500 truncate">{report.details}</p>
                  <p class="text-xs text-gray-400 mt-1">
                    Par <span class="font-medium">{report.reporter.name}</span>
                    · {format_date(report.inserted_at)}
                  </p>
                </div>
                <span class={["text-xs px-2 py-0.5 rounded-full shrink-0", report_status_class(report.status)]}>
                  {report.status}
                </span>
              </div>
            </div>
          </div>
        </div>

      </div>

      <!-- Colonne latérale -->
      <div class="space-y-6">

        <!-- Stats -->
        <div class="bg-white rounded-xl border border-gray-200 p-6">
          <h3 class="font-semibold text-gray-900 mb-4">Statistiques</h3>
          <div class="space-y-3">
            <.stat_row icon="hero-document-text" label="Posts" value={@stats.posts} />
            <.stat_row icon="hero-users" label="Amis" value={@stats.friends} />
            <.stat_row icon="hero-flag" label="Reports reçus" value={@stats.reports_received} danger={@stats.reports_received > 3} />
            <.stat_row icon="hero-flag" label="Reports envoyés" value={@stats.reports_sent} />
          </div>
        </div>

        <!-- Actions -->
        <div class="bg-white rounded-xl border border-gray-200 p-6">
          <h3 class="font-semibold text-gray-900 mb-4">Actions</h3>
          <div class="space-y-2">

            <button
              :if={@user.scheduled_deletion_at}
              phx-click="cancel_deletion"
              class="w-full flex items-center gap-2 px-4 py-2.5 text-sm text-green-700 bg-green-50 hover:bg-green-100 rounded-lg transition-colors font-medium"
            >
              <.icon name="hero-arrow-uturn-left" class="w-4 h-4" />
              Annuler la suppression planifiée
            </button>

            <button
              :if={@user.id != @current_admin.id}
              phx-click="confirm_delete"
              class="w-full flex items-center gap-2 px-4 py-2.5 text-sm text-red-700 bg-red-50 hover:bg-red-100 rounded-lg transition-colors font-medium"
            >
              <.icon name="hero-trash" class="w-4 h-4" />
              Supprimer le compte
            </button>

          </div>
        </div>

        <!-- Infos suppression planifiée -->
        <div :if={@user.scheduled_deletion_at} class="bg-red-50 border border-red-200 rounded-xl p-4">
          <div class="flex items-start gap-3">
            <.icon name="hero-exclamation-triangle" class="w-5 h-5 text-red-500 shrink-0 mt-0.5" />
            <div>
              <p class="text-sm font-medium text-red-700">Suppression planifiée</p>
              <p class="text-xs text-red-600 mt-1">
                Le {format_datetime(@user.scheduled_deletion_at)}
                ({Accounts.days_until_deletion(@user)} jours restants)
              </p>
            </div>
          </div>
        </div>

      </div>
    </div>

    <!-- Confirm delete modal -->
    <div :if={@confirm_delete} class="fixed inset-0 z-50 flex items-center justify-center px-4">
      <div class="absolute inset-0 bg-black/40 backdrop-blur-sm" phx-click="cancel_confirm_delete" />
      <div class="bg-white rounded-2xl shadow-2xl p-6 max-w-sm w-full relative z-10">
        <div class="w-12 h-12 bg-red-100 rounded-full flex items-center justify-center mx-auto mb-4">
          <.icon name="hero-trash" class="w-6 h-6 text-red-600" />
        </div>
        <h3 class="text-lg font-semibold text-gray-900 text-center mb-2">Supprimer {@user.name} ?</h3>
        <p class="text-sm text-gray-500 text-center mb-6">
          Cette action est irréversible. Tous ses posts, messages et données seront supprimés.
        </p>
        <div class="flex gap-3">
          <button
            phx-click="cancel_confirm_delete"
            class="flex-1 py-2 px-4 text-sm border border-gray-300 rounded-lg hover:bg-gray-50 transition-colors font-medium"
          >
            Annuler
          </button>
          <button
            phx-click="delete_user"
            class="flex-1 py-2 px-4 text-sm bg-red-600 hover:bg-red-700 text-white rounded-lg transition-colors font-medium"
          >
            Supprimer
          </button>
        </div>
      </div>
    </div>
    """
  end

  # ============== COMPOSANTS ==============

  attr :label, :string, required: true
  attr :value, :string, required: true

  defp info_row(assigns) do
    ~H"""
    <div>
      <p class="text-xs text-gray-400 mb-0.5">{@label}</p>
      <p class="text-sm text-gray-800 font-medium">{@value}</p>
    </div>
    """
  end

  attr :icon, :string, required: true
  attr :label, :string, required: true
  attr :value, :integer, required: true
  attr :danger, :boolean, default: false

  defp stat_row(assigns) do
    ~H"""
    <div class="flex items-center justify-between">
      <div class="flex items-center gap-2 text-sm text-gray-600">
        <.icon name={@icon} class="w-4 h-4 text-gray-400" />
        {@label}
      </div>
      <span class={["text-sm font-semibold", if(@danger, do: "text-red-600", else: "text-gray-900")]}>
        {@value}
      </span>
    </div>
    """
  end

  # ============== HELPERS ==============

  defp format_date(nil), do: "—"
  defp format_date(dt), do: Calendar.strftime(dt, "%d/%m/%Y")

  defp format_datetime(nil), do: "—"
  defp format_datetime(dt), do: Calendar.strftime(dt, "%d/%m/%Y à %H:%M")

  defp gender_label(nil), do: "—"
  defp gender_label(g), do: MonApp.Accounts.User.gender_label(g) || g

  defp nationality_label(nil), do: "—"
  defp nationality_label(code), do: MonApp.Accounts.User.nationality_label(code) || code

  defp looking_for_label(nil), do: "—"
  defp looking_for_label(v), do: MonApp.Accounts.User.looking_for_label(v)

  defp role_badge_class("admin"), do: "bg-purple-50 text-purple-700"
  defp role_badge_class("moderator"), do: "bg-blue-50 text-blue-700"
  defp role_badge_class(_), do: "bg-gray-100 text-gray-600"

  defp report_type_class("user"), do: "bg-orange-50 text-orange-600"
  defp report_type_class("post"), do: "bg-yellow-50 text-yellow-700"
  defp report_type_class("date"), do: "bg-pink-50 text-pink-600"
  defp report_type_class(_), do: "bg-gray-100 text-gray-500"

  defp report_status_class("pending"), do: "bg-yellow-50 text-yellow-700"
  defp report_status_class("resolved"), do: "bg-green-50 text-green-700"
  defp report_status_class("dismissed"), do: "bg-gray-100 text-gray-500"
  defp report_status_class(_), do: "bg-gray-100 text-gray-500"
end
