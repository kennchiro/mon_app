defmodule MonAppWeb.ChatLive do
  use MonAppWeb, :live_view

  import Ecto.Query

  alias MonApp.Chat
  alias MonApp.Chat.Conversation
  alias MonApp.Repo
  alias MonAppWeb.Presence

  import MonAppWeb.ChatComponents

  @impl true
  def mount(%{"id" => conversation_id}, _session, socket) do
    user = socket.assigns.current_user
    conversation_id = String.to_integer(conversation_id)

    # Vérifier que l'utilisateur a accès à cette conversation
    conversation = Chat.get_conversation(conversation_id)

    if conversation && Chat.user_in_conversation?(conversation_id, user.id) do
      other_user = Conversation.other_user(conversation, user.id)

      if connected?(socket) do
        # Tracker la présence de l'utilisateur
        {:ok, _} = Presence.track(self(), "users:online", to_string(user.id), %{
          user_id: user.id,
          name: user.name,
          online_at: System.system_time(:second)
        })

        # S'abonner au channel de la conversation
        Phoenix.PubSub.subscribe(MonApp.PubSub, "chat:#{conversation_id}")
        # S'abonner à son propre channel pour les ACK
        Phoenix.PubSub.subscribe(MonApp.PubSub, "user:#{user.id}")
        # S'abonner aux updates de présence
        Phoenix.PubSub.subscribe(MonApp.PubSub, "users:online")

        # Marquer les messages comme vus
        Chat.mark_conversation_as_seen(conversation_id, user.id)

        # Notifier l'autre utilisateur que ses messages ont été vus
        notify_messages_seen(conversation_id, user.id, other_user.id)
      end

      messages = Chat.list_messages(conversation_id)
      online = Presence.user_online?(other_user.id)

      {:ok,
       socket
       |> assign(:conversation, conversation)
       |> assign(:other_user, other_user)
       |> assign(:messages, messages)
       |> assign(:online, online)
       |> assign(:typing, false)
       |> assign(:form, to_form(%{"body" => ""}))
       |> assign(:page_title, other_user.name)}
    else
      {:ok,
       socket
       |> put_flash(:error, "Conversation non trouvée")
       |> push_navigate(to: "/conversations")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="h-screen flex flex-col bg-base-100">
      <!-- Header -->
      <.chat_header
        other_user={@other_user}
        online={@online}
        typing={@typing}
      />

      <!-- Messages -->
      <div
        class="flex-1 overflow-y-auto bg-base-200/30"
        id="messages-container"
        phx-hook="ScrollToBottom"
      >
        <.message_list messages={@messages} current_user={@current_user} />
      </div>

      <!-- Input -->
      <.chat_input form={@form} />
    </div>
    """
  end

  @impl true
  def handle_event("send_message", %{"message" => %{"body" => body}}, socket) do
    body = String.trim(body)

    if body == "" do
      {:noreply, socket}
    else
      user = socket.assigns.current_user
      conversation = socket.assigns.conversation
      other_user = socket.assigns.other_user

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

          {:noreply,
           socket
           |> assign(:form, to_form(%{"body" => ""}))}

        {:error, _changeset} ->
          {:noreply, put_flash(socket, :error, "Erreur lors de l'envoi")}
      end
    end
  end

  @impl true
  def handle_event("typing", %{"message" => %{"body" => body}}, socket) do
    user = socket.assigns.current_user
    conversation = socket.assigns.conversation
    is_typing = String.trim(body) != ""

    # Broadcast le statut de frappe
    Phoenix.PubSub.broadcast(
      MonApp.PubSub,
      "chat:#{conversation.id}",
      {:typing, user.id, is_typing}
    )

    {:noreply, socket}
  end

  # ============== PUBSUB HANDLERS ==============

  @impl true
  def handle_info({:new_message, message}, socket) do
    user = socket.assigns.current_user
    conversation = socket.assigns.conversation

    # Ajouter le message s'il n'existe pas déjà
    messages = socket.assigns.messages

    if Enum.any?(messages, &(&1.id == message.id)) do
      {:noreply, socket}
    else
      # Si le message vient de l'autre personne, le marquer comme vu
      if message.sender_id != user.id do
        Chat.mark_conversation_as_seen(conversation.id, user.id)
        notify_messages_seen(conversation.id, user.id, message.sender_id)
      end

      {:noreply,
       socket
       |> assign(:messages, messages ++ [message])
       |> assign(:typing, false)
       |> push_event("scroll_to_bottom", %{})}
    end
  end

  @impl true
  def handle_info({:typing, sender_id, is_typing}, socket) do
    other_user = socket.assigns.other_user

    if sender_id == other_user.id do
      {:noreply, assign(socket, :typing, is_typing)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:message_delivered, message_id}, socket) do
    messages = update_message_status(socket.assigns.messages, message_id, "delivered")
    {:noreply, assign(socket, :messages, messages)}
  end

  @impl true
  def handle_info({:messages_delivered, message_ids}, socket) do
    messages =
      Enum.reduce(message_ids, socket.assigns.messages, fn id, msgs ->
        update_message_status(msgs, id, "delivered")
      end)
    {:noreply, assign(socket, :messages, messages)}
  end

  @impl true
  def handle_info({:message_seen, message_id}, socket) do
    messages = update_message_status(socket.assigns.messages, message_id, "seen")
    {:noreply, assign(socket, :messages, messages)}
  end

  @impl true
  def handle_info({:messages_seen, message_ids}, socket) do
    messages =
      Enum.reduce(message_ids, socket.assigns.messages, fn id, msgs ->
        update_message_status(msgs, id, "seen")
      end)
    {:noreply, assign(socket, :messages, messages)}
  end

  @impl true
  def handle_info(%{event: "presence_diff"}, socket) do
    other_user = socket.assigns.other_user
    online = Presence.user_online?(other_user.id)
    {:noreply, assign(socket, :online, online)}
  end

  @impl true
  def handle_info(_msg, socket) do
    {:noreply, socket}
  end

  # ============== HELPERS ==============

  defp update_message_status(messages, message_id, new_status) do
    Enum.map(messages, fn msg ->
      if msg.id == message_id do
        %{msg | status: new_status}
      else
        msg
      end
    end)
  end

  defp notify_messages_seen(conv_id, _user_id, other_user_id) do
    # Récupérer les IDs des messages qui viennent d'être marqués comme vus
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
