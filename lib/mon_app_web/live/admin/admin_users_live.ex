defmodule MonAppWeb.AdminUsersLive do
  use MonAppWeb, :live_view

  alias MonApp.Accounts
  alias MonApp.Admin

  @per_page 25

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Utilisateurs")
     |> assign(:current_path, "/admin/users")
     |> assign(:pending_reports_count, 0)
     |> assign(:search, "")
     |> assign(:role_filter, "")
     |> assign(:sort, "newest")
     |> assign(:page, 1)
     |> assign(:confirm_delete_id, nil)
     |> load_users()}
  end

  def handle_event("search", %{"value" => value}, socket) do
    {:noreply,
     socket
     |> assign(:search, value)
     |> assign(:page, 1)
     |> load_users()}
  end

  def handle_event("filter_role", %{"role" => role}, socket) do
    {:noreply,
     socket
     |> assign(:role_filter, role)
     |> assign(:page, 1)
     |> load_users()}
  end

  def handle_event("sort", %{"by" => by}, socket) do
    {:noreply,
     socket
     |> assign(:sort, by)
     |> assign(:page, 1)
     |> load_users()}
  end

  def handle_event("page", %{"n" => n}, socket) do
    {:noreply,
     socket
     |> assign(:page, String.to_integer(n))
     |> load_users()}
  end

  def handle_event("change_role", %{"id" => id, "role" => role}, socket) do
    user = Accounts.get_user!(id)

    if user.id == socket.assigns.current_admin.id do
      {:noreply, put_flash(socket, :error, "Vous ne pouvez pas modifier votre propre rôle")}
    else
      case Accounts.update_user_role(user, role) do
        {:ok, _} ->
          Admin.log_action(socket.assigns.current_admin.id, "change_role",
            target_type: "user", target_id: user.id, metadata: %{role: role}
          )
          {:noreply, socket |> put_flash(:info, "Rôle mis à jour") |> load_users()}

        {:error, _} ->
          {:noreply, put_flash(socket, :error, "Erreur lors de la mise à jour")}
      end
    end
  end

  def handle_event("confirm_delete", %{"id" => id}, socket) do
    {:noreply, assign(socket, :confirm_delete_id, String.to_integer(id))}
  end

  def handle_event("cancel_delete", _, socket) do
    {:noreply, assign(socket, :confirm_delete_id, nil)}
  end

  def handle_event("delete_user", %{"id" => id}, socket) do
    user = Accounts.get_user!(id)

    if user.id == socket.assigns.current_admin.id do
      {:noreply, put_flash(socket, :error, "Vous ne pouvez pas supprimer votre propre compte")}
    else
      case Accounts.admin_delete_user(user) do
        {:ok, _} ->
          Admin.log_action(socket.assigns.current_admin.id, "delete_user",
            target_type: "user", target_id: user.id, metadata: %{name: user.name, email: user.email}
          )
          {:noreply,
           socket
           |> assign(:confirm_delete_id, nil)
           |> put_flash(:info, "Utilisateur \"#{user.name}\" supprimé")
           |> load_users()}

        {:error, _} ->
          {:noreply, put_flash(socket, :error, "Erreur lors de la suppression")}
      end
    end
  end

  def handle_event("cancel_deletion", %{"id" => id}, socket) do
    user = Accounts.get_user!(id)

    case Accounts.cancel_deletion(user) do
      {:ok, _} ->
        {:noreply, socket |> put_flash(:info, "Suppression annulée") |> load_users()}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Erreur")}
    end
  end

  def render(assigns) do
    ~H"""
    <!-- Filtres -->
    <div class="bg-white rounded-xl border border-gray-200 p-4 mb-6 flex flex-wrap items-center gap-3">
      <!-- Search -->
      <div class="relative flex-1 min-w-56">
        <.icon name="hero-magnifying-glass" class="w-4 h-4 absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" />
        <input
          type="text"
          value={@search}
          placeholder="Rechercher par nom ou email…"
          phx-keyup="search"
          phx-debounce="300"
          name="value"
          class="w-full pl-9 pr-4 py-2 text-sm border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-pink-500 focus:border-transparent"
        />
      </div>

      <!-- Role filter -->
      <select
        phx-change="filter_role"
        name="role"
        class="py-2 pl-3 pr-8 text-sm border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-pink-500"
      >
        <option value="" selected={@role_filter == ""}>Tous les rôles</option>
        <option value="user" selected={@role_filter == "user"}>Utilisateurs</option>
        <option value="moderator" selected={@role_filter == "moderator"}>Modérateurs</option>
        <option value="admin" selected={@role_filter == "admin"}>Admins</option>
      </select>

      <!-- Sort -->
      <select
        phx-change="sort"
        name="by"
        class="py-2 pl-3 pr-8 text-sm border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-pink-500"
      >
        <option value="newest" selected={@sort == "newest"}>Plus récents</option>
        <option value="oldest" selected={@sort == "oldest"}>Plus anciens</option>
        <option value="name" selected={@sort == "name"}>Nom A→Z</option>
      </select>

      <!-- Total -->
      <span class="text-sm text-gray-500 ml-auto">
        {@result.total} utilisateur{if @result.total > 1, do: "s", else: ""}
      </span>
    </div>

    <!-- Table -->
    <div class="bg-white rounded-xl border border-gray-200 overflow-hidden mb-6">
      <table class="w-full text-sm">
        <thead class="bg-gray-50 border-b border-gray-200">
          <tr>
            <th class="text-left px-6 py-3 text-xs font-semibold text-gray-500 uppercase tracking-wider">Utilisateur</th>
            <th class="text-left px-4 py-3 text-xs font-semibold text-gray-500 uppercase tracking-wider">Rôle</th>
            <th class="text-left px-4 py-3 text-xs font-semibold text-gray-500 uppercase tracking-wider">Statut</th>
            <th class="text-left px-4 py-3 text-xs font-semibold text-gray-500 uppercase tracking-wider">Inscrit le</th>
            <th class="text-right px-6 py-3 text-xs font-semibold text-gray-500 uppercase tracking-wider">Actions</th>
          </tr>
        </thead>
        <tbody class="divide-y divide-gray-100">
          <tr :if={@result.users == []} class="text-center">
            <td colspan="5" class="py-12 text-gray-400 text-sm">Aucun utilisateur trouvé</td>
          </tr>
          <tr :for={user <- @result.users} class="hover:bg-gray-50 transition-colors group">
            <!-- User info -->
            <td class="px-6 py-4">
              <div class="flex items-center gap-3">
                <div class="w-9 h-9 rounded-full bg-pink-100 flex items-center justify-center text-pink-600 font-semibold text-sm shrink-0">
                  {String.first(user.name) |> String.upcase()}
                </div>
                <div class="min-w-0">
                  <.link navigate={"/admin/users/#{user.id}"} class="font-medium text-gray-900 hover:text-pink-600 transition-colors">
                    {user.name}
                  </.link>
                  <p class="text-xs text-gray-400 truncate">{user.email}</p>
                </div>
              </div>
            </td>

            <!-- Role -->
            <td class="px-4 py-4">
              <form phx-change="change_role">
                <input type="hidden" name="id" value={user.id} />
                <select
                  id={"role-#{user.id}"}
                  name="role"
                  disabled={user.id == @current_admin.id}
                  class={[
                    "text-xs px-2 py-1 rounded-lg border font-medium focus:outline-none focus:ring-2 focus:ring-pink-500",
                    role_select_class(user.role)
                  ]}
                >
                  <option value="user" selected={user.role == "user"}>Utilisateur</option>
                  <option value="moderator" selected={user.role == "moderator"}>Modérateur</option>
                  <option value="admin" selected={user.role == "admin"}>Admin</option>
                </select>
              </form>
            </td>

            <!-- Status -->
            <td class="px-4 py-4">
              <span :if={user.scheduled_deletion_at} class="inline-flex items-center gap-1 text-xs px-2 py-1 bg-red-50 text-red-600 rounded-full font-medium">
                <.icon name="hero-clock" class="w-3 h-3" />
                Suppression planifiée
              </span>
              <span :if={!user.scheduled_deletion_at} class="inline-flex items-center gap-1 text-xs px-2 py-1 bg-green-50 text-green-600 rounded-full font-medium">
                <.icon name="hero-check-circle" class="w-3 h-3" />
                Actif
              </span>
            </td>

            <!-- Date -->
            <td class="px-4 py-4 text-xs text-gray-500">
              {format_date(user.inserted_at)}
            </td>

            <!-- Actions -->
            <td class="px-6 py-4">
              <div class="flex items-center justify-end gap-2">
                <.link
                  navigate={"/admin/users/#{user.id}"}
                  class="p-1.5 text-gray-400 hover:text-pink-600 hover:bg-pink-50 rounded-lg transition-colors"
                  title="Voir la fiche"
                >
                  <.icon name="hero-eye" class="w-4 h-4" />
                </.link>

                <button
                  :if={user.scheduled_deletion_at}
                  phx-click="cancel_deletion"
                  phx-value-id={user.id}
                  class="p-1.5 text-gray-400 hover:text-green-600 hover:bg-green-50 rounded-lg transition-colors"
                  title="Annuler la suppression"
                >
                  <.icon name="hero-arrow-uturn-left" class="w-4 h-4" />
                </button>

                <button
                  :if={user.id != @current_admin.id}
                  phx-click="confirm_delete"
                  phx-value-id={user.id}
                  class="p-1.5 text-gray-400 hover:text-red-600 hover:bg-red-50 rounded-lg transition-colors"
                  title="Supprimer"
                >
                  <.icon name="hero-trash" class="w-4 h-4" />
                </button>
              </div>
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <!-- Pagination -->
    <div :if={@result.total_pages > 1} class="flex items-center justify-between">
      <p class="text-sm text-gray-500">
        Page {@result.page} sur {@result.total_pages}
      </p>
      <div class="flex gap-1">
        <button
          :if={@result.page > 1}
          phx-click="page"
          phx-value-n={@result.page - 1}
          class="px-3 py-1.5 text-sm border border-gray-300 rounded-lg hover:bg-gray-50 transition-colors"
        >
          ← Précédent
        </button>
        <%= for n <- page_range(@result.page, @result.total_pages) do %>
          <button
            phx-click="page"
            phx-value-n={n}
            class={[
              "px-3 py-1.5 text-sm border rounded-lg transition-colors",
              if(n == @result.page,
                do: "bg-pink-600 text-white border-pink-600",
                else: "border-gray-300 hover:bg-gray-50"
              )
            ]}
          >
            {n}
          </button>
        <% end %>
        <button
          :if={@result.page < @result.total_pages}
          phx-click="page"
          phx-value-n={@result.page + 1}
          class="px-3 py-1.5 text-sm border border-gray-300 rounded-lg hover:bg-gray-50 transition-colors"
        >
          Suivant →
        </button>
      </div>
    </div>

    <!-- Confirm delete modal -->
    <div :if={@confirm_delete_id} class="fixed inset-0 z-50 flex items-center justify-center px-4">
      <div class="absolute inset-0 bg-black/40 backdrop-blur-sm" phx-click="cancel_delete" />
      <div class="bg-white rounded-2xl shadow-2xl p-6 max-w-sm w-full relative z-10">
        <div class="w-12 h-12 bg-red-100 rounded-full flex items-center justify-center mx-auto mb-4">
          <.icon name="hero-trash" class="w-6 h-6 text-red-600" />
        </div>
        <h3 class="text-lg font-semibold text-gray-900 text-center mb-2">Supprimer l'utilisateur ?</h3>
        <p class="text-sm text-gray-500 text-center mb-6">
          Cette action est irréversible. Toutes les données de l'utilisateur seront perdues.
        </p>
        <div class="flex gap-3">
          <button
            phx-click="cancel_delete"
            class="flex-1 py-2 px-4 text-sm border border-gray-300 rounded-lg hover:bg-gray-50 transition-colors font-medium"
          >
            Annuler
          </button>
          <button
            phx-click="delete_user"
            phx-value-id={@confirm_delete_id}
            class="flex-1 py-2 px-4 text-sm bg-red-600 hover:bg-red-700 text-white rounded-lg transition-colors font-medium"
          >
            Supprimer
          </button>
        </div>
      </div>
    </div>
    """
  end

  # ============== PRIVATE ==============

  defp load_users(socket) do
    opts = [
      search: socket.assigns.search,
      role: socket.assigns.role_filter,
      sort: socket.assigns.sort
    ]

    result = Accounts.list_users_paginated(socket.assigns.page, @per_page, opts)
    assign(socket, :result, result)
  end

  defp format_date(nil), do: "—"
  defp format_date(dt) do
    Calendar.strftime(dt, "%d/%m/%Y")
  end

  defp role_select_class("admin"), do: "bg-purple-50 text-purple-700 border-purple-200"
  defp role_select_class("moderator"), do: "bg-blue-50 text-blue-700 border-blue-200"
  defp role_select_class(_), do: "bg-gray-50 text-gray-600 border-gray-200"

  defp page_range(current, total) do
    start = max(1, current - 2)
    finish = min(total, current + 2)
    Enum.to_list(start..finish)
  end
end
