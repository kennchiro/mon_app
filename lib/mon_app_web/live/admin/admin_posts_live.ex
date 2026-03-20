defmodule MonAppWeb.AdminPostsLive do
  use MonAppWeb, :live_view

  alias MonApp.Blog
  alias MonApp.Blog.Post
  alias MonApp.Admin

  @per_page 25

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Posts")
     |> assign(:current_path, "/admin/posts")
     |> assign(:pending_reports_count, 0)
     |> assign(:search, "")
     |> assign(:type_filter, "")
     |> assign(:visibility_filter, "")
     |> assign(:sort, "newest")
     |> assign(:page, 1)
     |> assign(:selected_ids, MapSet.new())
     |> assign(:confirm_delete_id, nil)
     |> load_posts()}
  end

  # ── Recherche / filtres ────────────────────────────────
  def handle_event("search", %{"value" => value}, socket) do
    {:noreply, socket |> assign(:search, value) |> assign(:page, 1) |> load_posts()}
  end

  def handle_event("filter_type", %{"type" => t}, socket) do
    {:noreply, socket |> assign(:type_filter, t) |> assign(:page, 1) |> load_posts()}
  end

  def handle_event("filter_visibility", %{"visibility" => v}, socket) do
    {:noreply, socket |> assign(:visibility_filter, v) |> assign(:page, 1) |> load_posts()}
  end

  def handle_event("sort", %{"by" => by}, socket) do
    {:noreply, socket |> assign(:sort, by) |> assign(:page, 1) |> load_posts()}
  end

  def handle_event("page", %{"n" => n}, socket) do
    {:noreply, socket |> assign(:page, String.to_integer(n)) |> load_posts()}
  end

  # ── Sélection multiple ────────────────────────────────
  def handle_event("toggle_select", %{"id" => id}, socket) do
    id = String.to_integer(id)
    selected = socket.assigns.selected_ids

    selected =
      if MapSet.member?(selected, id),
        do: MapSet.delete(selected, id),
        else: MapSet.put(selected, id)

    {:noreply, assign(socket, :selected_ids, selected)}
  end

  def handle_event("select_all", _, socket) do
    all_ids = socket.assigns.result.posts |> Enum.map(& &1.id) |> MapSet.new()
    {:noreply, assign(socket, :selected_ids, all_ids)}
  end

  def handle_event("deselect_all", _, socket) do
    {:noreply, assign(socket, :selected_ids, MapSet.new())}
  end

  # ── Actions sur la visibilité en bulk ─────────────────
  def handle_event("bulk_visibility", %{"visibility" => visibility}, socket) do
    ids = MapSet.to_list(socket.assigns.selected_ids)

    Enum.each(ids, fn id ->
      case Blog.get_post(id) do
        nil -> :ok
        post ->
          Blog.update_post_visibility(post, visibility)
          Admin.log_action(socket.assigns.current_admin.id, "update_visibility",
            target_type: "post", target_id: id, metadata: %{visibility: visibility}
          )
      end
    end)

    {:noreply,
     socket
     |> assign(:selected_ids, MapSet.new())
     |> put_flash(:info, "#{length(ids)} post(s) mis à jour")
     |> load_posts()}
  end

  # ── Suppression individuelle ──────────────────────────
  def handle_event("confirm_delete", %{"id" => id}, socket) do
    {:noreply, assign(socket, :confirm_delete_id, String.to_integer(id))}
  end

  def handle_event("cancel_delete", _, socket) do
    {:noreply, assign(socket, :confirm_delete_id, nil)}
  end

  def handle_event("delete_post", %{"id" => id}, socket) do
    post = Blog.get_post(String.to_integer(id))

    case Blog.admin_delete_post(post) do
      {:ok, _} ->
        Admin.log_action(socket.assigns.current_admin.id, "delete_post",
          target_type: "post", target_id: post.id, metadata: %{title: post.title}
        )
        {:noreply,
         socket
         |> assign(:confirm_delete_id, nil)
         |> put_flash(:info, "Post supprimé")
         |> load_posts()}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Erreur lors de la suppression")}
    end
  end

  # ── Suppression en bulk ───────────────────────────────
  def handle_event("bulk_delete", _, socket) do
    ids = MapSet.to_list(socket.assigns.selected_ids)

    Enum.each(ids, fn id ->
      case Blog.get_post(id) do
        nil -> :ok
        post ->
          Blog.admin_delete_post(post)
          Admin.log_action(socket.assigns.current_admin.id, "delete_post",
            target_type: "post", target_id: id
          )
      end
    end)

    {:noreply,
     socket
     |> assign(:selected_ids, MapSet.new())
     |> put_flash(:info, "#{length(ids)} post(s) supprimé(s)")
     |> load_posts()}
  end

  def render(assigns) do
    ~H"""
    <!-- Filtres -->
    <div class="bg-white rounded-xl border border-gray-200 p-4 mb-6 flex flex-wrap items-center gap-3">
      <div class="relative flex-1 min-w-56">
        <.icon name="hero-magnifying-glass" class="w-4 h-4 absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" />
        <input
          type="text"
          value={@search}
          placeholder="Rechercher par titre ou contenu…"
          phx-keyup="search"
          phx-debounce="300"
          name="value"
          class="w-full pl-9 pr-4 py-2 text-sm border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-pink-500 focus:border-transparent"
        />
      </div>

      <select phx-change="filter_type" name="type" class="py-2 pl-3 pr-8 text-sm border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-pink-500">
        <option value="" selected={@type_filter == ""}>Tous les types</option>
        <option value="standard" selected={@type_filter == "standard"}>Standard</option>
        <option value="date" selected={@type_filter == "date"}>Date</option>
      </select>

      <select phx-change="filter_visibility" name="visibility" class="py-2 pl-3 pr-8 text-sm border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-pink-500">
        <option value="" selected={@visibility_filter == ""}>Toutes visibilités</option>
        <option value="public" selected={@visibility_filter == "public"}>Public</option>
        <option value="friends" selected={@visibility_filter == "friends"}>Amis</option>
        <option value="private" selected={@visibility_filter == "private"}>Privé</option>
      </select>

      <select phx-change="sort" name="by" class="py-2 pl-3 pr-8 text-sm border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-pink-500">
        <option value="newest" selected={@sort == "newest"}>Plus récents</option>
        <option value="oldest" selected={@sort == "oldest"}>Plus anciens</option>
        <option value="title" selected={@sort == "title"}>Titre A→Z</option>
      </select>

      <span class="text-sm text-gray-500 ml-auto">
        {@result.total} post{if @result.total > 1, do: "s", else: ""}
      </span>
    </div>

    <!-- Barre d'actions bulk -->
    <div :if={MapSet.size(@selected_ids) > 0} class="bg-pink-50 border border-pink-200 rounded-xl px-4 py-3 mb-4 flex items-center gap-3 flex-wrap">
      <span class="text-sm font-medium text-pink-700">
        {MapSet.size(@selected_ids)} sélectionné(s)
      </span>
      <div class="flex items-center gap-2 ml-auto flex-wrap">
        <span class="text-xs text-gray-500">Changer visibilité :</span>
        <button phx-click="bulk_visibility" phx-value-visibility="public"
          class="text-xs px-3 py-1.5 bg-green-50 text-green-700 border border-green-200 rounded-lg hover:bg-green-100 transition-colors font-medium">
          Public
        </button>
        <button phx-click="bulk_visibility" phx-value-visibility="friends"
          class="text-xs px-3 py-1.5 bg-blue-50 text-blue-700 border border-blue-200 rounded-lg hover:bg-blue-100 transition-colors font-medium">
          Amis
        </button>
        <button phx-click="bulk_visibility" phx-value-visibility="private"
          class="text-xs px-3 py-1.5 bg-gray-50 text-gray-700 border border-gray-200 rounded-lg hover:bg-gray-100 transition-colors font-medium">
          Privé
        </button>
        <div class="w-px h-4 bg-gray-300" />
        <button phx-click="bulk_delete"
          class="text-xs px-3 py-1.5 bg-red-50 text-red-700 border border-red-200 rounded-lg hover:bg-red-100 transition-colors font-medium"
          data-confirm={"Supprimer #{MapSet.size(@selected_ids)} post(s) ?"}>
          <.icon name="hero-trash" class="w-3.5 h-3.5 inline mr-1" />Supprimer
        </button>
        <button phx-click="deselect_all"
          class="text-xs px-3 py-1.5 text-gray-500 hover:text-gray-700 transition-colors">
          Annuler
        </button>
      </div>
    </div>

    <!-- Table -->
    <div class="bg-white rounded-xl border border-gray-200 overflow-hidden mb-6">
      <table class="w-full text-sm">
        <thead class="bg-gray-50 border-b border-gray-200">
          <tr>
            <th class="px-4 py-3 w-10">
              <input
                type="checkbox"
                phx-click={if MapSet.size(@selected_ids) == length(@result.posts), do: "deselect_all", else: "select_all"}
                checked={MapSet.size(@selected_ids) == length(@result.posts) && length(@result.posts) > 0}
                class="w-4 h-4 rounded border-gray-300 accent-pink-600"
              />
            </th>
            <th class="text-left px-4 py-3 text-xs font-semibold text-gray-500 uppercase tracking-wider">Post</th>
            <th class="text-left px-4 py-3 text-xs font-semibold text-gray-500 uppercase tracking-wider">Auteur</th>
            <th class="text-left px-4 py-3 text-xs font-semibold text-gray-500 uppercase tracking-wider">Type</th>
            <th class="text-left px-4 py-3 text-xs font-semibold text-gray-500 uppercase tracking-wider">Visibilité</th>
            <th class="text-left px-4 py-3 text-xs font-semibold text-gray-500 uppercase tracking-wider">Date</th>
            <th class="text-right px-6 py-3 text-xs font-semibold text-gray-500 uppercase tracking-wider">Actions</th>
          </tr>
        </thead>
        <tbody class="divide-y divide-gray-100">
          <tr :if={@result.posts == []} class="text-center">
            <td colspan="7" class="py-12 text-gray-400 text-sm">Aucun post trouvé</td>
          </tr>
          <tr :for={post <- @result.posts}
            class={["hover:bg-gray-50 transition-colors", if(MapSet.member?(@selected_ids, post.id), do: "bg-pink-50/50", else: "")]}>
            <!-- Checkbox -->
            <td class="px-4 py-3">
              <input
                type="checkbox"
                checked={MapSet.member?(@selected_ids, post.id)}
                phx-click="toggle_select"
                phx-value-id={post.id}
                class="w-4 h-4 rounded border-gray-300 accent-pink-600"
              />
            </td>

            <!-- Titre -->
            <td class="px-4 py-4 max-w-xs">
              <.link navigate={"/admin/posts/#{post.id}"} class="font-medium text-gray-900 hover:text-pink-600 transition-colors line-clamp-1">
                {post_display_title(post)}
              </.link>
              <p :if={post.body} class="text-xs text-gray-400 line-clamp-1 mt-0.5">{post.body}</p>
            </td>

            <!-- Auteur -->
            <td class="px-4 py-4">
              <.link navigate={"/admin/users/#{post.user.id}"} class="text-sm text-gray-700 hover:text-pink-600 transition-colors">
                {post.user.name}
              </.link>
            </td>

            <!-- Type -->
            <td class="px-4 py-4">
              <span :if={post.post_type == "date"} class="inline-flex items-center gap-1 text-xs px-2 py-1 bg-pink-50 text-pink-700 rounded-full font-medium">
                💝 Date
              </span>
              <span :if={post.post_type != "date"} class="text-xs px-2 py-1 bg-gray-100 text-gray-600 rounded-full font-medium">
                Standard
              </span>
            </td>

            <!-- Visibilité -->
            <td class="px-4 py-4">
              <select
                phx-change="change_visibility"
                phx-value-id={post.id}
                name="visibility"
                class={["text-xs px-2 py-1 rounded-lg border font-medium focus:outline-none focus:ring-2 focus:ring-pink-500", visibility_select_class(post.visibility)]}
              >
                <option value="public" selected={post.visibility == "public"}>🌍 Public</option>
                <option value="friends" selected={post.visibility == "friends"}>👥 Amis</option>
                <option value="private" selected={post.visibility == "private"}>🔒 Privé</option>
              </select>
            </td>

            <!-- Date -->
            <td class="px-4 py-4 text-xs text-gray-500 whitespace-nowrap">
              {format_date(post.inserted_at)}
            </td>

            <!-- Actions -->
            <td class="px-6 py-4">
              <div class="flex items-center justify-end gap-2">
                <.link navigate={"/admin/posts/#{post.id}"}
                  class="p-1.5 text-gray-400 hover:text-pink-600 hover:bg-pink-50 rounded-lg transition-colors"
                  title="Voir le détail">
                  <.icon name="hero-eye" class="w-4 h-4" />
                </.link>
                <button
                  phx-click="confirm_delete"
                  phx-value-id={post.id}
                  class="p-1.5 text-gray-400 hover:text-red-600 hover:bg-red-50 rounded-lg transition-colors"
                  title="Supprimer">
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
      <p class="text-sm text-gray-500">Page {@result.page} sur {@result.total_pages}</p>
      <div class="flex gap-1">
        <button :if={@result.page > 1} phx-click="page" phx-value-n={@result.page - 1}
          class="px-3 py-1.5 text-sm border border-gray-300 rounded-lg hover:bg-gray-50 transition-colors">
          ← Précédent
        </button>
        <%= for n <- page_range(@result.page, @result.total_pages) do %>
          <button phx-click="page" phx-value-n={n}
            class={["px-3 py-1.5 text-sm border rounded-lg transition-colors",
              if(n == @result.page, do: "bg-pink-600 text-white border-pink-600", else: "border-gray-300 hover:bg-gray-50")]}>
            {n}
          </button>
        <% end %>
        <button :if={@result.page < @result.total_pages} phx-click="page" phx-value-n={@result.page + 1}
          class="px-3 py-1.5 text-sm border border-gray-300 rounded-lg hover:bg-gray-50 transition-colors">
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
        <h3 class="text-lg font-semibold text-gray-900 text-center mb-2">Supprimer ce post ?</h3>
        <p class="text-sm text-gray-500 text-center mb-6">
          Les images, commentaires et réactions associés seront également supprimés.
        </p>
        <div class="flex gap-3">
          <button phx-click="cancel_delete"
            class="flex-1 py-2 px-4 text-sm border border-gray-300 rounded-lg hover:bg-gray-50 transition-colors font-medium">
            Annuler
          </button>
          <button phx-click="delete_post" phx-value-id={@confirm_delete_id}
            class="flex-1 py-2 px-4 text-sm bg-red-600 hover:bg-red-700 text-white rounded-lg transition-colors font-medium">
            Supprimer
          </button>
        </div>
      </div>
    </div>
    """
  end

  # change_visibility inline dans la table
  def handle_event("change_visibility", %{"id" => id, "visibility" => visibility}, socket) do
    post = Blog.get_post(String.to_integer(id))

    case Blog.update_post_visibility(post, visibility) do
      {:ok, _} ->
        Admin.log_action(socket.assigns.current_admin.id, "update_visibility",
          target_type: "post", target_id: post.id, metadata: %{visibility: visibility}
        )
        {:noreply, socket |> put_flash(:info, "Visibilité mise à jour") |> load_posts()}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Erreur")}
    end
  end

  # ── Helpers ───────────────────────────────────────────
  defp load_posts(socket) do
    opts = [
      search: socket.assigns.search,
      post_type: socket.assigns.type_filter,
      visibility: socket.assigns.visibility_filter,
      sort: socket.assigns.sort
    ]

    result = Blog.list_posts_admin(socket.assigns.page, @per_page, opts)
    assign(socket, :result, result)
  end

  defp post_display_title(%Post{post_type: "date", date_title: t}) when not is_nil(t), do: t
  defp post_display_title(%Post{title: t}) when not is_nil(t), do: t
  defp post_display_title(_), do: "(sans titre)"

  defp format_date(nil), do: "—"
  defp format_date(dt), do: Calendar.strftime(dt, "%d/%m/%Y")

  defp visibility_select_class("public"), do: "bg-green-50 text-green-700 border-green-200"
  defp visibility_select_class("friends"), do: "bg-blue-50 text-blue-700 border-blue-200"
  defp visibility_select_class(_), do: "bg-gray-50 text-gray-600 border-gray-200"

  defp page_range(current, total) do
    Enum.to_list(max(1, current - 2)..min(total, current + 2))
  end
end
