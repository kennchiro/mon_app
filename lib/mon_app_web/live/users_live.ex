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

      Phoenix.PubSub.subscribe(MonApp.PubSub, "#{@topic}:#{user_id}")
      # S'abonner aux notifications de nouveaux messages
      Phoenix.PubSub.subscribe(MonApp.PubSub, "user:#{user_id}")
    end

    unread_messages_count = Chat.count_total_unread(user_id)

    {:ok,
     socket
     |> assign(:active_tab, :friends)
     |> assign(:unread_messages_count, unread_messages_count)
     |> assign(:confirm_action, nil)
     |> assign(:confirm_user_id, nil)
     |> assign(:confirm_user_name, nil)
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

        <.user_tabs active_tab={@active_tab} pending_count={@pending_count} sent_count={@sent_count} />

        <.user_list
          :if={@active_tab == :friends}
          users={@friends}
          type={:friend}
          current_user={@current_user}
        />

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

        <.user_list
          :if={@active_tab == :discover}
          users={@non_friends}
          type={:discover}
          current_user={@current_user}
        />
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
    {:noreply, assign(socket, :active_tab, String.to_atom(tab))}
  end

  @impl true
  def handle_event("send_request", %{"id" => friend_id}, socket) do
    user_id = socket.assigns.current_user.id

    case Social.send_friend_request(user_id, String.to_integer(friend_id)) do
      {:ok, _} ->
        notify_user(friend_id, :request_received)
        {:noreply,
         socket
         |> put_flash(:info, "Demande envoyée !")
         |> load_data()}

      {:error, :already_exists} ->
        {:noreply, put_flash(socket, :error, "Demande déjà envoyée")}

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
        # Notifier l'envoyeur que sa demande a été refusée
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
    # Incrémenter le compteur de messages non lus
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
    non_friends = Social.list_non_friends(user_id)

    # Ajouter friendship_id aux pending pour les boutons
    pending_with_id =
      Enum.map(pending, fn f ->
        Map.put(f.user, :friendship_id, f.id)
      end)

    # Extraire les users des demandes envoyées
    sent_users = Enum.map(sent, fn f -> f.friend end)

    socket
    |> assign(:friends, friends)
    |> assign(:pending_requests, pending_with_id)
    |> assign(:sent_requests, sent_users)
    |> assign(:non_friends, non_friends)
    |> assign(:pending_count, length(pending))
    |> assign(:sent_count, length(sent))
  end

  defp notify_user(user_id, event) do
    Phoenix.PubSub.broadcast(
      MonApp.PubSub,
      "#{@topic}:#{user_id}",
      {:friendship_update, event}
    )
  end
end
