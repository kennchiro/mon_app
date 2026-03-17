defmodule MonAppWeb.UsersLive do
  use MonAppWeb, :live_view

  alias MonApp.Social
  alias MonApp.Chat
  alias MonApp.Notifications
  alias MonAppWeb.Presence

  import MonAppWeb.Navbar
  import MonAppWeb.UserComponents

  @topic "friendships"

  # ============== LIFECYCLE ==============

  @impl true
  def mount(params, _session, socket) do
    user = socket.assigns.current_user
    user_id = user.id

    if connected?(socket) do
      {:ok, _} = Presence.track(self(), "users:online", to_string(user_id), %{
        user_id: user_id,
        name: user.name,
        online_at: System.system_time(:second)
      })

      Phoenix.PubSub.subscribe(MonApp.PubSub, "#{@topic}:#{user_id}")
      Phoenix.PubSub.subscribe(MonApp.PubSub, "user:#{user_id}")
    end

    unread_messages_count = Chat.count_total_unread(user_id)

    {:ok,
     socket
     |> assign(:active_tab, tab_from_params(params))
     |> assign(:unread_messages_count, unread_messages_count)
     |> assign(:confirm_action, nil)
     |> assign(:confirm_user_id, nil)
     |> assign(:confirm_user_name, nil)
     |> assign(:friends_search, "")
     |> assign(:filtered_friends, [])
     |> assign(:discover_search, "")
     |> assign(:discover_page, 1)
     |> assign(:discover_has_more, false)
     |> assign(:discover_loading, false)
     |> load_data()}
  end

  # ============== RENDER ==============

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-base-200 overflow-x-hidden">
      <.navbar current_user={@current_user} current_path="/users" pending_requests_count={@pending_count} unread_messages_count={@unread_messages_count} notifications={@notifications} unread_notifications_count={@unread_notifications_count} />

      <main class="max-w-2xl mx-auto p-4 sm:p-6 pb-20 md:pb-6">
        <h1 class="text-2xl font-bold mb-6">Amis</h1>

        <.user_tabs active_tab={@active_tab} pending_count={@pending_count} sent_count={@sent_count} friends_count={length(@friends)} />

        <!-- Friends tab with search -->
        <div :if={@active_tab == :friends}>
          <div :if={@friends != []} class="relative mb-4">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 absolute left-3.5 top-1/2 -translate-y-1/2 text-base-content/40" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
              <path stroke-linecap="round" stroke-linejoin="round" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
            </svg>
            <input
              type="text"
              value={@friends_search}
              phx-keyup="search_friends"
              phx-debounce="300"
              placeholder="Rechercher un ami..."
              class="w-full pl-10 pr-4 py-2.5 bg-base-100 border border-base-300 rounded-xl text-sm focus:outline-none focus:border-pink-400 transition-all"
            />
            <button
              :if={@friends_search != ""}
              type="button"
              phx-click="clear_friends_search"
              class="absolute right-3 top-1/2 -translate-y-1/2 text-base-content/30 hover:text-base-content/60 transition-colors"
            >
              <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12" />
              </svg>
            </button>
          </div>

          <div class="space-y-3">
            <.empty_users :if={@filtered_friends == [] && @friends_search != ""} type={:search} />
            <.empty_users :if={@friends == []} type={:friend} />
            <.user_card
              :for={user <- @filtered_friends}
              user={user}
              type={:friend}
              current_user={@current_user}
            />
          </div>
        </div>

        <.user_list
          :if={@active_tab == :pending}
          users={@pending_requests}
          type={:pending}
          current_user={@current_user}
        />

        <.user_list
          :if={@active_tab == :sent}
          users={@sent_requests}
          type={:sent}
          current_user={@current_user}
        />

        <!-- Discover tab with search + pagination -->
        <div :if={@active_tab == :discover}>
          <!-- Search bar -->
          <div class="relative mb-4">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 absolute left-3.5 top-1/2 -translate-y-1/2 text-base-content/40" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
              <path stroke-linecap="round" stroke-linejoin="round" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
            </svg>
            <input
              type="text"
              value={@discover_search}
              phx-keyup="search_discover"
              phx-debounce="300"
              placeholder="Rechercher un pseudo ou email..."
              class="w-full pl-10 pr-4 py-2.5 bg-base-100 border border-base-300 rounded-xl text-sm focus:outline-none focus:border-pink-400 transition-all"
            />
            <button
              :if={@discover_search != ""}
              type="button"
              phx-click="clear_search"
              class="absolute right-3 top-1/2 -translate-y-1/2 text-base-content/30 hover:text-base-content/60 transition-colors"
            >
              <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12" />
              </svg>
            </button>
          </div>

          <!-- Results -->
          <div class="space-y-3">
            <.empty_users :if={@non_friends == []} type={:discover} />

            <.user_card
              :for={user <- @non_friends}
              user={user}
              type={:discover}
              current_user={@current_user}
            />
          </div>

          <!-- Load more button -->
          <div :if={@discover_has_more && @discover_search == ""} class="mt-4">
            <button
              phx-click="load_more_discover"
              class={"btn btn-ghost w-full border border-base-300 rounded-xl text-sm #{if @discover_loading, do: "loading", else: ""}"}
              disabled={@discover_loading}
            >
              <span :if={!@discover_loading}>Voir plus de personnes</span>
              <span :if={@discover_loading}>Chargement...</span>
            </button>
          </div>
        </div>
      </main>

      <.confirm_dialog
        :if={@confirm_action == :remove_friend}
        id="remove-friend-dialog"
        title="Retirer cet ami ?"
        message={"Vous ne pourrez plus voir les publications privées de #{@confirm_user_name}."}
        icon={:danger}
        confirm_text="Retirer"
        cancel_text="Annuler"
        confirm_event="confirm_remove_friend"
        on_cancel="close_confirm_dialog"
      />

      <.confirm_dialog
        :if={@confirm_action == :cancel_request}
        id="cancel-request-dialog"
        title="Annuler cette demande ?"
        message={"La demande d'ami envoyée à #{@confirm_user_name} sera annulée."}
        icon={:warning}
        confirm_text="Annuler la demande"
        cancel_text="Retour"
        confirm_event="confirm_cancel_request"
        confirm_style={:warning}
        on_cancel="close_confirm_dialog"
      />
    </div>
    """
  end

  # ============== EVENTS ==============

  @impl true
  def handle_event("change_tab", %{"tab" => tab}, socket) do
    socket =
      if tab == "discover" do
        load_discover(socket, 1, "")
      else
        socket
      end

    {:noreply, assign(socket, :active_tab, String.to_atom(tab))}
  end

  @impl true
  def handle_event("search_friends", %{"value" => query}, socket) do
    query = String.trim(query)
    filtered =
      if query == "" do
        socket.assigns.friends
      else
        search = String.downcase(query)
        Enum.filter(socket.assigns.friends, fn user ->
          String.downcase(user.name) |> String.contains?(search) ||
            String.downcase(user.email) |> String.contains?(search)
        end)
      end

    {:noreply,
     socket
     |> assign(:friends_search, query)
     |> assign(:filtered_friends, filtered)}
  end

  @impl true
  def handle_event("clear_friends_search", _, socket) do
    {:noreply,
     socket
     |> assign(:friends_search, "")
     |> assign(:filtered_friends, socket.assigns.friends)}
  end

  @impl true
  def handle_event("search_discover", %{"value" => query}, socket) do
    query = String.trim(query)
    user_id = socket.assigns.current_user.id

    if query == "" do
      {:noreply, load_discover(socket, 1, "")}
    else
      results = Social.search_non_friends(user_id, query)
      {:noreply,
       socket
       |> assign(:non_friends, results)
       |> assign(:discover_search, query)
       |> assign(:discover_has_more, false)}
    end
  end

  @impl true
  def handle_event("clear_search", _, socket) do
    {:noreply, load_discover(socket, 1, "")}
  end

  @impl true
  def handle_event("load_more_discover", _, socket) do
    user_id = socket.assigns.current_user.id
    next_page = socket.assigns.discover_page + 1

    {new_users, has_more} = Social.list_non_friends_paginated(user_id, next_page)

    {:noreply,
     socket
     |> assign(:non_friends, socket.assigns.non_friends ++ new_users)
     |> assign(:discover_page, next_page)
     |> assign(:discover_has_more, has_more)}
  end

  @impl true
  def handle_event("send_request", %{"id" => friend_id}, socket) do
    user_id = socket.assigns.current_user.id

    case Social.send_friend_request(user_id, String.to_integer(friend_id)) do
      {:ok, _} ->
        notify_user(friend_id, :request_received)
        Notifications.notify_friend_request(socket.assigns.current_user, String.to_integer(friend_id))
        {:noreply,
         socket
         |> put_flash(:info, "Demande envoyée !")
         |> load_data()}

      {:error, :already_exists} ->
        {:noreply, put_flash(socket, :error, "Demande déjà envoyée")}

      {:error, :daily_limit_reached} ->
        {:noreply, put_flash(socket, :error, "Vous avez atteint la limite de 20 demandes par jour")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Erreur")}
    end
  end

  @impl true
  def handle_event("accept_request", %{"id" => friendship_id}, socket) do
    user_id = socket.assigns.current_user.id

    case Social.accept_friend_request(String.to_integer(friendship_id), user_id) do
      {:ok, friendship} ->
        notify_user(friendship.user_id, :request_accepted)
        Notifications.notify_friend_accepted(socket.assigns.current_user, friendship.user_id)
        {:noreply,
         socket
         |> put_flash(:info, "Ami ajouté !")
         |> load_data()}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Erreur")}
    end
  end

  @impl true
  def handle_event("reject_request", %{"id" => friendship_id}, socket) do
    user_id = socket.assigns.current_user.id

    case Social.reject_friend_request(String.to_integer(friendship_id), user_id) do
      {:ok, friendship} ->
        notify_user(friendship.user_id, :request_rejected)
        {:noreply,
         socket
         |> put_flash(:info, "Demande refusée")
         |> load_data()}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Erreur")}
    end
  end

  @impl true
  def handle_event("show_remove_friend_confirm", %{"id" => id, "name" => name}, socket) do
    {:noreply,
     socket
     |> assign(:confirm_action, :remove_friend)
     |> assign(:confirm_user_id, id)
     |> assign(:confirm_user_name, name)}
  end

  @impl true
  def handle_event("confirm_remove_friend", _params, socket) do
    user_id = socket.assigns.current_user.id
    friend_id = socket.assigns.confirm_user_id

    case Social.remove_friend(user_id, String.to_integer(friend_id)) do
      {:ok, _} ->
        notify_user(friend_id, :friend_removed)
        {:noreply,
         socket
         |> assign(:confirm_action, nil)
         |> put_flash(:info, "Ami retiré")
         |> load_data()}

      {:error, _} ->
        {:noreply,
         socket
         |> assign(:confirm_action, nil)
         |> put_flash(:error, "Erreur")}
    end
  end

  @impl true
  def handle_event("show_cancel_request_confirm", %{"id" => id, "name" => name}, socket) do
    {:noreply,
     socket
     |> assign(:confirm_action, :cancel_request)
     |> assign(:confirm_user_id, id)
     |> assign(:confirm_user_name, name)}
  end

  @impl true
  def handle_event("confirm_cancel_request", _params, socket) do
    user_id = socket.assigns.current_user.id
    friend_id_int = String.to_integer(socket.assigns.confirm_user_id)

    case Social.cancel_friend_request(user_id, friend_id_int) do
      {:ok, _} ->
        notify_user(friend_id_int, :request_cancelled)
        {:noreply,
         socket
         |> assign(:confirm_action, nil)
         |> put_flash(:info, "Demande annulée")
         |> load_data()}

      {:error, _} ->
        {:noreply,
         socket
         |> assign(:confirm_action, nil)
         |> put_flash(:error, "Erreur")}
    end
  end

  @impl true
  def handle_event("close_confirm_dialog", _params, socket) do
    {:noreply,
     socket
     |> assign(:confirm_action, nil)
     |> assign(:confirm_user_id, nil)
     |> assign(:confirm_user_name, nil)}
  end

  # ============== NOTIFICATION EVENTS ==============

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
  def handle_info({:friendship_update, _}, socket) do
    {:noreply, load_data(socket)}
  end

  @impl true
  def handle_info({:new_message, _message}, socket) do
    user_id = socket.assigns.current_user.id
    unread_count = Chat.count_total_unread(user_id)
    {:noreply, assign(socket, :unread_messages_count, unread_count)}
  end

  @impl true
  def handle_info({:friend_request_received, _}, socket) do
    {:noreply, load_data(socket)}
  end

  @impl true
  def handle_info({:friend_request_updated, _}, socket) do
    {:noreply, load_data(socket)}
  end

  @impl true
  def handle_info({:friend_request_accepted, _}, socket) do
    {:noreply, load_data(socket)}
  end

  @impl true
  def handle_info({:new_notification, notification}, socket) do
    notifications = [notification | socket.assigns.notifications]
    unread_count = socket.assigns.unread_notifications_count + 1

    {:noreply,
     socket
     |> assign(:notifications, notifications)
     |> assign(:unread_notifications_count, unread_count)}
  end

  @impl true
  def handle_info(_msg, socket) do
    {:noreply, socket}
  end

  # ============== HELPERS ==============

  defp load_data(socket) do
    user_id = socket.assigns.current_user.id

    friends = Social.list_friends(user_id)
    pending = Social.list_pending_requests(user_id)
    sent = Social.list_sent_requests(user_id)

    pending_with_id =
      Enum.map(pending, fn f ->
        Map.put(f.user, :friendship_id, f.id)
      end)

    sent_users = Enum.map(sent, fn f -> f.friend end)

    friends_search = socket.assigns[:friends_search] || ""
    filtered =
      if friends_search == "" do
        friends
      else
        search = String.downcase(friends_search)
        Enum.filter(friends, fn user ->
          String.downcase(user.name) |> String.contains?(search) ||
            String.downcase(user.email) |> String.contains?(search)
        end)
      end

    socket
    |> assign(:friends, friends)
    |> assign(:filtered_friends, filtered)
    |> assign(:pending_requests, pending_with_id)
    |> assign(:sent_requests, sent_users)
    |> assign(:pending_count, length(pending))
    |> assign(:sent_count, length(sent))
    |> load_discover(socket.assigns[:discover_page] || 1, socket.assigns[:discover_search] || "")
  end

  defp load_discover(socket, page, search) do
    user_id = socket.assigns.current_user.id

    if search != "" do
      results = Social.search_non_friends(user_id, search)
      socket
      |> assign(:non_friends, results)
      |> assign(:discover_search, search)
      |> assign(:discover_page, 1)
      |> assign(:discover_has_more, false)
    else
      {users, has_more} = Social.list_non_friends_paginated(user_id, 1, 20)
      # When loading fresh, reset to page 1 with first batch
      all_users =
        if page > 1 do
          # Reload all pages up to current
          Enum.reduce(1..page, [], fn p, acc ->
            {batch, _} = Social.list_non_friends_paginated(user_id, p, 20)
            acc ++ batch
          end)
        else
          users
        end

      has_more_final = if page > 1 do
        {_, hm} = Social.list_non_friends_paginated(user_id, page, 20)
        hm
      else
        has_more
      end

      socket
      |> assign(:non_friends, all_users)
      |> assign(:discover_search, "")
      |> assign(:discover_page, page)
      |> assign(:discover_has_more, has_more_final)
    end
  end

  defp tab_from_params(%{"tab" => "pending"}), do: :pending
  defp tab_from_params(%{"tab" => "sent"}), do: :sent
  defp tab_from_params(%{"tab" => "discover"}), do: :discover
  defp tab_from_params(%{"tab" => "friends"}), do: :friends
  defp tab_from_params(_), do: :friends

  defp notify_user(user_id, event) do
    Phoenix.PubSub.broadcast(
      MonApp.PubSub,
      "#{@topic}:#{user_id}",
      {:friendship_update, event}
    )
  end
end
