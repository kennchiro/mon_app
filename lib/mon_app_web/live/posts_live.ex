defmodule MonAppWeb.PostsLive do
  use MonAppWeb, :live_view

  alias MonApp.Blog
  alias MonApp.Blog.Post
  alias MonApp.Blog.Comment
  alias MonApp.Repo
  alias MonApp.Social

  import MonAppWeb.Navbar
  import MonAppWeb.PostComponents

  @topic "posts"

  # ============== LIFECYCLE ==============

  @impl true
  def mount(_params, _session, socket) do
    user_id = socket.assigns.current_user.id

    if connected?(socket) do
      Phoenix.PubSub.subscribe(MonApp.PubSub, @topic)
    end

    posts = Blog.list_posts_for_user(user_id)
    pending_count = length(Social.list_pending_requests(user_id))

    {:ok,
     socket
     |> assign(:posts, posts)
     |> assign(:pending_requests_count, pending_count)
     |> assign(:form, to_form(Blog.change_post(%Post{})))
     |> assign(:show_post_modal, false)
     |> assign(:editing_post, nil)
     |> assign(:edit_form, nil)
     |> assign(:viewing_post, nil)
     |> assign(:comment_form, nil)
     |> assign(:comment_form_id, nil)
     |> assign(:replying_to, nil)
     |> assign(:viewing_reactions_post, nil)
     |> assign(:reactions_filter, "all")
     |> assign(:friendship_statuses, %{})
     |> assign(:viewing_comment_reactions, nil)
     |> assign(:comment_reactions_filter, "all")
     |> assign(:comment_friendship_statuses, %{})
     |> assign(:preview_image, nil)
     |> allow_upload(:images,
       accept: ~w(.jpg .jpeg .png .gif .webp),
       max_entries: 20,
       max_file_size: 10_000_000
     )
     |> allow_upload(:comment_images,
       accept: ~w(.jpg .jpeg .png .gif .webp),
       max_entries: 4,
       max_file_size: 5_000_000
     )}
  end

  # ============== RENDER ==============

  @impl true
  def render(assigns) do
    # Vérifier si un modal est ouvert pour bloquer le scroll
    modal_open? = assigns.show_post_modal || assigns.editing_post || assigns.viewing_post ||
                  assigns.viewing_reactions_post || assigns.viewing_comment_reactions || assigns.preview_image
    assigns = assign(assigns, :modal_open?, modal_open?)

    ~H"""
    <div class={"min-h-screen bg-base-200 #{if @modal_open?, do: "overflow-hidden h-screen", else: ""}"}>
      <.navbar current_user={@current_user} current_path="/posts" pending_requests_count={@pending_requests_count} />

      <main class="max-w-4xl mx-auto p-6">
        <.post_form_trigger current_user={@current_user} />
        <.post_form_modal
          :if={@show_post_modal}
          form={@form}
          uploads={@uploads}
          current_user={@current_user}
        />
        <.edit_post_modal
          :if={@editing_post}
          form={@edit_form}
          uploads={@uploads}
          current_user={@current_user}
          post={@editing_post}
        />
        <.post_detail_modal
          :if={@viewing_post}
          post={@viewing_post}
          current_user={@current_user}
          comment_form={@comment_form}
          comment_form_id={@comment_form_id}
          replying_to={@replying_to}
          uploads={@uploads}
        />
        <.reactions_modal
          :if={@viewing_reactions_post}
          post={@viewing_reactions_post}
          current_user={@current_user}
          reactions={@viewing_reactions_post.reactions}
          filter={@reactions_filter}
          friendship_statuses={@friendship_statuses}
        />
        <.comment_reactions_modal
          :if={@viewing_comment_reactions}
          comment={@viewing_comment_reactions}
          current_user={@current_user}
          reactions={@viewing_comment_reactions.reactions}
          filter={@comment_reactions_filter}
          friendship_statuses={@comment_friendship_statuses}
        />
        <.image_preview_modal :if={@preview_image} src={@preview_image} />
        <.post_list posts={@posts} current_user={@current_user} />
      </main>
    </div>
    """
  end

  # ============== EVENTS ==============

  @impl true
  def handle_event("open_post_modal", _, socket) do
    {:noreply, assign(socket, :show_post_modal, true)}
  end

  @impl true
  def handle_event("close_post_modal", _, socket) do
    {:noreply,
     socket
     |> assign(:show_post_modal, false)
     |> assign(:form, to_form(Blog.change_post(%Post{})))}
  end

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
  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :images, ref)}
  end

  @impl true
  def handle_event("save", %{"post" => post_params}, socket) do
    user = socket.assigns.current_user
    post_params = Map.put(post_params, "user_id", user.id)

    case Blog.create_post(post_params) do
      {:ok, post} ->
        # Sauvegarder les images uploadées
        save_uploaded_images(socket, post.id)

        post = Repo.preload(post, [:user, :images, :comments])
        Phoenix.PubSub.broadcast(MonApp.PubSub, @topic, {:post_created, post})

        {:noreply,
         socket
         |> put_flash(:info, "Post publié !")
         |> assign(:show_post_modal, false)
         |> assign(:form, to_form(Blog.change_post(%Post{})))}

      {:error, changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    post = Blog.get_post(id)
    user = socket.assigns.current_user

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

  # ============== EDIT POST EVENTS ==============

  @impl true
  def handle_event("edit_post", %{"id" => id}, socket) do
    user = socket.assigns.current_user
    post = Blog.get_post(id) |> Repo.preload([:user, :images])

    if post && post.user_id == user.id do
      edit_form = Blog.change_post(post) |> to_form()

      {:noreply,
       socket
       |> assign(:editing_post, post)
       |> assign(:edit_form, edit_form)}
    else
      {:noreply, put_flash(socket, :error, "Non autorisé")}
    end
  end

  @impl true
  def handle_event("close_edit_modal", _, socket) do
    {:noreply,
     socket
     |> assign(:editing_post, nil)
     |> assign(:edit_form, nil)}
  end

  @impl true
  def handle_event("validate_edit", %{"post" => post_params}, socket) do
    post = socket.assigns.editing_post

    form =
      post
      |> Blog.change_post(post_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, :edit_form, form)}
  end

  @impl true
  def handle_event("update_post", %{"post" => post_params}, socket) do
    post = socket.assigns.editing_post
    user = socket.assigns.current_user

    if post && post.user_id == user.id do
      case Blog.update_post(post, post_params) do
        {:ok, updated_post} ->
          # Sauvegarder les nouvelles images
          save_uploaded_images(socket, updated_post.id)

          updated_post = Repo.preload(updated_post, [:user, :images, :comments], force: true)
          Phoenix.PubSub.broadcast(MonApp.PubSub, @topic, {:post_updated, updated_post})

          {:noreply,
           socket
           |> put_flash(:info, "Post modifié !")
           |> assign(:editing_post, nil)
           |> assign(:edit_form, nil)}

        {:error, changeset} ->
          {:noreply, assign(socket, :edit_form, to_form(changeset))}
      end
    else
      {:noreply, put_flash(socket, :error, "Non autorisé")}
    end
  end

  @impl true
  def handle_event("delete_image", %{"id" => image_id}, socket) do
    user = socket.assigns.current_user
    post = socket.assigns.editing_post

    if post && post.user_id == user.id do
      image = Blog.get_post_image(image_id)

      if image && image.post_id == post.id do
        Blog.delete_post_image(image)

        # Recharger le post avec les images à jour
        updated_post = Blog.get_post(post.id) |> Repo.preload([:user, :images])

        {:noreply, assign(socket, :editing_post, updated_post)}
      else
        {:noreply, put_flash(socket, :error, "Image non trouvée")}
      end
    else
      {:noreply, put_flash(socket, :error, "Non autorisé")}
    end
  end

  # ============== REACTION EVENTS ==============

  @impl true
  def handle_event("toggle_reaction", %{"post-id" => post_id, "type" => reaction_type}, socket) do
    user = socket.assigns.current_user
    post_id_int = String.to_integer(post_id)

    case Blog.toggle_reaction(user.id, post_id_int, reaction_type) do
      {:ok, _result} ->
        # Recharger les réactions du post
        updated_posts = update_post_reactions(socket.assigns.posts, post_id_int)

        # Mettre à jour viewing_post si le modal est ouvert
        socket = assign(socket, :posts, updated_posts)
        socket = if socket.assigns.viewing_post && socket.assigns.viewing_post.id == post_id_int do
          updated_viewing_post = Enum.find(updated_posts, fn p -> p.id == post_id_int end)
          assign(socket, :viewing_post, updated_viewing_post)
        else
          socket
        end

        # Broadcast pour les autres utilisateurs
        Phoenix.PubSub.broadcast(MonApp.PubSub, @topic, {:reaction_updated, post_id_int})

        {:noreply, socket}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Erreur lors de la réaction")}
    end
  end

  defp update_post_reactions(posts, post_id) do
    Enum.map(posts, fn post ->
      if post.id == post_id do
        reactions = Blog.list_reactions(post_id)
        %{post | reactions: reactions}
      else
        post
      end
    end)
  end

  # ============== REACTIONS MODAL EVENTS ==============

  @impl true
  def handle_event("open_reactions", %{"id" => id}, socket) do
    post = Blog.get_post(id) |> Repo.preload([:user, reactions: [:user]])
    user_id = socket.assigns.current_user.id

    if post do
      # Calculer le statut d'amitié pour chaque utilisateur ayant réagi
      friendship_statuses =
        post.reactions
        |> Enum.map(fn r -> r.user_id end)
        |> Enum.uniq()
        |> Enum.reject(fn uid -> uid == user_id end)
        |> Enum.map(fn uid -> {uid, Social.friendship_status(user_id, uid)} end)
        |> Enum.into(%{})

      {:noreply,
       socket
       |> assign(:viewing_reactions_post, post)
       |> assign(:reactions_filter, "all")
       |> assign(:friendship_statuses, friendship_statuses)}
    else
      {:noreply, put_flash(socket, :error, "Post non trouvé")}
    end
  end

  @impl true
  def handle_event("close_reactions", _, socket) do
    {:noreply,
     socket
     |> assign(:viewing_reactions_post, nil)
     |> assign(:reactions_filter, "all")
     |> assign(:friendship_statuses, %{})}
  end

  @impl true
  def handle_event("filter_reactions", %{"filter" => filter}, socket) do
    {:noreply, assign(socket, :reactions_filter, filter)}
  end

  @impl true
  def handle_event("send_friend_request_from_reactions", %{"user-id" => friend_id}, socket) do
    user_id = socket.assigns.current_user.id
    friend_id = String.to_integer(friend_id)

    case Social.send_friend_request(user_id, friend_id) do
      {:ok, _} ->
        # Mettre à jour le statut d'amitié
        friendship_statuses = Map.put(socket.assigns.friendship_statuses, friend_id, :request_sent)
        {:noreply,
         socket
         |> assign(:friendship_statuses, friendship_statuses)
         |> put_flash(:info, "Demande d'ami envoyée")}

      {:error, :already_exists} ->
        {:noreply, put_flash(socket, :info, "Demande déjà envoyée ou vous êtes déjà amis")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Erreur lors de l'envoi de la demande")}
    end
  end

  @impl true
  def handle_event("cancel_friend_request_from_reactions", %{"user-id" => friend_id}, socket) do
    user_id = socket.assigns.current_user.id
    friend_id = String.to_integer(friend_id)

    case Social.cancel_friend_request(user_id, friend_id) do
      {:ok, _} ->
        friendship_statuses = Map.put(socket.assigns.friendship_statuses, friend_id, :none)
        {:noreply,
         socket
         |> assign(:friendship_statuses, friendship_statuses)
         |> put_flash(:info, "Demande annulée")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Erreur lors de l'annulation")}
    end
  end

  @impl true
  def handle_event("accept_friend_from_reactions", %{"user-id" => friend_id}, socket) do
    user_id = socket.assigns.current_user.id
    friend_id = String.to_integer(friend_id)

    # Trouver la demande d'ami
    pending_requests = Social.list_pending_requests(user_id)
    request = Enum.find(pending_requests, fn r -> r.user_id == friend_id end)

    if request do
      case Social.accept_friend_request(request.id, user_id) do
        {:ok, _} ->
          friendship_statuses = Map.put(socket.assigns.friendship_statuses, friend_id, :friends)
          pending_count = socket.assigns.pending_requests_count - 1
          {:noreply,
           socket
           |> assign(:friendship_statuses, friendship_statuses)
           |> assign(:pending_requests_count, pending_count)
           |> put_flash(:info, "Demande acceptée ! Vous êtes maintenant amis")}

        {:error, _} ->
          {:noreply, put_flash(socket, :error, "Erreur lors de l'acceptation")}
      end
    else
      {:noreply, put_flash(socket, :error, "Demande non trouvée")}
    end
  end

  # ============== COMMENT REACTION EVENTS ==============

  @impl true
  def handle_event("toggle_comment_reaction", %{"comment-id" => comment_id, "type" => reaction_type}, socket) do
    user = socket.assigns.current_user
    comment_id = String.to_integer(comment_id)

    case Blog.toggle_comment_reaction(user.id, comment_id, reaction_type) do
      {:ok, _result} ->
        # Recharger les réactions du commentaire et mettre à jour les posts
        updated_posts = update_comment_reactions(socket.assigns.posts, comment_id)

        # Mettre à jour aussi le viewing_post si on est dans le modal des commentaires
        socket =
          if socket.assigns.viewing_post do
            updated_viewing_post = update_post_comment_reactions(socket.assigns.viewing_post, comment_id)
            assign(socket, :viewing_post, updated_viewing_post)
          else
            socket
          end

        {:noreply, assign(socket, :posts, updated_posts)}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Erreur lors de la réaction")}
    end
  end

  defp update_comment_reactions(posts, comment_id) do
    reactions = Blog.list_comment_reactions(comment_id)

    Enum.map(posts, fn post ->
      updated_comments = update_comments_with_reaction(post.comments, comment_id, reactions)
      %{post | comments: updated_comments}
    end)
  end

  defp update_post_comment_reactions(post, comment_id) do
    reactions = Blog.list_comment_reactions(comment_id)
    updated_comments = update_comments_with_reaction(post.comments, comment_id, reactions)
    %{post | comments: updated_comments}
  end

  defp update_comments_with_reaction(comments, comment_id, reactions) do
    Enum.map(comments, fn comment ->
      comment =
        if comment.id == comment_id do
          %{comment | reactions: reactions}
        else
          comment
        end

      # Mettre à jour aussi les réponses
      replies = Map.get(comment, :replies, [])
      updated_replies = Enum.map(replies, fn reply ->
        if reply.id == comment_id do
          %{reply | reactions: reactions}
        else
          reply
        end
      end)

      %{comment | replies: updated_replies}
    end)
  end

  # ============== COMMENT REACTIONS MODAL EVENTS ==============

  @impl true
  def handle_event("open_comment_reactions", %{"comment-id" => comment_id}, socket) do
    comment_id = String.to_integer(comment_id)
    user_id = socket.assigns.current_user.id

    # Trouver le commentaire dans les posts ou dans le viewing_post
    comment = find_comment_in_posts(socket.assigns.posts, comment_id) ||
              (socket.assigns.viewing_post && find_comment_in_post(socket.assigns.viewing_post, comment_id))

    if comment do
      # Recharger les réactions avec les users
      reactions = Blog.list_comment_reactions(comment_id)
      comment = %{comment | reactions: reactions}

      # Calculer le statut d'amitié pour chaque utilisateur ayant réagi
      friendship_statuses =
        reactions
        |> Enum.map(fn r -> r.user_id end)
        |> Enum.uniq()
        |> Enum.reject(fn uid -> uid == user_id end)
        |> Enum.map(fn uid -> {uid, Social.friendship_status(user_id, uid)} end)
        |> Enum.into(%{})

      {:noreply,
       socket
       |> assign(:viewing_comment_reactions, comment)
       |> assign(:comment_reactions_filter, "all")
       |> assign(:comment_friendship_statuses, friendship_statuses)}
    else
      {:noreply, put_flash(socket, :error, "Commentaire non trouvé")}
    end
  end

  @impl true
  def handle_event("close_comment_reactions", _, socket) do
    {:noreply,
     socket
     |> assign(:viewing_comment_reactions, nil)
     |> assign(:comment_reactions_filter, "all")
     |> assign(:comment_friendship_statuses, %{})}
  end

  @impl true
  def handle_event("filter_comment_reactions", %{"filter" => filter}, socket) do
    {:noreply, assign(socket, :comment_reactions_filter, filter)}
  end

  @impl true
  def handle_event("send_friend_request_from_comment_reactions", %{"user-id" => friend_id}, socket) do
    user_id = socket.assigns.current_user.id
    friend_id = String.to_integer(friend_id)

    case Social.send_friend_request(user_id, friend_id) do
      {:ok, _} ->
        friendship_statuses = Map.put(socket.assigns.comment_friendship_statuses, friend_id, :request_sent)
        {:noreply,
         socket
         |> assign(:comment_friendship_statuses, friendship_statuses)
         |> put_flash(:info, "Demande d'ami envoyée")}

      {:error, :already_exists} ->
        {:noreply, put_flash(socket, :info, "Demande déjà envoyée ou vous êtes déjà amis")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Erreur lors de l'envoi de la demande")}
    end
  end

  @impl true
  def handle_event("accept_friend_from_comment_reactions", %{"user-id" => friend_id}, socket) do
    user_id = socket.assigns.current_user.id
    friend_id = String.to_integer(friend_id)

    # Trouver la demande d'ami
    pending_requests = Social.list_pending_requests(user_id)
    request = Enum.find(pending_requests, fn r -> r.user_id == friend_id end)

    if request do
      case Social.accept_friend_request(request.id, user_id) do
        {:ok, _} ->
          friendship_statuses = Map.put(socket.assigns.comment_friendship_statuses, friend_id, :friends)
          pending_count = socket.assigns.pending_requests_count - 1
          {:noreply,
           socket
           |> assign(:comment_friendship_statuses, friendship_statuses)
           |> assign(:pending_requests_count, pending_count)
           |> put_flash(:info, "Demande acceptée ! Vous êtes maintenant amis")}

        {:error, _} ->
          {:noreply, put_flash(socket, :error, "Erreur lors de l'acceptation")}
      end
    else
      {:noreply, put_flash(socket, :error, "Demande non trouvée")}
    end
  end

  # Helper pour trouver un commentaire dans les posts
  defp find_comment_in_posts(posts, comment_id) do
    Enum.find_value(posts, fn post ->
      find_comment_in_post(post, comment_id)
    end)
  end

  defp find_comment_in_post(post, comment_id) do
    # Chercher dans les commentaires de premier niveau
    found = Enum.find(post.comments, fn c -> c.id == comment_id end)

    if found do
      found
    else
      # Chercher dans les réponses
      Enum.find_value(post.comments, fn comment ->
        replies = Map.get(comment, :replies, [])
        Enum.find(replies, fn r -> r.id == comment_id end)
      end)
    end
  end

  # ============== COMMENT EVENTS ==============

  @impl true
  def handle_event("open_comments", %{"id" => id}, socket) do
    post = Blog.get_post_with_comments(id)

    if post do
      comment_form = Blog.change_comment(%Comment{}) |> to_form()

      {:noreply,
       socket
       |> assign(:viewing_post, post)
       |> assign(:comment_form, comment_form)
       |> assign(:comment_form_id, System.unique_integer())
       |> assign(:replying_to, nil)}
    else
      {:noreply, put_flash(socket, :error, "Post non trouvé")}
    end
  end

  @impl true
  def handle_event("close_comments", _, socket) do
    # Ne pas fermer si le modal des réactions de commentaire ou le preview d'image est ouvert
    if socket.assigns.viewing_comment_reactions || socket.assigns.preview_image do
      {:noreply, socket}
    else
      {:noreply,
       socket
       |> assign(:viewing_post, nil)
       |> assign(:comment_form, nil)
       |> assign(:replying_to, nil)}
    end
  end

  @impl true
  def handle_event("start_reply", %{"id" => comment_id}, socket) do
    comment = Blog.get_comment(comment_id) |> Repo.preload(:user)

    if comment do
      {:noreply, assign(socket, :replying_to, comment)}
    else
      {:noreply, put_flash(socket, :error, "Commentaire non trouvé")}
    end
  end

  @impl true
  def handle_event("cancel_reply", _, socket) do
    {:noreply, assign(socket, :replying_to, nil)}
  end

  @impl true
  def handle_event("cancel-comment-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :comment_images, ref)}
  end

  @impl true
  def handle_event("validate_comment", %{"comment" => _comment_params}, socket) do
    # Juste pour permettre le preview des images uploadées
    {:noreply, socket}
  end

  # ============== IMAGE PREVIEW EVENTS ==============

  @impl true
  def handle_event("open_image_preview", %{"src" => src}, socket) do
    {:noreply, assign(socket, :preview_image, src)}
  end

  @impl true
  def handle_event("close_image_preview", _, socket) do
    {:noreply, assign(socket, :preview_image, nil)}
  end

  @impl true
  def handle_event("add_comment", %{"comment" => comment_params}, socket) do
    user = socket.assigns.current_user
    post = socket.assigns.viewing_post

    # Vérifier qu'il y a du texte ou une image
    has_body = comment_params["body"] && String.trim(comment_params["body"]) != ""
    has_image = socket.assigns.uploads.comment_images.entries != []

    if !has_body && !has_image do
      {:noreply, put_flash(socket, :error, "Ajoutez un texte ou une image")}
    else
      comment_params =
        comment_params
        |> Map.put("user_id", user.id)
        |> Map.put("post_id", post.id)
        |> Map.update("body", "", fn body -> if body, do: body, else: "" end)

      case Blog.create_comment(comment_params) do
        {:ok, comment} ->
          # Sauvegarder l'image si présente
          save_comment_images(socket, comment.id)

          comment = Repo.preload(comment, [:user, :images, :replies, :reactions])

          # Mettre à jour le post avec le nouveau commentaire
          updated_post = %{post | comments: post.comments ++ [comment]}

          # Mettre à jour aussi dans la liste des posts
          posts =
            Enum.map(socket.assigns.posts, fn p ->
              if p.id == post.id do
                %{p | comments: p.comments ++ [comment]}
              else
                p
              end
            end)

          # Broadcast pour les autres utilisateurs
          Phoenix.PubSub.broadcast(MonApp.PubSub, @topic, {:comment_added, post.id, comment})

          {:noreply,
           socket
           |> assign(:viewing_post, updated_post)
           |> assign(:posts, posts)
           |> assign(:comment_form, to_form(Blog.change_comment(%Comment{})))
           |> assign(:comment_form_id, System.unique_integer())}

        {:error, changeset} ->
          {:noreply, assign(socket, :comment_form, to_form(changeset))}
      end
    end
  end

  @impl true
  def handle_event("add_reply", %{"comment" => comment_params}, socket) do
    user = socket.assigns.current_user
    post = socket.assigns.viewing_post
    parent_comment = socket.assigns.replying_to

    # Vérifier qu'il y a du texte ou une image
    has_body = comment_params["body"] && String.trim(comment_params["body"]) != ""
    has_image = socket.assigns.uploads.comment_images.entries != []

    if !has_body && !has_image do
      {:noreply, put_flash(socket, :error, "Ajoutez un texte ou une image")}
    else
      comment_params =
        comment_params
        |> Map.put("user_id", user.id)
        |> Map.put("post_id", post.id)
        |> Map.put("parent_id", parent_comment.id)
        |> Map.update("body", "", fn body -> if body, do: body, else: "" end)

      case Blog.create_reply(comment_params) do
        {:ok, reply} ->
          # Sauvegarder l'image si présente
          save_comment_images(socket, reply.id)

          reply = Repo.preload(reply, [:user, :images, :reactions])

          # Mettre à jour le commentaire parent avec la nouvelle réponse
          updated_comments =
            Enum.map(post.comments, fn comment ->
              if comment.id == parent_comment.id do
                existing_replies = Map.get(comment, :replies, [])
                %{comment | replies: existing_replies ++ [reply]}
              else
                comment
              end
            end)

          updated_post = %{post | comments: updated_comments}

          # Mettre à jour aussi dans la liste des posts
          posts =
            Enum.map(socket.assigns.posts, fn p ->
              if p.id == post.id do
                %{p | comments: updated_comments}
              else
                p
              end
            end)

          # Broadcast pour les autres utilisateurs
          Phoenix.PubSub.broadcast(MonApp.PubSub, @topic, {:reply_added, post.id, parent_comment.id, reply})

          {:noreply,
           socket
           |> assign(:viewing_post, updated_post)
           |> assign(:posts, posts)
           |> assign(:comment_form, to_form(Blog.change_comment(%Comment{})))
           |> assign(:comment_form_id, System.unique_integer())
           |> assign(:replying_to, nil)}

        {:error, changeset} ->
          {:noreply, assign(socket, :comment_form, to_form(changeset))}
      end
    end
  end

  @impl true
  def handle_event("delete_comment", %{"id" => comment_id}, socket) do
    user = socket.assigns.current_user
    post = socket.assigns.viewing_post
    comment = Blog.get_comment(comment_id)

    # L'auteur du commentaire ou l'auteur du post peut supprimer
    can_delete? = comment && (comment.user_id == user.id or post.user_id == user.id)

    if can_delete? do
      case Blog.delete_comment(comment) do
        {:ok, _} ->
          # Mettre à jour le post sans le commentaire
          updated_comments = Enum.reject(post.comments, &(&1.id == comment.id))
          updated_post = %{post | comments: updated_comments}

          # Mettre à jour aussi dans la liste des posts
          posts =
            Enum.map(socket.assigns.posts, fn p ->
              if p.id == post.id do
                %{p | comments: updated_comments}
              else
                p
              end
            end)

          # Broadcast pour les autres utilisateurs
          Phoenix.PubSub.broadcast(MonApp.PubSub, @topic, {:comment_deleted, post.id, comment.id})

          {:noreply,
           socket
           |> assign(:viewing_post, updated_post)
           |> assign(:posts, posts)}

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
    user_id = socket.assigns.current_user.id

    # Vérifier si l'utilisateur peut voir ce post
    if can_see_post?(post, user_id) do
      posts = [post | socket.assigns.posts]
      {:noreply, assign(socket, :posts, posts)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:post_deleted, post}, socket) do
    posts = Enum.reject(socket.assigns.posts, &(&1.id == post.id))
    {:noreply, assign(socket, :posts, posts)}
  end

  @impl true
  def handle_info({:post_updated, updated_post}, socket) do
    posts =
      Enum.map(socket.assigns.posts, fn post ->
        if post.id == updated_post.id, do: updated_post, else: post
      end)

    {:noreply, assign(socket, :posts, posts)}
  end

  @impl true
  def handle_info({:reaction_updated, post_id}, socket) do
    # Recharger les réactions du post
    posts = update_post_reactions(socket.assigns.posts, post_id)
    {:noreply, assign(socket, :posts, posts)}
  end

  @impl true
  def handle_info({:comment_added, post_id, comment}, socket) do
    # S'assurer que le commentaire a les replies initialisées
    comment = Map.put_new(comment, :replies, [])

    # Mettre à jour les posts avec le nouveau commentaire
    posts =
      Enum.map(socket.assigns.posts, fn post ->
        if post.id == post_id do
          # Éviter les doublons si c'est notre propre commentaire
          if Enum.any?(post.comments, &(&1.id == comment.id)) do
            post
          else
            %{post | comments: post.comments ++ [comment]}
          end
        else
          post
        end
      end)

    # Mettre à jour le viewing_post si on regarde ce post
    socket =
      if socket.assigns.viewing_post && socket.assigns.viewing_post.id == post_id do
        viewing_post = socket.assigns.viewing_post

        if Enum.any?(viewing_post.comments, &(&1.id == comment.id)) do
          socket
        else
          assign(socket, :viewing_post, %{viewing_post | comments: viewing_post.comments ++ [comment]})
        end
      else
        socket
      end

    {:noreply, assign(socket, :posts, posts)}
  end

  @impl true
  def handle_info({:comment_deleted, post_id, comment_id}, socket) do
    # Mettre à jour les posts sans le commentaire (commentaire principal ou réponse)
    posts =
      Enum.map(socket.assigns.posts, fn post ->
        if post.id == post_id do
          updated_comments =
            post.comments
            |> Enum.reject(&(&1.id == comment_id))
            |> Enum.map(fn comment ->
              replies = Map.get(comment, :replies, [])
              %{comment | replies: Enum.reject(replies, &(&1.id == comment_id))}
            end)
          %{post | comments: updated_comments}
        else
          post
        end
      end)

    # Mettre à jour le viewing_post si on regarde ce post
    socket =
      if socket.assigns.viewing_post && socket.assigns.viewing_post.id == post_id do
        viewing_post = socket.assigns.viewing_post
        updated_comments =
          viewing_post.comments
          |> Enum.reject(&(&1.id == comment_id))
          |> Enum.map(fn comment ->
            replies = Map.get(comment, :replies, [])
            %{comment | replies: Enum.reject(replies, &(&1.id == comment_id))}
          end)
        assign(socket, :viewing_post, %{viewing_post | comments: updated_comments})
      else
        socket
      end

    {:noreply, assign(socket, :posts, posts)}
  end

  @impl true
  def handle_info({:reply_added, post_id, parent_id, reply}, socket) do
    # Mettre à jour les posts avec la nouvelle réponse
    posts =
      Enum.map(socket.assigns.posts, fn post ->
        if post.id == post_id do
          updated_comments =
            Enum.map(post.comments, fn comment ->
              if comment.id == parent_id do
                existing_replies = Map.get(comment, :replies, [])
                if Enum.any?(existing_replies, &(&1.id == reply.id)) do
                  comment
                else
                  %{comment | replies: existing_replies ++ [reply]}
                end
              else
                comment
              end
            end)
          %{post | comments: updated_comments}
        else
          post
        end
      end)

    # Mettre à jour le viewing_post si on regarde ce post
    socket =
      if socket.assigns.viewing_post && socket.assigns.viewing_post.id == post_id do
        viewing_post = socket.assigns.viewing_post
        updated_comments =
          Enum.map(viewing_post.comments, fn comment ->
            if comment.id == parent_id do
              existing_replies = Map.get(comment, :replies, [])
              if Enum.any?(existing_replies, &(&1.id == reply.id)) do
                comment
              else
                %{comment | replies: existing_replies ++ [reply]}
              end
            else
              comment
            end
          end)
        assign(socket, :viewing_post, %{viewing_post | comments: updated_comments})
      else
        socket
      end

    {:noreply, assign(socket, :posts, posts)}
  end

  # ============== HELPERS ==============

  defp can_see_post?(post, user_id) do
    cond do
      # C'est mon post
      post.user_id == user_id -> true
      # Post public
      post.visibility == "public" -> true
      # Post privé (et pas mon post)
      post.visibility == "private" -> false
      # Post amis - vérifier si on est amis
      post.visibility == "friends" ->
        Social.friendship_status(user_id, post.user_id) == :friends
      # Par défaut, non
      true -> false
    end
  end

  defp save_uploaded_images(socket, post_id) do
    consume_uploaded_entries(socket, :images, fn %{path: path}, entry ->
      # Générer un nom de fichier unique
      ext = Path.extname(entry.client_name)
      filename = "#{post_id}_#{System.unique_integer([:positive])}#{ext}"
      dest = Path.join(Blog.uploads_dir(), filename)

      # Copier le fichier
      File.cp!(path, dest)

      # Créer l'entrée en base
      Blog.create_post_image(%{
        filename: filename,
        original_filename: entry.client_name,
        content_type: entry.client_type,
        size: entry.client_size,
        post_id: post_id
      })

      {:ok, filename}
    end)
  end

  defp save_comment_images(socket, comment_id) do
    consume_uploaded_entries(socket, :comment_images, fn %{path: path}, entry ->
      # Générer un nom de fichier unique
      ext = Path.extname(entry.client_name)
      filename = "comment_#{comment_id}_#{System.unique_integer([:positive])}#{ext}"
      dest = Path.join(Blog.comment_uploads_dir(), filename)

      # Copier le fichier
      File.cp!(path, dest)

      # Créer l'entrée en base
      Blog.create_comment_image(%{
        filename: filename,
        original_filename: entry.client_name,
        content_type: entry.client_type,
        size: entry.client_size,
        comment_id: comment_id
      })

      {:ok, filename}
    end)
  end
end
