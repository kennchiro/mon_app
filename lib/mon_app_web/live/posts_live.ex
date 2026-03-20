defmodule MonAppWeb.PostsLive do
  use MonAppWeb, :live_view

  alias MonApp.Blog
  alias MonApp.Blog.Post
  alias MonApp.Blog.Comment
  alias MonApp.Chat
  alias MonApp.Notifications
  alias MonApp.Repo
  alias MonApp.Social
  alias MonAppWeb.Presence

  import MonAppWeb.Navbar
  import MonAppWeb.PostComponents
  import MonAppWeb.Toast, only: [toast_popup: 1]
  alias MonAppWeb.ToastHandler

  @topic "posts"

  # ============== LIFECYCLE ==============

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_user
    user_id = user.id

    if connected?(socket) do
      # Tracker la présence de l'utilisateur
      {:ok, _} = Presence.track(self(), "users:online", to_string(user_id), %{
        user_id: user_id,
        name: user.name,
        online_at: System.system_time(:second)
      })

      Phoenix.PubSub.subscribe(MonApp.PubSub, @topic)
      Phoenix.PubSub.subscribe(MonApp.PubSub, "user:#{user_id}")
    end

    {posts, has_more?} = Blog.list_posts_for_user_paginated(user_id, 1, 20, post_type: "date")
    pending_count = Social.count_pending_requests(user_id)
    unread_messages_count = Chat.count_total_unread(user_id)

    {:ok,
     socket
     |> assign(:posts, posts)
     |> assign(:page, 1)
     |> assign(:has_more, has_more?)
     |> assign(:loading_more, false)
     |> assign(:pending_requests_count, pending_count)
     |> assign(:unread_messages_count, unread_messages_count)
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
     |> assign(:sharing_post, nil)
     |> assign(:share_form, to_form(%{"visibility" => "public"}))
     |> assign(:feed_filter, "date")
     |> assign(:show_date_modal, false)
     |> assign(:editing_date, nil)
     |> assign(:date_form, to_form(Blog.change_date_post(%Post{})))
     |> assign(:applying_to_date, nil)
     |> assign(:viewing_date_applications, nil)
     |> assign(:date_applications, [])
     |> allow_upload(:images,
       accept: ~w(.jpg .jpeg .png .gif .webp),
       max_entries: 20,
       max_file_size: 10_000_000
     )
     |> allow_upload(:date_images,
       accept: ~w(.jpg .jpeg .png .gif .webp),
       max_entries: 4,
       max_file_size: 10_000_000
     )
     |> allow_upload(:comment_images,
       accept: ~w(.jpg .jpeg .png .gif .webp),
       max_entries: 4,
       max_file_size: 5_000_000
     )
     |> ToastHandler.init_toast()
     |> assign(:online_user_ids, get_online_ids())
     |> assign(:reporting_post, nil)
     |> assign(:reporting_type, nil)}
  end

  @impl true
  def handle_params(%{"post_id" => post_id}, _uri, socket) do
    case Blog.get_post_with_comments(post_id) do
      nil ->
        {:noreply, put_flash(socket, :error, "Post non trouvé")}

      post ->
        comment_form = Blog.change_comment(%Comment{}) |> to_form()

        {:noreply,
         socket
         |> assign(:viewing_post, post)
         |> assign(:comment_form, comment_form)
         |> assign(:comment_form_id, System.unique_integer())
         |> assign(:replying_to, nil)}
    end
  end

  @impl true
  def handle_params(_params, _uri, socket) do
    {:noreply, socket}
  end

  # ============== RENDER ==============

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-base-200 overflow-x-hidden">
      <.navbar current_user={@current_user} current_path="/posts" pending_requests_count={@pending_requests_count} unread_messages_count={@unread_messages_count} notifications={@notifications} unread_notifications_count={@unread_notifications_count} />
      <.toast_popup toast={@toast} />

      <main id="posts-main" phx-hook="ScrollRestore" class="max-w-2xl mx-auto p-4 sm:p-6 pb-20 md:pb-6">
        <.post_form_trigger current_user={@current_user} />
        <.post_form_modal
          :if={@show_post_modal}
          form={@form}
          uploads={@uploads}
          current_user={@current_user}
        />
        <.date_form_modal
          :if={@show_date_modal}
          form={@date_form}
          uploads={@uploads}
          current_user={@current_user}
          editing_post={@editing_date}
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
        <.share_post_modal
          :if={@sharing_post}
          post={@sharing_post}
          current_user={@current_user}
          form={@share_form}
        />
        <.date_apply_modal
          :if={@applying_to_date}
          post={@applying_to_date}
          current_user={@current_user}
        />
        <.date_applications_modal
          :if={@viewing_date_applications}
          post={@viewing_date_applications}
          applications={@date_applications}
          current_user={@current_user}
        />
        <.post_list posts={@posts} current_user={@current_user} feed_filter={@feed_filter} online_user_ids={@online_user_ids} />

        <!-- Infinite Scroll Sentinel -->
        <div
          :if={@has_more}
          id="infinite-scroll-sentinel"
          phx-hook="InfiniteScroll"
          class="flex justify-center py-8"
        >
          <span class="loading loading-spinner loading-md text-primary"></span>
        </div>

        <div :if={!@has_more && @posts != []} class="text-center py-8 text-base-content/40 text-sm">
          Vous avez tout vu !
        </div>
      </main>

      <!-- Report Post Modal -->
      <div :if={@reporting_post} class="fixed inset-0 bg-black/50 z-[100] flex items-center justify-center px-4">
        <div class="bg-base-100 rounded-2xl shadow-2xl max-w-sm w-full overflow-hidden" phx-click-away="close_report_modal">
          <div class="p-5">
            <h3 class="text-lg font-bold text-base-content">
              {if @reporting_type == "date", do: "Signaler ce date", else: "Signaler cette publication"}
            </h3>
            <p class="text-sm text-base-content/50 mt-1">Choisissez la raison du signalement</p>

            <div class="space-y-1.5 mt-4">
              <button
                :for={reason <- MonApp.Social.UserReport.reasons_for(@reporting_type)}
                type="button"
                phx-click="submit_report"
                phx-value-reason={reason}
                class="w-full text-left px-4 py-2.5 rounded-xl text-sm hover:bg-base-200/50 transition-colors flex items-center justify-between"
              >
                <span>{MonApp.Social.UserReport.reason_label(reason)}</span>
                <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 text-base-content/20" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M9 5l7 7-7 7" />
                </svg>
              </button>
            </div>
          </div>
          <div class="border-t border-base-200">
            <button phx-click="close_report_modal" class="w-full py-3 text-sm font-medium text-base-content/50 hover:bg-base-200/50 transition-colors">
              Annuler
            </button>
          </div>
        </div>
      </div>
    </div>
    """
  end

  # ============== EVENTS ==============

  @impl true
  def handle_event("load_more", _, socket) do
    if socket.assigns.has_more && !socket.assigns.loading_more do
      socket = assign(socket, :loading_more, true)
      user_id = socket.assigns.current_user.id
      next_page = socket.assigns.page + 1

      filter = socket.assigns.feed_filter
      {new_posts, has_more?} = Blog.list_posts_for_user_paginated(user_id, next_page, 20, post_type: filter)

      {:noreply,
       socket
       |> assign(:posts, socket.assigns.posts ++ new_posts)
       |> assign(:page, next_page)
       |> assign(:has_more, has_more?)
       |> assign(:loading_more, false)}
    else
      {:noreply, socket}
    end
  end

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

  # ============== SHARE EVENTS ==============

  @impl true
  def handle_event("open_share_modal", %{"id" => id}, socket) do
    post_id = String.to_integer(id)

    # Chercher dans les posts locaux d'abord
    post = Enum.find(socket.assigns.posts, fn p -> p.id == post_id end)

    # Si pas trouvé, chercher dans les shared_post des posts locaux
    post = post || Enum.find_value(socket.assigns.posts, fn p ->
      if p.shared_post && p.shared_post.id == post_id, do: p.shared_post, else: nil
    end)

    # Si toujours pas trouvé, charger depuis la DB
    post = post || Blog.get_post_with_user(post_id)

    if post do
      {:noreply,
       socket
       |> assign(:sharing_post, post)
       |> assign(:share_form, to_form(%{"visibility" => "public", "title" => "", "body" => ""}))}
    else
      {:noreply, put_flash(socket, :error, "Post non trouvé")}
    end
  end

  @impl true
  def handle_event("close_share_modal", _, socket) do
    {:noreply,
     socket
     |> assign(:sharing_post, nil)
     |> assign(:share_form, to_form(%{"visibility" => "public"}))}
  end

  @impl true
  def handle_event("validate_share", %{"share" => share_params}, socket) do
    {:noreply, assign(socket, :share_form, to_form(share_params))}
  end

  @impl true
  def handle_event("share_post", %{"share" => share_params}, socket) do
    user = socket.assigns.current_user
    shared_post_id = String.to_integer(share_params["shared_post_id"])

    attrs = %{
      title: share_params["title"],
      body: share_params["body"],
      visibility: share_params["visibility"] || "public"
    }

    case Blog.share_post(user.id, shared_post_id, attrs) do
      {:ok, new_post} ->
        new_post = Repo.preload(new_post, [:user, :images, :reactions, :shares,
          shared_post: [:user, :images],
          comments: []])

        {:noreply,
         socket
         |> assign(:posts, [new_post | socket.assigns.posts])
         |> assign(:sharing_post, nil)
         |> assign(:share_form, to_form(%{"visibility" => "public"}))
         |> put_flash(:info, "Publication partagée !")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Erreur lors du partage")}
    end
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

          # Notifier le propriétaire du post
          Notifications.notify_comment(post, comment, user)

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

          # Notifier le propriétaire du post
          Notifications.notify_comment(post, reply, user)
          # Notifier l'auteur du commentaire parent
          Notifications.notify_reply(post, reply, parent_comment, user)

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

  # ============== NOTIFICATION EVENTS ==============

  # ============== REPORT / BLOCK ==============

  @impl true
  def handle_event("report_post", %{"id" => id, "type" => type}, socket) do
    post = Enum.find(socket.assigns.posts, fn p -> p.id == String.to_integer(id) end)
    {:noreply, socket |> assign(:reporting_post, post) |> assign(:reporting_type, type)}
  end

  @impl true
  def handle_event("close_report_modal", _, socket) do
    {:noreply, socket |> assign(:reporting_post, nil) |> assign(:reporting_type, nil)}
  end

  @impl true
  def handle_event("submit_report", %{"reason" => reason}, socket) do
    post = socket.assigns.reporting_post
    user_id = socket.assigns.current_user.id

    case Social.report_post(user_id, post.id, post.user_id, reason, socket.assigns.reporting_type) do
      {:ok, _} ->
        {:noreply,
         socket
         |> assign(:reporting_post, nil)
         |> assign(:reporting_type, nil)
         |> put_flash(:info, "Signalement envoyé. Merci pour votre vigilance.")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Erreur lors du signalement")}
    end
  end

  @impl true
  def handle_event("block_user_from_post", %{"id" => user_id}, socket) do
    current_user_id = socket.assigns.current_user.id
    blocked_id = String.to_integer(user_id)

    Social.block_user(current_user_id, blocked_id)
    blocked_name = Enum.find_value(socket.assigns.posts, fn p -> if p.user_id == blocked_id, do: p.user.name end)

    # Filter posts from blocked user
    posts = Enum.reject(socket.assigns.posts, fn p -> p.user_id == blocked_id end)

    {:noreply,
     socket
     |> assign(:posts, posts)
     |> put_flash(:info, "#{blocked_name} a été bloqué")}
  end

  @impl true
  def handle_event("dismiss_toast", _, socket) do
    Process.send_after(self(), :clear_toast, 300)
    {:noreply, ToastHandler.dismiss_toast(socket)}
  end

  @impl true
  def handle_event("mark_notification_read", %{"id" => id}, socket) do
    user_id = socket.assigns.current_user.id
    notification_id = String.to_integer(id)
    Notifications.mark_as_read(notification_id, user_id)

    notifications =
      Enum.map(socket.assigns.notifications, fn n ->
        if n.id == notification_id, do: %{n | read: true}, else: n
      end)

    unread_count = Enum.count(notifications, fn n -> !n.read end)

    {:noreply,
     socket
     |> assign(:notifications, notifications)
     |> assign(:unread_notifications_count, unread_count)}
  end

  @impl true
  def handle_event("mark_all_notifications_read", _, socket) do
    user_id = socket.assigns.current_user.id
    Notifications.mark_all_as_read(user_id)

    notifications = Enum.map(socket.assigns.notifications, fn n -> %{n | read: true} end)

    {:noreply,
     socket
     |> assign(:notifications, notifications)
     |> assign(:unread_notifications_count, 0)}
  end

  # ============== PUBSUB HANDLERS ==============

  @impl true
  def handle_info({:post_created, post}, socket) do
    user_id = socket.assigns.current_user.id
    filter = socket.assigns.feed_filter

    # Vérifier si le post correspond au filtre actif
    matches_filter = (post.post_type || "standard") == filter

    if can_see_post?(post, user_id) && matches_filter do
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

  @impl true
  def handle_info({:new_message, message}, socket) do
    user_id = socket.assigns.current_user.id
    unread_count = Chat.count_total_unread(user_id)

    # Toast for new message (not from self)
    socket =
      if message.sender_id != user_id do
        sender = MonApp.Accounts.get_user(message.sender_id)
        if sender do
          ToastHandler.show_message_toast(socket, message, sender.name, sender.avatar)
        else
          socket
        end
      else
        socket
      end

    {:noreply, assign(socket, :unread_messages_count, unread_count)}
  end

  @impl true
  def handle_info({:friend_request_received, _}, socket) do
    # Nouvelle demande d'ami reçue - mettre à jour le compteur
    user_id = socket.assigns.current_user.id
    pending_count = Social.count_pending_requests(user_id)
    {:noreply, assign(socket, :pending_requests_count, pending_count)}
  end

  @impl true
  def handle_info({:friend_request_updated, _}, socket) do
    # Demande acceptée/refusée - mettre à jour le compteur
    user_id = socket.assigns.current_user.id
    pending_count = Social.count_pending_requests(user_id)
    {:noreply, assign(socket, :pending_requests_count, pending_count)}
  end

  @impl true
  def handle_info({:friend_request_accepted, _}, socket) do
    # Notre demande a été acceptée - rafraîchir la liste d'amis si nécessaire
    {:noreply, socket}
  end

  @impl true
  def handle_info({:new_notification, notification}, socket) do
    notifications = [notification | socket.assigns.notifications]
    unread_count = socket.assigns.unread_notifications_count + 1

    {:noreply,
     socket
     |> assign(:notifications, notifications)
     |> assign(:unread_notifications_count, unread_count)
     |> ToastHandler.show_notification_toast(notification)}
  end

  @impl true
  def handle_info(:auto_dismiss_toast, socket) do
    {:noreply, ToastHandler.dismiss_toast(socket)}
  end

  @impl true
  def handle_info(:clear_toast, socket) do
    {:noreply, ToastHandler.clear_toast(socket)}
  end

  @impl true
  def handle_info(_msg, socket) do
    {:noreply, socket}
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
      MonApp.ImageCompressor.compress(dest)

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
      MonApp.ImageCompressor.compress(dest)

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

  defp get_online_ids do
    Presence.list("users:online")
    |> Map.keys()
    |> Enum.map(&String.to_integer/1)
  end

  defp save_date_images(socket, post_id) do
    consume_uploaded_entries(socket, :date_images, fn %{path: path}, entry ->
      ext = Path.extname(entry.client_name)
      filename = "date_#{post_id}_#{System.unique_integer([:positive])}#{ext}"
      dest = Path.join(Blog.uploads_dir(), filename)

      File.cp!(path, dest)
      MonApp.ImageCompressor.compress(dest)

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

  # Convertit "2026-03-20T19:00" → "2026-03-20T19:00:00Z" pour Ecto utc_datetime
  defp normalize_date_datetime(%{"date_datetime" => dt} = params) when is_binary(dt) and dt != "" do
    normalized =
      case String.length(dt) do
        16 -> dt <> ":00Z"  # "2026-03-20T19:00" → "2026-03-20T19:00:00Z"
        19 -> dt <> "Z"     # "2026-03-20T19:00:00" → "2026-03-20T19:00:00Z"
        _ -> dt
      end
    Map.put(params, "date_datetime", normalized)
  end
  defp normalize_date_datetime(params), do: params

  # ============== DATE EVENTS ==============

  @impl true
  def handle_event("open_date_modal", _, socket) do
    {:noreply, assign(socket, :show_date_modal, true)}
  end

  @impl true
  def handle_event("close_date_modal", _, socket) do
    {:noreply,
     socket
     |> assign(:show_date_modal, false)
     |> assign(:editing_date, nil)
     |> assign(:date_form, to_form(Blog.change_date_post(%Post{})))}
  end

  @impl true
  def handle_event("validate_date", %{"date" => date_params}, socket) do
    date_params = normalize_date_datetime(date_params)

    base_post = socket.assigns.editing_date || %Post{}
    form =
      base_post
      |> Blog.change_date_post(date_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, :date_form, form)}
  end

  @impl true
  def handle_event("save_date", %{"date" => date_params}, socket) do
    date_params = normalize_date_datetime(date_params)
    user = socket.assigns.current_user
    date_params = Map.put(date_params, "user_id", user.id)

    case Blog.create_date_post(date_params) do
      {:ok, post} ->
        # Sauvegarder les images uploadées
        save_date_images(socket, post.id)

        post = Repo.preload(post, [:user, :images, :reactions, :shares, :comments, date_applications: :user])
        Phoenix.PubSub.broadcast(MonApp.PubSub, @topic, {:post_created, post})

        {:noreply,
         socket
         |> put_flash(:info, "Date publié ! 💘")
         |> assign(:show_date_modal, false)
         |> assign(:date_form, to_form(Blog.change_date_post(%Post{})))}

      {:error, changeset} ->
        {:noreply, assign(socket, :date_form, to_form(changeset))}
    end
  end

  @impl true
  def handle_event("cancel-date-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :date_images, ref)}
  end

  @impl true
  def handle_event("remove_date_image", %{"id" => id}, socket) do
    image = Blog.get_post_image(String.to_integer(id))
    if image, do: Blog.delete_post_image(image)

    # Refresh the editing post to reflect removed image
    editing = socket.assigns.editing_date
    updated_post = if editing, do: Blog.get_post_with_comments(editing.id), else: nil

    {:noreply, assign(socket, :editing_date, updated_post)}
  end

  # ============== EDIT / DELETE DATE ==============

  @impl true
  def handle_event("edit_date", %{"id" => id}, socket) do
    user = socket.assigns.current_user
    post = Blog.get_post(id) |> Repo.preload([:user, :images])

    if post && post.user_id == user.id do
      date_form = Blog.change_date_post(post) |> to_form()

      {:noreply,
       socket
       |> assign(:editing_date, post)
       |> assign(:show_date_modal, true)
       |> assign(:date_form, date_form)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("update_date", %{"date" => date_params}, socket) do
    post = socket.assigns.editing_date
    user = socket.assigns.current_user

    if post && post.user_id == user.id do
      date_params = normalize_date_datetime(date_params)

      case Blog.update_date_post(post, date_params) do
        {:ok, updated_post} ->
          save_date_images(socket, updated_post.id)
          updated_post = Blog.get_post_with_comments(updated_post.id)

          posts = Enum.map(socket.assigns.posts, fn p ->
            if p.id == updated_post.id, do: updated_post, else: p
          end)

          Phoenix.PubSub.broadcast(MonApp.PubSub, @topic, {:post_updated, updated_post})

          {:noreply,
           socket
           |> assign(:posts, posts)
           |> assign(:show_date_modal, false)
           |> assign(:editing_date, nil)
           |> assign(:date_form, to_form(Blog.change_date_post(%Post{})))
           |> put_flash(:info, "Date modifié ! ✏️")}

        {:error, changeset} ->
          {:noreply, assign(socket, :date_form, to_form(changeset))}
      end
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("delete_date", %{"id" => id}, socket) do
    post = Blog.get_post(id)
    user = socket.assigns.current_user

    if post && post.user_id == user.id do
      case Blog.delete_post(post) do
        {:ok, _} ->
          Phoenix.PubSub.broadcast(MonApp.PubSub, @topic, {:post_deleted, post})
          {:noreply, put_flash(socket, :info, "Date supprimé")}

        {:error, _} ->
          {:noreply, put_flash(socket, :error, "Erreur lors de la suppression")}
      end
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("filter_feed", %{"filter" => filter}, socket) do
    user_id = socket.assigns.current_user.id
    {posts, has_more?} = Blog.list_posts_for_user_paginated(user_id, 1, 20, post_type: filter)

    {:noreply,
     socket
     |> assign(:feed_filter, filter)
     |> assign(:posts, posts)
     |> assign(:page, 1)
     |> assign(:has_more, has_more?)}
  end

  @impl true
  def handle_event("open_apply_modal", %{"id" => id}, socket) do
    post = Enum.find(socket.assigns.posts, &(to_string(&1.id) == id))
    {:noreply, assign(socket, :applying_to_date, post)}
  end

  @impl true
  def handle_event("close_apply_modal", _, socket) do
    {:noreply, assign(socket, :applying_to_date, nil)}
  end

  @impl true
  def handle_event("submit_date_application", %{"post_id" => post_id} = params, socket) do
    user_id = socket.assigns.current_user.id
    message = Map.get(params, "message", "")
    message = if message == "", do: nil, else: message

    case Blog.apply_to_date(user_id, String.to_integer(post_id), message) do
      {:ok, _application} ->
        updated_post = Blog.get_post_with_comments(String.to_integer(post_id))
        posts = Enum.map(socket.assigns.posts, fn p ->
          if p.id == updated_post.id, do: updated_post, else: p
        end)

        # Broadcast temps réel pour tous les utilisateurs
        Phoenix.PubSub.broadcast(MonApp.PubSub, @topic, {:post_updated, updated_post})

        # Notifier le propriétaire du date (temps réel + notification persistante)
        Phoenix.PubSub.broadcast(
          MonApp.PubSub,
          "user:#{updated_post.user_id}",
          {:date_application_received, updated_post}
        )

        MonApp.Notifications.notify_date_application(updated_post, socket.assigns.current_user)

        {:noreply,
         socket
         |> assign(:applying_to_date, nil)
         |> assign(:posts, posts)
         |> put_flash(:info, "Candidature envoyée ! 💘")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Impossible de postuler")}
    end
  end

  @impl true
  def handle_event("cancel_date_application", %{"post-id" => post_id}, socket) do
    user_id = socket.assigns.current_user.id
    post_id = String.to_integer(post_id)

    case Blog.cancel_date_application(user_id, post_id) do
      {:ok, _} ->
        updated_post = Blog.get_post_with_comments(post_id)
        posts = Enum.map(socket.assigns.posts, fn p ->
          if p.id == post_id, do: updated_post, else: p
        end)

        # Broadcast temps réel
        Phoenix.PubSub.broadcast(MonApp.PubSub, @topic, {:post_updated, updated_post})

        {:noreply,
         socket
         |> assign(:posts, posts)
         |> put_flash(:info, "Candidature annulée")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Impossible d'annuler")}
    end
  end

  @impl true
  def handle_event("view_date_applications", %{"id" => id}, socket) do
    post_id = String.to_integer(id)
    post = Enum.find(socket.assigns.posts, &(&1.id == post_id))
    applications = Blog.list_date_applications(post_id)

    {:noreply,
     socket
     |> assign(:viewing_date_applications, post)
     |> assign(:date_applications, applications)}
  end

  @impl true
  def handle_event("close_date_applications", _, socket) do
    {:noreply,
     socket
     |> assign(:viewing_date_applications, nil)
     |> assign(:date_applications, [])
     |> push_event("restore_scroll", %{})}
  end

  @impl true
  def handle_event("accept_date_application", %{"id" => id}, socket) do
    case Blog.accept_date_application(String.to_integer(id)) do
      {:ok, accepted_app} ->
        post = socket.assigns.viewing_date_applications
        updated_post = Blog.get_post_with_comments(post.id)
        applications = Blog.list_date_applications(post.id)
        posts = Enum.map(socket.assigns.posts, fn p ->
          if p.id == post.id, do: updated_post, else: p
        end)

        # Broadcast temps réel
        Phoenix.PubSub.broadcast(MonApp.PubSub, @topic, {:post_updated, updated_post})

        # Notification persistante pour le candidat accepté
        MonApp.Notifications.notify_date_accepted(updated_post, accepted_app.user_id)

        {:noreply,
         socket
         |> assign(:posts, posts)
         |> assign(:viewing_date_applications, updated_post)
         |> assign(:date_applications, applications)
         |> put_flash(:info, "Candidature acceptée ! Vous êtes maintenant amis 🎉")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Erreur lors de l'acceptation")}
    end
  end

  @impl true
  def handle_event("reject_date_application", %{"id" => id}, socket) do
    case Blog.reject_date_application(String.to_integer(id)) do
      {:ok, _} ->
        post = socket.assigns.viewing_date_applications
        updated_post = Blog.get_post_with_comments(post.id)
        applications = Blog.list_date_applications(post.id)
        posts = Enum.map(socket.assigns.posts, fn p ->
          if p.id == post.id, do: updated_post, else: p
        end)

        # Broadcast temps réel
        Phoenix.PubSub.broadcast(MonApp.PubSub, @topic, {:post_updated, updated_post})

        {:noreply,
         socket
         |> assign(:posts, posts)
         |> assign(:viewing_date_applications, updated_post)
         |> assign(:date_applications, applications)}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Erreur lors du déclin")}
    end
  end

  # ============== DATE REALTIME HANDLERS ==============

  @impl true
  def handle_info({:date_application_received, updated_post}, socket) do
    # Mettre à jour le post dans le feed + rafraîchir le modal si ouvert
    posts = Enum.map(socket.assigns.posts, fn p ->
      if p.id == updated_post.id, do: updated_post, else: p
    end)

    socket = assign(socket, :posts, posts)

    # Si le modal des candidatures est ouvert pour ce post, rafraîchir
    socket =
      if socket.assigns.viewing_date_applications &&
         socket.assigns.viewing_date_applications.id == updated_post.id do
        applications = Blog.list_date_applications(updated_post.id)

        socket
        |> assign(:viewing_date_applications, updated_post)
        |> assign(:date_applications, applications)
      else
        socket
      end

    {:noreply, socket}
  end
end
