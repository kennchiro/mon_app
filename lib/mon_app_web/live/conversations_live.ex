defmodule MonAppWeb.ConversationsLive do
  use MonAppWeb, :live_view

  import Ecto.Query

  alias MonApp.Chat
  alias MonApp.Chat.Conversation
  alias MonApp.Social
  alias MonApp.Repo
  alias MonAppWeb.Presence

  import MonAppWeb.Navbar
  import MonAppWeb.ChatComponents

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_user

    if connected?(socket) do
      # Tracker la présence de l'utilisateur
      {:ok, _} = Presence.track(self(), "users:online", to_string(user.id), %{
        user_id: user.id,
        name: user.name,
        online_at: System.system_time(:second)
      })

      # S'abonner aux mises à jour de présence
      Phoenix.PubSub.subscribe(MonApp.PubSub, "users:online")
      # S'abonner aux notifications de messages
      Phoenix.PubSub.subscribe(MonApp.PubSub, "user:#{user.id}")
    end

    conversations = Chat.list_conversations(user.id)
    online_users = Presence.list_online_users()
    unread_count = Chat.count_total_unread(user.id)
    pending_count = length(Social.list_pending_requests(user.id))
    friends = Social.list_friends(user.id)

    {:ok,
     socket
     |> assign(:conversations, conversations)
     |> assign(:online_users, online_users)
     |> assign(:unread_count, unread_count)
     |> assign(:pending_requests_count, pending_count)
     |> assign(:friends, friends)
     |> assign(:show_new_conversation, false)
     |> assign(:active_conversation, nil)
     |> assign(:active_messages, [])
     |> assign(:active_other_user, nil)
     |> assign(:typing, false)
     |> assign(:form, to_form(%{"body" => ""}))}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class={["min-h-screen bg-base-200", @active_conversation && "chat-open"]}>
      <!-- Navbar cachée sur mobile quand le chat est ouvert -->
      <div class={@active_conversation && "hidden md:block"}>
        <.navbar current_user={@current_user} current_path="/conversations" pending_requests_count={@pending_requests_count} unread_messages_count={@unread_count} />
      </div>

      <main class="max-w-2xl mx-auto pb-safe">
        <!-- Header - caché sur mobile quand le chat est ouvert -->
        <div class={["bg-base-100 border-b border-base-200 sticky top-0 z-10", @active_conversation && "hidden md:block"]}>
          <div class="flex items-center justify-between p-4">
            <h1 class="text-xl font-bold">Messages</h1>
            <button
              type="button"
              phx-click="open_new_conversation"
              class="btn btn-primary btn-sm gap-2"
            >
              <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" />
              </svg>
              <span class="hidden sm:inline">Nouveau</span>
            </button>
          </div>
        </div>

        <!-- Liste des conversations - cachée sur mobile quand le chat est ouvert -->
        <div class={["bg-base-100 min-h-[50vh]", @active_conversation && "hidden md:block"]}>
          <.conversation_list
            conversations={@conversations}
            current_user={@current_user}
            online_users={@online_users}
          />
        </div>

        <!-- Modal nouvelle conversation -->
        <.new_conversation_modal
          :if={@show_new_conversation}
          friends={@friends}
          online_users={@online_users}
        />

        <!-- Chat Bottom Sheet -->
        <.chat_bottom_sheet
          :if={@active_conversation}
          other_user={@active_other_user}
          messages={@active_messages}
          current_user={@current_user}
          online={@active_other_user && @active_other_user.id in @online_users}
          typing={@typing}
          form={@form}
        />
      </main>
    </div>
    """
  end

  # ============== EVENTS ==============

  @impl true
  def handle_event("open_new_conversation", _, socket) do
    {:noreply, assign(socket, :show_new_conversation, true)}
  end

  @impl true
  def handle_event("close_new_conversation", _, socket) do
    {:noreply, assign(socket, :show_new_conversation, false)}
  end

  @impl true
  def handle_event("open_chat", %{"id" => conversation_id}, socket) do
    user = socket.assigns.current_user
    conversation_id = String.to_integer(conversation_id)

    conversation = Chat.get_conversation(conversation_id)

    if conversation && Chat.user_in_conversation?(conversation_id, user.id) do
      other_user = Conversation.other_user(conversation, user.id)
      messages = Chat.list_messages(conversation_id)

      # S'abonner au channel de la conversation
      Phoenix.PubSub.subscribe(MonApp.PubSub, "chat:#{conversation_id}")

      # Marquer les messages comme vus
      Chat.mark_conversation_as_seen(conversation_id, user.id)
      notify_messages_seen(conversation_id, user.id, other_user.id)

      # Rafraîchir les conversations pour mettre à jour les compteurs
      conversations = Chat.list_conversations(user.id)
      unread_count = Chat.count_total_unread(user.id)

      {:noreply,
       socket
       |> assign(:active_conversation, conversation)
       |> assign(:active_messages, messages)
       |> assign(:active_other_user, other_user)
       |> assign(:conversations, conversations)
       |> assign(:unread_count, unread_count)
       |> assign(:form, to_form(%{"body" => ""}))}
    else
      {:noreply, put_flash(socket, :error, "Conversation non trouvée")}
    end
  end

  @impl true
  def handle_event("close_chat", _, socket) do
    # Se désabonner du channel de la conversation
    if socket.assigns.active_conversation do
      Phoenix.PubSub.unsubscribe(MonApp.PubSub, "chat:#{socket.assigns.active_conversation.id}")
    end

    {:noreply,
     socket
     |> assign(:active_conversation, nil)
     |> assign(:active_messages, [])
     |> assign(:active_other_user, nil)
     |> assign(:typing, false)}
  end

  @impl true
  def handle_event("start_conversation", %{"user-id" => friend_id}, socket) do
    user = socket.assigns.current_user
    friend_id = String.to_integer(friend_id)

    case Chat.get_or_create_conversation(user.id, friend_id) do
      {:ok, conversation} ->
        # Ouvrir la conversation dans la bottom sheet
        other_user = Conversation.other_user(conversation, user.id)
        messages = Chat.list_messages(conversation.id)

        # S'abonner au channel
        Phoenix.PubSub.subscribe(MonApp.PubSub, "chat:#{conversation.id}")

        # Rafraîchir les conversations
        conversations = Chat.list_conversations(user.id)

        {:noreply,
         socket
         |> assign(:show_new_conversation, false)
         |> assign(:active_conversation, conversation)
         |> assign(:active_messages, messages)
         |> assign(:active_other_user, other_user)
         |> assign(:conversations, conversations)
         |> assign(:form, to_form(%{"body" => ""}))}

      {:error, :not_friends} ->
        {:noreply, put_flash(socket, :error, "Vous devez être amis pour discuter")}
    end
  end

  @impl true
  def handle_event("send_message", %{"message" => %{"body" => body}}, socket) do
    body = String.trim(body)

    if body == "" do
      {:noreply, socket}
    else
      user = socket.assigns.current_user
      conversation = socket.assigns.active_conversation
      other_user = socket.assigns.active_other_user

      case Chat.create_message(%{
        body: body,
        conversation_id: conversation.id,
        sender_id: user.id
      }) do
        {:ok, message} ->
          # Broadcast le nouveau message
          Phoenix.PubSub.broadcast(
            MonApp.PubSub,
            "chat:#{conversation.id}",
            {:new_message, message}
          )

          # Notifier l'autre utilisateur
          Phoenix.PubSub.broadcast(
            MonApp.PubSub,
            "user:#{other_user.id}",
            {:new_message, message}
          )

          {:noreply, assign(socket, :form, to_form(%{"body" => ""}))}

        {:error, _changeset} ->
          {:noreply, put_flash(socket, :error, "Erreur lors de l'envoi")}
      end
    end
  end

  @impl true
  def handle_event("typing", %{"message" => %{"body" => body}}, socket) do
    conversation = socket.assigns.active_conversation

    if conversation do
      user = socket.assigns.current_user
      is_typing = String.trim(body) != ""

      Phoenix.PubSub.broadcast(
        MonApp.PubSub,
        "chat:#{conversation.id}",
        {:typing, user.id, is_typing}
      )
    end

    {:noreply, socket}
  end

  # ============== PUBSUB HANDLERS ==============

  @impl true
  def handle_info(%{event: "presence_diff"}, socket) do
    online_users = Presence.list_online_users()
    {:noreply, assign(socket, :online_users, online_users)}
  end

  @impl true
  def handle_info({:new_message, message}, socket) do
    user = socket.assigns.current_user
    active_conversation = socket.assigns.active_conversation

    # Recharger les conversations
    conversations = Chat.list_conversations(user.id)
    unread_count = Chat.count_total_unread(user.id)

    socket =
      socket
      |> assign(:conversations, conversations)
      |> assign(:unread_count, unread_count)

    # Si la conversation active correspond au message, l'ajouter
    if active_conversation && message.conversation_id == active_conversation.id do
      messages = socket.assigns.active_messages

      if Enum.any?(messages, &(&1.id == message.id)) do
        {:noreply, socket}
      else
        # Si le message vient de l'autre personne, le marquer comme vu
        socket =
          if message.sender_id != user.id do
            Chat.mark_conversation_as_seen(active_conversation.id, user.id)
            notify_messages_seen(active_conversation.id, user.id, message.sender_id)
            # Rafraîchir le compteur après avoir marqué comme vu
            new_unread_count = Chat.count_total_unread(user.id)
            assign(socket, :unread_count, new_unread_count)
          else
            socket
          end

        {:noreply,
         socket
         |> assign(:active_messages, messages ++ [message])
         |> assign(:typing, false)
         |> push_event("scroll_to_bottom", %{})}
      end
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:typing, sender_id, is_typing}, socket) do
    other_user = socket.assigns.active_other_user

    if other_user && sender_id == other_user.id do
      {:noreply, assign(socket, :typing, is_typing)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:messages_seen, message_ids}, socket) do
    # Mettre à jour les statuts des messages dans la bottom sheet
    if socket.assigns.active_conversation do
      messages =
        Enum.map(socket.assigns.active_messages, fn msg ->
          if msg.id in message_ids do
            %{msg | status: "seen"}
          else
            msg
          end
        end)

      {:noreply, assign(socket, :active_messages, messages)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_info(_msg, socket) do
    {:noreply, socket}
  end

  # ============== HELPERS ==============

  defp notify_messages_seen(conv_id, _user_id, other_user_id) do
    message_ids =
      MonApp.Chat.Message
      |> where([m], m.conversation_id == ^conv_id)
      |> where([m], m.sender_id == ^other_user_id)
      |> where([m], m.status == "seen")
      |> select([m], m.id)
      |> Repo.all()

    if message_ids != [] do
      Phoenix.PubSub.broadcast(
        MonApp.PubSub,
        "user:#{other_user_id}",
        {:messages_seen, message_ids}
      )
    end
  end
end
