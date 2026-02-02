defmodule MonAppWeb.PostsLive do
  use MonAppWeb, :live_view

  alias MonApp.Blog
  alias MonApp.Blog.Post
  alias MonApp.Repo

  @topic "posts"

  # ============== LIFECYCLE ==============

  @impl true
  def mount(_params, _session, socket) do
    # S'abonner aux updates en temps réel
    if connected?(socket) do
      Phoenix.PubSub.subscribe(MonApp.PubSub, @topic)
    end

    # current_user est déjà assigné par LiveAuth
    posts = Blog.list_posts() |> Repo.preload(:user)

    {:ok,
     socket
     |> assign(:posts, posts)
     |> assign(:form, to_form(Blog.change_post(%Post{})))}
  end

  # ============== RENDER ==============

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-4xl mx-auto p-6">
      <!-- Header avec user connecté -->
      <div class="flex justify-between items-center mb-8">
        <h1 class="text-3xl font-bold">Posts en temps réel</h1>
        <div class="flex items-center gap-4">
          <span class="text-base-content/70">
            Connecté en tant que <strong>{@current_user.name}</strong>
          </span>
          <.link href={~p"/auth/logout"} method="delete" class="btn btn-ghost btn-sm">
            Déconnexion
          </.link>
        </div>
      </div>

      <!-- Formulaire de création -->
      <div class="bg-base-200 rounded-box p-6 mb-8">
        <h2 class="text-xl font-semibold mb-4">Nouveau post</h2>

        <.form for={@form} phx-submit="save" phx-change="validate" class="space-y-4">
          <div>
            <label class="label">Titre</label>
            <input
              type="text"
              name="post[title]"
              value={@form[:title].value}
              class="input input-bordered w-full"
              placeholder="Titre du post..."
              phx-debounce="300"
            />
            <span :for={msg <- @form[:title].errors} class="text-error text-sm">{elem(msg, 0)}</span>
          </div>

          <div>
            <label class="label">Contenu</label>
            <textarea
              name="post[body]"
              class="textarea textarea-bordered w-full h-32"
              placeholder="Contenu du post..."
              phx-debounce="300"
            >{@form[:body].value}</textarea>
          </div>

          <div class="flex items-center gap-2">
            <input type="checkbox" name="post[published]" class="checkbox" />
            <label>Publié</label>
          </div>

          <button type="submit" class="btn btn-primary">
            Créer le post
          </button>
        </.form>
      </div>

      <!-- Liste des posts -->
      <div class="space-y-4">
        <h2 class="text-xl font-semibold">
          Posts ({length(@posts)})
          <span class="badge badge-success badge-sm ml-2">Live</span>
        </h2>

        <div :if={@posts == []} class="text-base-content/50">
          Aucun post pour le moment.
        </div>

        <div
          :for={post <- @posts}
          id={"post-#{post.id}"}
          class="card bg-base-100 shadow-sm border border-base-300"
        >
          <div class="card-body">
            <div class="flex justify-between items-start">
              <div>
                <h3 class="card-title">{post.title}</h3>
                <!-- Auteur du post -->
                <p class="text-sm text-primary">
                  Par <strong>{post.user.name}</strong>
                </p>
              </div>
              <div class="flex gap-2">
                <span :if={post.published} class="badge badge-success">Publié</span>
                <span :if={!post.published} class="badge badge-ghost">Brouillon</span>
                <!-- Bouton supprimer visible seulement pour l'auteur -->
                <button
                  :if={post.user_id == @current_user.id}
                  phx-click="delete"
                  phx-value-id={post.id}
                  class="btn btn-ghost btn-xs text-error"
                  data-confirm="Supprimer ce post ?"
                >
                  Supprimer
                </button>
              </div>
            </div>
            <p class="text-base-content/70 mt-2">{post.body}</p>
            <div class="text-sm text-base-content/50 mt-2">
              Créé le {Calendar.strftime(post.inserted_at, "%d/%m/%Y à %H:%M")}
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  # ============== EVENTS ==============

  @impl true
  def handle_event("validate", %{"post" => post_params}, socket) do
    form =
      %Post{}
      |> Blog.change_post(post_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, :form, form)}
  end

  @impl true
  def handle_event("save", %{"post" => post_params}, socket) do
    # Utiliser le user connecté
    user = socket.assigns.current_user
    post_params = Map.put(post_params, "user_id", user.id)

    case Blog.create_post(post_params) do
      {:ok, post} ->
        # Précharger le user pour l'affichage
        post = Repo.preload(post, :user)

        # Broadcast à tous les clients
        Phoenix.PubSub.broadcast(MonApp.PubSub, @topic, {:post_created, post})

        {:noreply,
         socket
         |> put_flash(:info, "Post créé !")
         |> assign(:form, to_form(Blog.change_post(%Post{})))}

      {:error, changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    post = Blog.get_post(id)
    user = socket.assigns.current_user

    # Vérifier que l'utilisateur est l'auteur
    if post && post.user_id == user.id do
      case Blog.delete_post(post) do
        {:ok, _} ->
          Phoenix.PubSub.broadcast(MonApp.PubSub, @topic, {:post_deleted, post})
          {:noreply, put_flash(socket, :info, "Post supprimé")}

        {:error, _} ->
          {:noreply, put_flash(socket, :error, "Erreur lors de la suppression")}
      end
    else
      {:noreply, put_flash(socket, :error, "Non autorisé")}
    end
  end

  # ============== PUBSUB HANDLERS ==============

  @impl true
  def handle_info({:post_created, post}, socket) do
    # Ajouter le nouveau post en haut de la liste
    posts = [post | socket.assigns.posts]
    {:noreply, assign(socket, :posts, posts)}
  end

  @impl true
  def handle_info({:post_deleted, post}, socket) do
    # Retirer le post de la liste
    posts = Enum.reject(socket.assigns.posts, &(&1.id == post.id))
    {:noreply, assign(socket, :posts, posts)}
  end
end
