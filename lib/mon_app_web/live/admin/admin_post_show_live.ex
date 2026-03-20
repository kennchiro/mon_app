defmodule MonAppWeb.AdminPostShowLive do
  use MonAppWeb, :live_view

  alias MonApp.Blog
  alias MonApp.Blog.Post
  alias MonApp.Admin

  def mount(%{"id" => id}, _session, socket) do
    post = Blog.get_post_admin(id)

    if is_nil(post) do
      {:ok,
       socket
       |> put_flash(:error, "Post introuvable")
       |> redirect(to: "/admin/posts")}
    else
      {:ok,
       socket
       |> assign(:page_title, post_title(post))
       |> assign(:current_path, "/admin/posts")
       |> assign(:pending_reports_count, 0)
       |> assign(:post, post)
       |> assign(:confirm_delete, false)
       |> assign(:confirm_delete_comment_id, nil)}
    end
  end

  # ── Visibilité ────────────────────────────────────────
  def handle_event("change_visibility", %{"visibility" => visibility}, socket) do
    case Blog.update_post_visibility(socket.assigns.post, visibility) do
      {:ok, updated} ->
        Admin.log_action(socket.assigns.current_admin.id, "update_visibility",
          target_type: "post", target_id: updated.id, metadata: %{visibility: visibility}
        )
        post = Blog.get_post_admin(updated.id)
        {:noreply, socket |> assign(:post, post) |> put_flash(:info, "Visibilité mise à jour")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Erreur")}
    end
  end

  # ── Statut date ───────────────────────────────────────
  def handle_event("change_date_status", %{"status" => status}, socket) do
    case Blog.update_date_status(socket.assigns.post, status) do
      {:ok, updated} ->
        Admin.log_action(socket.assigns.current_admin.id, "update_date_status",
          target_type: "post", target_id: updated.id, metadata: %{status: status}
        )
        post = Blog.get_post_admin(updated.id)
        {:noreply, socket |> assign(:post, post) |> put_flash(:info, "Statut mis à jour")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Erreur")}
    end
  end

  # ── Suppression post ──────────────────────────────────
  def handle_event("confirm_delete", _, socket) do
    {:noreply, assign(socket, :confirm_delete, true)}
  end

  def handle_event("cancel_delete", _, socket) do
    {:noreply, assign(socket, :confirm_delete, false)}
  end

  def handle_event("delete_post", _, socket) do
    post = socket.assigns.post

    case Blog.admin_delete_post(post) do
      {:ok, _} ->
        Admin.log_action(socket.assigns.current_admin.id, "delete_post",
          target_type: "post", target_id: post.id, metadata: %{title: post.title}
        )
        {:noreply,
         socket
         |> put_flash(:info, "Post supprimé")
         |> redirect(to: "/admin/posts")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Erreur lors de la suppression")}
    end
  end

  # ── Suppression commentaire ───────────────────────────
  def handle_event("confirm_delete_comment", %{"id" => id}, socket) do
    {:noreply, assign(socket, :confirm_delete_comment_id, String.to_integer(id))}
  end

  def handle_event("cancel_delete_comment", _, socket) do
    {:noreply, assign(socket, :confirm_delete_comment_id, nil)}
  end

  def handle_event("delete_comment", %{"id" => id}, socket) do
    comment = Blog.get_comment(String.to_integer(id))

    case Blog.admin_delete_comment(comment) do
      {:ok, _} ->
        Admin.log_action(socket.assigns.current_admin.id, "delete_comment",
          target_type: "comment", target_id: comment.id
        )
        post = Blog.get_post_admin(socket.assigns.post.id)
        {:noreply,
         socket
         |> assign(:post, post)
         |> assign(:confirm_delete_comment_id, nil)
         |> put_flash(:info, "Commentaire supprimé")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Erreur")}
    end
  end

  def render(assigns) do
    ~H"""
    <!-- Breadcrumb -->
    <div class="flex items-center gap-2 text-sm text-gray-500 mb-6">
      <.link navigate="/admin/posts" class="hover:text-pink-600 transition-colors">Posts</.link>
      <.icon name="hero-chevron-right" class="w-4 h-4" />
      <span class="text-gray-900 font-medium line-clamp-1">{post_title(@post)}</span>
    </div>

    <div class="grid grid-cols-1 xl:grid-cols-3 gap-6">
      <!-- Contenu principal -->
      <div class="xl:col-span-2 space-y-6">

        <!-- Post content -->
        <div class="bg-white rounded-xl border border-gray-200 p-6">
          <div class="flex items-start justify-between gap-4 mb-4">
            <div class="flex-1 min-w-0">
              <!-- Type badge -->
              <div class="flex items-center gap-2 mb-2">
                <span :if={@post.post_type == "date"} class="text-xs px-2 py-0.5 bg-pink-50 text-pink-700 rounded-full font-medium">
                  💝 Post de date
                </span>
                <span :if={@post.post_type != "date"} class="text-xs px-2 py-0.5 bg-gray-100 text-gray-600 rounded-full font-medium">
                  Post standard
                </span>
                <span class={["text-xs px-2 py-0.5 rounded-full font-medium", visibility_badge_class(@post.visibility)]}>
                  {Post.visibility_label(@post.visibility)}
                </span>
              </div>
              <h2 class="text-xl font-bold text-gray-900 mb-1">{post_title(@post)}</h2>
              <p class="text-sm text-gray-500">
                Par <.link navigate={"/admin/users/#{@post.user.id}"} class="font-medium text-gray-700 hover:text-pink-600">{@post.user.name}</.link>
                · {format_datetime(@post.inserted_at)}
              </p>
            </div>
          </div>

          <!-- Corps du post -->
          <div :if={@post.body} class="prose prose-sm max-w-none text-gray-700 bg-gray-50 rounded-lg p-4 mb-4">
            {String.replace(@post.body, "\n", " ")}
          </div>

          <!-- Champs spécifiques date -->
          <div :if={@post.post_type == "date"} class="grid grid-cols-2 gap-3 mb-4">
            <.detail_row icon="🗂️" label="Catégorie" value={Post.date_category_label(@post.date_category)} />
            <.detail_row icon="📍" label="Lieu" value={@post.date_location || "—"} />
            <.detail_row icon="📅" label="Date/heure" value={format_date_event(@post.date_datetime)} />
            <.detail_row icon="💰" label="Budget" value={Post.date_budget_label(@post.date_budget)} />
            <.detail_row icon="👥" label="Places" value={"#{@post.date_spots} place(s)"} />
            <.detail_row icon="👤" label="Préférence genre" value={Post.date_gender_pref_label(@post.date_gender_pref)} />
            <.detail_row :if={@post.date_age_min || @post.date_age_max} icon="🎂" label="Tranche d'âge"
              value={"#{@post.date_age_min || "?"}–#{@post.date_age_max || "?"} ans"} />
          </div>

          <!-- Images -->
          <div :if={@post.images != []} class="flex gap-2 flex-wrap">
            <img :for={img <- @post.images}
              src={"/uploads/posts/#{img.filename}"}
              class="w-24 h-24 object-cover rounded-lg border border-gray-200"
            />
          </div>

          <!-- Stats -->
          <div class="flex items-center gap-6 mt-4 pt-4 border-t border-gray-100 text-sm text-gray-500">
            <span class="flex items-center gap-1">
              <.icon name="hero-heart" class="w-4 h-4" />
              {length(@post.reactions)} réaction{if length(@post.reactions) > 1, do: "s", else: ""}
            </span>
            <span class="flex items-center gap-1">
              <.icon name="hero-chat-bubble-left" class="w-4 h-4" />
              {length(@post.comments)} commentaire{if length(@post.comments) > 1, do: "s", else: ""}
            </span>
            <span :if={@post.post_type == "date"} class="flex items-center gap-1">
              <.icon name="hero-user-plus" class="w-4 h-4" />
              {length(@post.date_applications)} candidature{if length(@post.date_applications) > 1, do: "s", else: ""}
            </span>
          </div>
        </div>

        <!-- Candidatures (posts de dates uniquement) -->
        <div :if={@post.post_type == "date" && @post.date_applications != []} class="bg-white rounded-xl border border-gray-200 overflow-hidden">
          <div class="px-6 py-4 border-b border-gray-100">
            <h3 class="font-semibold text-gray-900">Candidatures ({length(@post.date_applications)})</h3>
          </div>
          <div class="divide-y divide-gray-100">
            <div :for={app <- @post.date_applications} class="px-6 py-4 flex items-center justify-between">
              <div class="flex items-center gap-3">
                <div class="w-8 h-8 rounded-full bg-pink-100 flex items-center justify-center text-pink-600 text-sm font-semibold">
                  {String.first(app.user.name) |> String.upcase()}
                </div>
                <div>
                  <.link navigate={"/admin/users/#{app.user.id}"} class="text-sm font-medium text-gray-900 hover:text-pink-600">
                    {app.user.name}
                  </.link>
                  <p :if={app.message} class="text-xs text-gray-400 line-clamp-1">{app.message}</p>
                </div>
              </div>
              <span class={["text-xs px-2 py-1 rounded-full font-medium", app_status_class(app.status)]}>
                {app.status}
              </span>
            </div>
          </div>
        </div>

        <!-- Commentaires -->
        <div :if={@post.comments != []} class="bg-white rounded-xl border border-gray-200 overflow-hidden">
          <div class="px-6 py-4 border-b border-gray-100">
            <h3 class="font-semibold text-gray-900">Commentaires ({length(@post.comments)})</h3>
          </div>
          <div class="divide-y divide-gray-100">
            <div :for={comment <- @post.comments} class="px-6 py-4">
              <div class="flex items-start justify-between gap-3">
                <div class="flex-1 min-w-0">
                  <div class="flex items-center gap-2 mb-1">
                    <.link navigate={"/admin/users/#{comment.user.id}"} class="text-sm font-medium text-gray-900 hover:text-pink-600">
                      {comment.user.name}
                    </.link>
                    <span class="text-xs text-gray-400">{format_date(comment.inserted_at)}</span>
                    <span :if={comment.replies != []} class="text-xs text-gray-400">
                      · {length(comment.replies)} réponse(s)
                    </span>
                  </div>
                  <p class="text-sm text-gray-700">{comment.body}</p>
                </div>
                <button
                  phx-click="confirm_delete_comment"
                  phx-value-id={comment.id}
                  class="p-1.5 text-gray-400 hover:text-red-600 hover:bg-red-50 rounded-lg transition-colors shrink-0"
                  title="Supprimer ce commentaire">
                  <.icon name="hero-trash" class="w-4 h-4" />
                </button>
              </div>
              <!-- Réponses -->
              <div :if={comment.replies != []} class="ml-6 mt-3 space-y-3 pl-4 border-l-2 border-gray-100">
                <div :for={reply <- comment.replies} class="flex items-start justify-between gap-3">
                  <div class="flex-1 min-w-0">
                    <div class="flex items-center gap-2 mb-0.5">
                      <.link navigate={"/admin/users/#{reply.user.id}"} class="text-xs font-medium text-gray-800 hover:text-pink-600">
                        {reply.user.name}
                      </.link>
                      <span class="text-xs text-gray-400">{format_date(reply.inserted_at)}</span>
                    </div>
                    <p class="text-xs text-gray-600">{reply.body}</p>
                  </div>
                  <button
                    phx-click="confirm_delete_comment"
                    phx-value-id={reply.id}
                    class="p-1 text-gray-400 hover:text-red-600 hover:bg-red-50 rounded-lg transition-colors shrink-0">
                    <.icon name="hero-trash" class="w-3.5 h-3.5" />
                  </button>
                </div>
              </div>
            </div>
          </div>
        </div>

      </div>

      <!-- Sidebar actions -->
      <div class="space-y-6">

        <!-- Changer visibilité -->
        <div class="bg-white rounded-xl border border-gray-200 p-6">
          <h3 class="font-semibold text-gray-900 mb-4">Visibilité</h3>
          <select
            phx-change="change_visibility"
            name="visibility"
            class="w-full py-2 px-3 text-sm border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-pink-500"
          >
            <option value="public" selected={@post.visibility == "public"}>🌍 Public</option>
            <option value="friends" selected={@post.visibility == "friends"}>👥 Amis seulement</option>
            <option value="private" selected={@post.visibility == "private"}>🔒 Privé</option>
          </select>
        </div>

        <!-- Statut date (si post de date) -->
        <div :if={@post.post_type == "date"} class="bg-white rounded-xl border border-gray-200 p-6">
          <h3 class="font-semibold text-gray-900 mb-4">Statut de la date</h3>
          <select
            phx-change="change_date_status"
            name="status"
            class="w-full py-2 px-3 text-sm border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-pink-500"
          >
            <option value="open" selected={@post.date_status == "open"}>✅ Ouvert</option>
            <option value="full" selected={@post.date_status == "full"}>🔴 Complet</option>
            <option value="completed" selected={@post.date_status == "completed"}>✔️ Passé</option>
            <option value="cancelled" selected={@post.date_status == "cancelled"}>❌ Annulé</option>
          </select>
        </div>

        <!-- Zone danger -->
        <div class="bg-white rounded-xl border border-red-200 p-6">
          <h3 class="font-semibold text-red-700 mb-4">Zone dangereuse</h3>
          <button
            phx-click="confirm_delete"
            class="w-full flex items-center justify-center gap-2 px-4 py-2.5 text-sm text-red-700 bg-red-50 hover:bg-red-100 rounded-lg transition-colors font-medium">
            <.icon name="hero-trash" class="w-4 h-4" />
            Supprimer ce post
          </button>
        </div>

      </div>
    </div>

    <!-- Confirm delete post -->
    <div :if={@confirm_delete} class="fixed inset-0 z-50 flex items-center justify-center px-4">
      <div class="absolute inset-0 bg-black/40 backdrop-blur-sm" phx-click="cancel_delete" />
      <div class="bg-white rounded-2xl shadow-2xl p-6 max-w-sm w-full relative z-10">
        <div class="w-12 h-12 bg-red-100 rounded-full flex items-center justify-center mx-auto mb-4">
          <.icon name="hero-trash" class="w-6 h-6 text-red-600" />
        </div>
        <h3 class="text-lg font-semibold text-gray-900 text-center mb-2">Supprimer ce post ?</h3>
        <p class="text-sm text-gray-500 text-center mb-6">
          Images, commentaires et réactions seront supprimés définitivement.
        </p>
        <div class="flex gap-3">
          <button phx-click="cancel_delete" class="flex-1 py-2 px-4 text-sm border border-gray-300 rounded-lg hover:bg-gray-50 font-medium">
            Annuler
          </button>
          <button phx-click="delete_post" class="flex-1 py-2 px-4 text-sm bg-red-600 hover:bg-red-700 text-white rounded-lg font-medium">
            Supprimer
          </button>
        </div>
      </div>
    </div>

    <!-- Confirm delete comment -->
    <div :if={@confirm_delete_comment_id} class="fixed inset-0 z-50 flex items-center justify-center px-4">
      <div class="absolute inset-0 bg-black/40 backdrop-blur-sm" phx-click="cancel_delete_comment" />
      <div class="bg-white rounded-2xl shadow-2xl p-6 max-w-sm w-full relative z-10">
        <h3 class="text-lg font-semibold text-gray-900 text-center mb-2">Supprimer ce commentaire ?</h3>
        <p class="text-sm text-gray-500 text-center mb-6">Cette action est irréversible.</p>
        <div class="flex gap-3">
          <button phx-click="cancel_delete_comment" class="flex-1 py-2 px-4 text-sm border border-gray-300 rounded-lg hover:bg-gray-50 font-medium">
            Annuler
          </button>
          <button phx-click="delete_comment" phx-value-id={@confirm_delete_comment_id}
            class="flex-1 py-2 px-4 text-sm bg-red-600 hover:bg-red-700 text-white rounded-lg font-medium">
            Supprimer
          </button>
        </div>
      </div>
    </div>
    """
  end

  # ── Composants ────────────────────────────────────────
  attr :icon, :string, required: true
  attr :label, :string, required: true
  attr :value, :string, required: true

  defp detail_row(assigns) do
    ~H"""
    <div class="flex items-start gap-2 p-3 bg-gray-50 rounded-lg">
      <span class="text-base leading-5">{@icon}</span>
      <div class="min-w-0">
        <p class="text-xs text-gray-400">{@label}</p>
        <p class="text-sm font-medium text-gray-800">{@value}</p>
      </div>
    </div>
    """
  end

  # ── Helpers ───────────────────────────────────────────
  defp post_title(%Post{post_type: "date", date_title: t}) when not is_nil(t), do: t
  defp post_title(%Post{title: t}) when not is_nil(t), do: t
  defp post_title(_), do: "(sans titre)"

  defp format_date(nil), do: "—"
  defp format_date(dt), do: Calendar.strftime(dt, "%d/%m/%Y")

  defp format_datetime(nil), do: "—"
  defp format_datetime(dt), do: Calendar.strftime(dt, "%d/%m/%Y à %H:%M")

  defp format_date_event(nil), do: "—"
  defp format_date_event(dt), do: Calendar.strftime(dt, "%d/%m/%Y %H:%M")

  defp visibility_badge_class("public"), do: "bg-green-50 text-green-700"
  defp visibility_badge_class("friends"), do: "bg-blue-50 text-blue-700"
  defp visibility_badge_class(_), do: "bg-gray-100 text-gray-600"

  defp app_status_class("pending"), do: "bg-yellow-50 text-yellow-700"
  defp app_status_class("accepted"), do: "bg-green-50 text-green-700"
  defp app_status_class("rejected"), do: "bg-red-50 text-red-600"
  defp app_status_class(_), do: "bg-gray-100 text-gray-500"
end
