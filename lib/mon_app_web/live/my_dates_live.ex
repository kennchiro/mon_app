defmodule MonAppWeb.MyDatesLive do
  use MonAppWeb, :live_view

  alias MonApp.Blog
  alias MonApp.Blog.Post
  alias MonApp.Chat
  alias MonApp.Notifications
  alias MonApp.Social
  alias MonAppWeb.Presence

  import MonAppWeb.Navbar
  import MonAppWeb.PostComponents

  @topic "posts"

  # ============== LIFECYCLE ==============

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_user
    user_id = user.id

    if connected?(socket) do
      {:ok, _} = Presence.track(self(), "users:online", to_string(user_id), %{
        user_id: user_id,
        name: user.name,
        online_at: System.system_time(:second)
      })

      Phoenix.PubSub.subscribe(MonApp.PubSub, @topic)
      Phoenix.PubSub.subscribe(MonApp.PubSub, "user:#{user_id}")
    end

    my_dates = Blog.list_my_date_posts(user_id)
    my_applications = Blog.list_my_date_applications(user_id)
    pending_count = length(Social.list_pending_requests(user_id))
    unread_messages_count = Chat.count_total_unread(user_id)
    notifications = Notifications.list_notifications(user_id)
    unread_notifications_count = Notifications.count_unread(user_id)

    {:ok,
     socket
     |> assign(:my_dates, my_dates)
     |> assign(:my_applications, my_applications)
     |> assign(:tab, "my_dates")
     |> assign(:pending_requests_count, pending_count)
     |> assign(:unread_messages_count, unread_messages_count)
     |> assign(:notifications, notifications)
     |> assign(:unread_notifications_count, unread_notifications_count)
     |> assign(:show_date_modal, false)
     |> assign(:editing_date, nil)
     |> assign(:date_form, to_form(Blog.change_date_post(%Post{})))
     |> assign(:applying_to_date, nil)
     |> assign(:viewing_date_applications, nil)
     |> assign(:date_applications, [])
     |> allow_upload(:date_images,
       accept: ~w(.jpg .jpeg .png .gif .webp),
       max_entries: 4,
       max_file_size: 10_000_000
     )}
  end

  # ============== RENDER ==============

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-base-200 overflow-x-hidden">
    <.navbar
      current_user={@current_user}
      current_path="/my-dates"
      pending_requests_count={@pending_requests_count}
      unread_messages_count={@unread_messages_count}
      notifications={@notifications}
      unread_notifications_count={@unread_notifications_count}
    />

    <div class="max-w-2xl mx-auto p-4 sm:p-6 pb-20 md:pb-6">
      <!-- Header -->
      <div class="flex items-center justify-between mb-6">
        <h1 class="text-2xl font-bold">Mes Dates</h1>
        <button
          phx-click="open_date_modal"
          class="bg-base-content text-base-100 px-5 py-2.5 rounded-xl font-bold hover:bg-pink-500 hover:text-white transition-all duration-300 shadow-md flex items-center gap-2 text-sm"
        >
          <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" viewBox="0 0 24 24" fill="currentColor">
            <path d="M12 21.35l-1.45-1.32C5.4 15.36 2 12.28 2 8.5 2 5.42 4.42 3 7.5 3c1.74 0 3.41.81 4.5 2.09C13.09 3.81 14.76 3 16.5 3 19.58 3 22 5.42 22 8.5c0 3.78-3.4 6.86-8.55 11.54L12 21.35z" />
          </svg>
          Créer un date
        </button>
      </div>

      <!-- Tabs -->
      <div class="flex gap-1 mb-6 bg-base-200/50 p-1 rounded-xl">
        <button
          phx-click="switch_tab"
          phx-value-tab="my_dates"
          class={"flex-1 py-2.5 px-4 rounded-lg text-sm font-semibold transition-all #{if @tab == "my_dates", do: "bg-base-100 shadow-sm text-base-content", else: "text-base-content/50 hover:text-base-content/70"}"}
        >
          Mes dates ({length(@my_dates)})
        </button>
        <button
          phx-click="switch_tab"
          phx-value-tab="my_applications"
          class={"flex-1 py-2.5 px-4 rounded-lg text-sm font-semibold transition-all #{if @tab == "my_applications", do: "bg-base-100 shadow-sm text-base-content", else: "text-base-content/50 hover:text-base-content/70"}"}
        >
          Mes candidatures ({length(@my_applications)})
        </button>
      </div>

      <!-- Content -->
      <div class="space-y-4">
        <!-- My dates tab -->
        <div :if={@tab == "my_dates"}>
          <div :if={@my_dates == []} class="text-center py-16">
            <div class="w-16 h-16 mx-auto bg-pink-500/10 rounded-full flex items-center justify-center mb-4">
              <svg xmlns="http://www.w3.org/2000/svg" class="h-8 w-8 text-pink-400" viewBox="0 0 24 24" fill="currentColor">
                <path d="M12 21.35l-1.45-1.32C5.4 15.36 2 12.28 2 8.5 2 5.42 4.42 3 7.5 3c1.74 0 3.41.81 4.5 2.09C13.09 3.81 14.76 3 16.5 3 19.58 3 22 5.42 22 8.5c0 3.78-3.4 6.86-8.55 11.54L12 21.35z" />
              </svg>
            </div>
            <p class="text-base-content/50 font-medium">Aucun date créé</p>
            <p class="text-base-content/30 text-sm mt-1">Créez votre premier date pour rencontrer des gens !</p>
          </div>
          <div :for={post <- @my_dates} class="mb-4">
            <.date_post_card post={post} current_user={@current_user} />
          </div>
        </div>

        <!-- My applications tab -->
        <div :if={@tab == "my_applications"}>
          <div :if={@my_applications == []} class="text-center py-16">
            <div class="w-16 h-16 mx-auto bg-blue-500/10 rounded-full flex items-center justify-center mb-4">
              <svg xmlns="http://www.w3.org/2000/svg" class="h-8 w-8 text-blue-400" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.5">
                <path stroke-linecap="round" stroke-linejoin="round" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
              </svg>
            </div>
            <p class="text-base-content/50 font-medium">Aucune candidature</p>
            <p class="text-base-content/30 text-sm mt-1">Explorez les dates disponibles depuis l'accueil !</p>
          </div>
          <div :for={app <- @my_applications} class="mb-4">
            <.date_post_card post={app.post} current_user={@current_user} />
          </div>
        </div>
      </div>
    </div>

    <!-- Modals -->
    <.date_form_modal
      :if={@show_date_modal}
      form={@date_form}
      uploads={@uploads}
      editing_post={@editing_date}
      current_user={@current_user}
    />

    <.date_apply_modal :if={@applying_to_date} post={@applying_to_date} current_user={@current_user} />

    <.date_applications_modal
      :if={@viewing_date_applications}
      post={@viewing_date_applications}
      applications={@date_applications}
      current_user={@current_user}
    />
    </div>
    """
  end

  # ============== EVENTS ==============

  @impl true
  def handle_event("switch_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, :tab, tab)}
  end

  # --- Date CRUD ---

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
    base = socket.assigns.editing_date || %Post{}
    changeset = Blog.change_date_post(base, date_params) |> Map.put(:action, :validate)
    {:noreply, assign(socket, :date_form, to_form(changeset))}
  end

  @impl true
  def handle_event("save_date", %{"date" => date_params}, socket) do
    user_id = socket.assigns.current_user.id
    date_params = Map.put(date_params, "user_id", user_id)

    case Blog.create_date_post(date_params) do
      {:ok, post} ->
        save_date_images(socket, post.id)
        my_dates = Blog.list_my_date_posts(user_id)

        # Broadcast pour que le feed principal se mette à jour
        updated_post = Blog.get_post_with_comments(post.id)
        Phoenix.PubSub.broadcast(MonApp.PubSub, @topic, {:post_created, updated_post})

        {:noreply,
         socket
         |> assign(:my_dates, my_dates)
         |> assign(:show_date_modal, false)
         |> assign(:date_form, to_form(Blog.change_date_post(%Post{})))
         |> put_flash(:info, "Date créé ! 💘")}

      {:error, changeset} ->
        {:noreply, assign(socket, :date_form, to_form(changeset))}
    end
  end

  @impl true
  def handle_event("edit_date", %{"id" => id}, socket) do
    user_id = socket.assigns.current_user.id
    post = Blog.get_post_with_comments(id)

    if post && post.user_id == user_id do
      changeset = Blog.change_date_post(post, %{})
      {:noreply,
       socket
       |> assign(:editing_date, post)
       |> assign(:date_form, to_form(changeset))
       |> assign(:show_date_modal, true)}
    else
      {:noreply, put_flash(socket, :error, "Non autorisé")}
    end
  end

  @impl true
  def handle_event("update_date", %{"date" => date_params}, socket) do
    post = socket.assigns.editing_date
    user_id = socket.assigns.current_user.id

    case Blog.update_date_post(post, date_params) do
      {:ok, _updated_post} ->
        my_dates = Blog.list_my_date_posts(user_id)

        {:noreply,
         socket
         |> assign(:my_dates, my_dates)
         |> assign(:show_date_modal, false)
         |> assign(:editing_date, nil)
         |> assign(:date_form, to_form(Blog.change_date_post(%Post{})))
         |> put_flash(:info, "Date modifié !")}

      {:error, changeset} ->
        {:noreply, assign(socket, :date_form, to_form(changeset))}
    end
  end

  @impl true
  def handle_event("delete_date", %{"id" => id}, socket) do
    user_id = socket.assigns.current_user.id
    post = Blog.get_post_with_comments(id)

    if post && post.user_id == user_id do
      Blog.delete_post(post)
      my_dates = Blog.list_my_date_posts(user_id)
      {:noreply,
       socket
       |> assign(:my_dates, my_dates)
       |> put_flash(:info, "Date supprimé")}
    else
      {:noreply, put_flash(socket, :error, "Non autorisé")}
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

    editing = socket.assigns.editing_date
    updated_post = if editing, do: Blog.get_post_with_comments(editing.id), else: nil

    {:noreply, assign(socket, :editing_date, updated_post)}
  end

  # --- Applications ---

  @impl true
  def handle_event("open_apply_modal", %{"id" => id}, socket) do
    post = Enum.find(socket.assigns.my_dates ++ Enum.map(socket.assigns.my_applications, & &1.post), fn p -> p.id == String.to_integer(id) end)
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
        Phoenix.PubSub.broadcast(MonApp.PubSub, @topic, {:post_updated, updated_post})
        Phoenix.PubSub.broadcast(MonApp.PubSub, "user:#{updated_post.user_id}", {:date_application_received, updated_post})
        Notifications.notify_date_application(updated_post, socket.assigns.current_user)

        {:noreply,
         socket
         |> assign(:applying_to_date, nil)
         |> refresh_data()
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
        Phoenix.PubSub.broadcast(MonApp.PubSub, @topic, {:post_updated, updated_post})

        {:noreply,
         socket
         |> refresh_data()
         |> put_flash(:info, "Candidature annulée")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Erreur")}
    end
  end

  @impl true
  def handle_event("view_date_applications", %{"id" => id}, socket) do
    post = Blog.get_post_with_comments(id)
    applications = Blog.list_date_applications(String.to_integer(id))
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
     |> assign(:date_applications, [])}
  end

  @impl true
  def handle_event("accept_date_application", %{"id" => id}, socket) do
    case Blog.accept_date_application(String.to_integer(id)) do
      {:ok, accepted_app} ->
        post = socket.assigns.viewing_date_applications
        updated_post = Blog.get_post_with_comments(post.id)
        applications = Blog.list_date_applications(post.id)

        Phoenix.PubSub.broadcast(MonApp.PubSub, @topic, {:post_updated, updated_post})
        Notifications.notify_date_accepted(updated_post, accepted_app.user_id)

        {:noreply,
         socket
         |> assign(:viewing_date_applications, updated_post)
         |> assign(:date_applications, applications)
         |> refresh_data()
         |> put_flash(:info, "Candidature acceptée ! 🎉")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Erreur lors de l'acceptation")}
    end
  end

  # --- Notifications ---

  @impl true
  def handle_event("mark_notification_read", %{"id" => id}, socket) do
    Notifications.mark_as_read(String.to_integer(id), socket.assigns.current_user.id)
    notifications = Notifications.list_notifications(socket.assigns.current_user.id)
    unread = Notifications.count_unread(socket.assigns.current_user.id)
    {:noreply, socket |> assign(:notifications, notifications) |> assign(:unread_notifications_count, unread)}
  end

  @impl true
  def handle_event("mark_all_notifications_read", _, socket) do
    Notifications.mark_all_as_read(socket.assigns.current_user.id)
    notifications = Notifications.list_notifications(socket.assigns.current_user.id)
    {:noreply, socket |> assign(:notifications, notifications) |> assign(:unread_notifications_count, 0)}
  end

  # ============== HANDLE INFO ==============

  @impl true
  def handle_info({:post_updated, updated_post}, socket) do
    if updated_post.post_type == "date" do
      {:noreply, refresh_data(socket)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:date_application_received, updated_post}, socket) do
    socket = refresh_data(socket)

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

  @impl true
  def handle_info({:new_notification, notification}, socket) do
    notifications = [notification | socket.assigns.notifications]
    unread_count = socket.assigns.unread_notifications_count + 1
    {:noreply, socket |> assign(:notifications, notifications) |> assign(:unread_notifications_count, unread_count)}
  end

  @impl true
  def handle_info({:new_message, _}, socket) do
    unread = Chat.count_total_unread(socket.assigns.current_user.id)
    {:noreply, assign(socket, :unread_messages_count, unread)}
  end

  @impl true
  def handle_info(_msg, socket) do
    {:noreply, socket}
  end

  # ============== HELPERS ==============

  defp refresh_data(socket) do
    user_id = socket.assigns.current_user.id
    my_dates = Blog.list_my_date_posts(user_id)
    my_applications = Blog.list_my_date_applications(user_id)
    socket
    |> assign(:my_dates, my_dates)
    |> assign(:my_applications, my_applications)
  end

  defp save_date_images(socket, post_id) do
    consume_uploaded_entries(socket, :date_images, fn %{path: path}, entry ->
      ext = Path.extname(entry.client_name)
      filename = "date_#{post_id}_#{System.unique_integer([:positive])}#{ext}"
      dest = Path.join(Blog.uploads_dir(), filename)
      File.cp!(path, dest)
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
end
