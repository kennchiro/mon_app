defmodule MonAppWeb.ChatDrawer do
  @moduledoc """
  Composant réutilisable et autonome de drawer de messagerie.
  Utilise exactement les mêmes composants que le chat complet :
  message_list, message_bubble, reactions, reply, delete, context menu, etc.

  Usage dans un parent LiveView :
    <.live_component
      module={MonAppWeb.ChatDrawer}
      id="chat-drawer"
      open={@chat_drawer_open}
      conversation={@chat_conversation}
      other_user={@profile_user}
      current_user={@current_user}
    />

  Le parent doit :
  - Gérer "close_chat_drawer" event
  - Forwarder les PubSub messages via send_update :
    - send_update(MonAppWeb.ChatDrawer, id: "chat-drawer", new_message: message)
    - send_update(MonAppWeb.ChatDrawer, id: "chat-drawer", typing: {sender_id, is_typing})
    - send_update(MonAppWeb.ChatDrawer, id: "chat-drawer", messages_seen: message_ids)
    - send_update(MonAppWeb.ChatDrawer, id: "chat-drawer", reaction_added: {message_id, reaction})
    - send_update(MonAppWeb.ChatDrawer, id: "chat-drawer", reaction_removed: {message_id, reaction})
    - send_update(MonAppWeb.ChatDrawer, id: "chat-drawer", message_deleted: {message_id, deleted_at})
  """
  use MonAppWeb, :live_component

  alias MonApp.Chat
  alias MonAppWeb.Presence

  import MonAppWeb.ChatComponents

  # ============== LIFECYCLE ==============

  @impl true
  def update(%{new_message: message}, socket) do
    user = socket.assigns.current_user
    messages = socket.assigns.messages

    # Éviter les doublons
    if Enum.any?(messages, &(&1.id == message.id)) do
      {:ok, socket}
    else
      # Recharger le message avec reply_to si nécessaire
      message =
        if message.reply_to_id && !Ecto.assoc_loaded?(message.reply_to) do
          Chat.get_message_with_reply(message.id)
        else
          message
        end

      # Si le message vient de l'autre personne et drawer est ouvert, marquer comme vu
      socket =
        if socket.assigns.open && message.sender_id != user.id && socket.assigns.conversation do
          Chat.mark_conversation_as_seen(socket.assigns.conversation.id, user.id)
          socket
        else
          socket
        end

      {:ok,
       socket
       |> assign(:messages, messages ++ [message])
       |> assign(:typing, false)}
    end
  end

  def update(%{typing: {sender_id, is_typing}}, socket) do
    other_user = socket.assigns[:other_user]
    if other_user && sender_id == other_user.id do
      {:ok, assign(socket, :typing, is_typing)}
    else
      {:ok, socket}
    end
  end

  def update(%{messages_seen: message_ids}, socket) do
    messages =
      Enum.map(socket.assigns.messages, fn msg ->
        if msg.id in message_ids, do: %{msg | status: "seen"}, else: msg
      end)
    {:ok, assign(socket, :messages, messages)}
  end

  def update(%{reaction_added: {message_id, reaction}}, socket) do
    messages =
      Enum.map(socket.assigns.messages, fn msg ->
        if msg.id == message_id do
          existing = msg.reactions || []
          if Enum.any?(existing, &(&1.id == reaction.id)),
            do: msg,
            else: %{msg | reactions: existing ++ [reaction]}
        else
          msg
        end
      end)
    {:ok, assign(socket, :messages, messages)}
  end

  def update(%{reaction_removed: {message_id, reaction}}, socket) do
    messages =
      Enum.map(socket.assigns.messages, fn msg ->
        if msg.id == message_id do
          existing = msg.reactions || []
          updated = Enum.reject(existing, fn r ->
            r.user_id == reaction.user_id && r.emoji == reaction.emoji
          end)
          %{msg | reactions: updated}
        else
          msg
        end
      end)
    {:ok, assign(socket, :messages, messages)}
  end

  def update(%{message_deleted: {message_id, deleted_at}}, socket) do
    messages =
      Enum.map(socket.assigns.messages, fn msg ->
        if msg.id == message_id, do: %{msg | deleted_for_all_at: deleted_at}, else: msg
      end)
    {:ok, assign(socket, :messages, messages)}
  end

  def update(%{forward_event: {event, params}}, socket) do
    # Events forwardés par le parent LiveView (provenant des function components)
    {:noreply, socket} = handle_event(event, params, socket)
    {:ok, socket}
  end

  def update(assigns, socket) do
    socket = assign(socket, assigns)

    # Charger les messages seulement à l'ouverture initiale ou quand la conversation change
    socket =
      if assigns[:conversation] && (
        !Map.get(socket.assigns, :loaded_conversation_id) ||
        socket.assigns.loaded_conversation_id != assigns.conversation.id
      ) do
        messages = Chat.list_messages_with_replies(
          assigns.conversation.id,
          limit: 30,
          user_id: assigns.current_user.id
        )

        # Marquer les messages comme lus
        Chat.mark_conversation_as_seen(assigns.conversation.id, assigns.current_user.id)

        online = if assigns[:other_user], do: Presence.user_online?(assigns.other_user.id), else: false

        socket
        |> assign(:messages, messages)
        |> assign(:loaded_conversation_id, assigns.conversation.id)
        |> assign(:online, online)
      else
        socket
      end

    # Initialiser les assigns par défaut
    socket =
      if !Map.has_key?(socket.assigns, :messages) do
        socket
        |> assign(:messages, [])
        |> assign(:form, to_form(%{"body" => ""}))
        |> assign(:typing, false)
        |> assign(:online, false)
        |> assign(:reply_message, nil)
        |> assign(:reaction_picker_message_id, nil)
        |> assign(:context_menu_message, nil)
        |> assign(:delete_modal_message, nil)
        |> assign(:preview_image, nil)
      else
        socket
      end

    {:ok, socket}
  end

  # ============== EVENTS ==============

  @impl true
  def handle_event("send_message", %{"message" => %{"body" => body}}, socket) do
    body = String.trim(body)

    if body == "" || !socket.assigns.conversation do
      {:noreply, socket}
    else
      conversation = socket.assigns.conversation
      current_user = socket.assigns.current_user
      other_user = socket.assigns.other_user

      attrs = %{
        body: body,
        conversation_id: conversation.id,
        sender_id: current_user.id
      }

      # Ajouter reply_to_id si on répond à un message
      attrs =
        if socket.assigns.reply_message do
          Map.put(attrs, :reply_to_id, socket.assigns.reply_message.id)
        else
          attrs
        end

      case Chat.create_message(attrs) do
        {:ok, message} ->
          Phoenix.PubSub.broadcast(
            MonApp.PubSub,
            "chat:#{conversation.id}",
            {:new_message, message}
          )

          Phoenix.PubSub.broadcast(
            MonApp.PubSub,
            "user:#{other_user.id}",
            {:new_message, message}
          )

          {:noreply, assign(socket, :reply_message, nil)}

        {:error, _changeset} ->
          {:noreply, socket}
      end
    end
  end

  @impl true
  def handle_event("validate_chat", _params, socket) do
    {:noreply, socket}
  end

  # ============== REPLY EVENTS ==============

  @impl true
  def handle_event("reply_to_message", %{"id" => message_id}, socket) do
    message_id = String.to_integer(message_id)
    message = Chat.get_message(message_id)

    {:noreply,
     socket
     |> assign(:reply_message, message)
     |> assign(:context_menu_message, nil)}
  end

  @impl true
  def handle_event("cancel_reply", _, socket) do
    {:noreply, assign(socket, :reply_message, nil)}
  end

  @impl true
  def handle_event("scroll_to_message", %{"id" => message_id}, socket) do
    {:noreply, push_event(socket, "scroll_to_message", %{id: message_id})}
  end

  # ============== REACTION EVENTS ==============

  @impl true
  def handle_event("open_reaction_picker", %{"id" => message_id}, socket) do
    message_id = String.to_integer(message_id)
    {:noreply, assign(socket, :reaction_picker_message_id, message_id)}
  end

  @impl true
  def handle_event("close_reaction_picker", _, socket) do
    {:noreply, assign(socket, :reaction_picker_message_id, nil)}
  end

  @impl true
  def handle_event("toggle_reaction", %{"message-id" => message_id, "emoji" => emoji}, socket) do
    user = socket.assigns.current_user
    message_id = String.to_integer(message_id)

    Chat.toggle_reaction(message_id, user.id, emoji)

    {:noreply,
     socket
     |> assign(:context_menu_message, nil)
     |> assign(:reaction_picker_message_id, nil)}
  end

  # ============== CONTEXT MENU EVENTS ==============

  @impl true
  def handle_event("open_context_menu", %{"id" => message_id}, socket) do
    message_id = String.to_integer(message_id)
    message = Chat.get_message(message_id)
    {:noreply, assign(socket, :context_menu_message, message)}
  end

  @impl true
  def handle_event("close_context_menu", _, socket) do
    {:noreply, assign(socket, :context_menu_message, nil)}
  end

  @impl true
  def handle_event("copy_message", %{"id" => message_id}, socket) do
    message_id = String.to_integer(message_id)
    message = Chat.get_message(message_id)

    if message && message.body do
      {:noreply,
       socket
       |> assign(:context_menu_message, nil)
       |> push_event("copy_to_clipboard", %{text: message.body})}
    else
      {:noreply, assign(socket, :context_menu_message, nil)}
    end
  end

  @impl true
  def handle_event("forward_message", %{"id" => _message_id}, socket) do
    {:noreply, assign(socket, :context_menu_message, nil)}
  end

  # ============== DELETE EVENTS ==============

  @impl true
  def handle_event("open_delete_modal", %{"id" => message_id}, socket) do
    message_id = String.to_integer(message_id)
    message = Chat.get_message(message_id)

    {:noreply,
     socket
     |> assign(:context_menu_message, nil)
     |> assign(:delete_modal_message, message)}
  end

  @impl true
  def handle_event("close_delete_modal", _, socket) do
    {:noreply, assign(socket, :delete_modal_message, nil)}
  end

  @impl true
  def handle_event("delete_message_for_me", %{"id" => message_id}, socket) do
    user = socket.assigns.current_user
    message_id = String.to_integer(message_id)

    case Chat.delete_message_for_me(message_id, user.id) do
      {:ok, _} ->
        messages = Enum.reject(socket.assigns.messages, &(&1.id == message_id))

        {:noreply,
         socket
         |> assign(:messages, messages)
         |> assign(:delete_modal_message, nil)}

      {:error, _} ->
        {:noreply, assign(socket, :delete_modal_message, nil)}
    end
  end

  @impl true
  def handle_event("delete_message_for_all", %{"id" => message_id}, socket) do
    user = socket.assigns.current_user
    message_id = String.to_integer(message_id)

    case Chat.delete_message_for_all(message_id, user.id) do
      {:ok, updated_message} ->
        messages =
          Enum.map(socket.assigns.messages, fn msg ->
            if msg.id == message_id, do: updated_message, else: msg
          end)

        {:noreply,
         socket
         |> assign(:messages, messages)
         |> assign(:delete_modal_message, nil)}

      {:error, _} ->
        {:noreply, assign(socket, :delete_modal_message, nil)}
    end
  end

  # ============== IMAGE PREVIEW ==============

  @impl true
  def handle_event("open_image_preview", %{"src" => src}, socket) do
    {:noreply, assign(socket, :preview_image, src)}
  end

  @impl true
  def handle_event("close_image_preview", _, socket) do
    {:noreply, assign(socket, :preview_image, nil)}
  end

  # ============== CLOSE DRAWER ==============

  @impl true
  def handle_event("close_chat_drawer", _params, socket) do
    # Notifier le parent pour fermer le drawer
    send(self(), :close_chat_drawer)
    {:noreply, socket}
  end

  # ============== TYPING ==============

  @impl true
  def handle_event("typing", %{"message" => %{"body" => body}}, socket) do
    conversation = socket.assigns.conversation

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

  # ============== RENDER ==============

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <!-- Overlay -->
      <div
        :if={@open}
        class="fixed inset-0 bg-black/30 z-40"
        phx-click="close_chat_drawer"
      />

      <!-- Drawer flottant — aligné sous la navbar, marge symétrique en bas -->
      <div class={
        "fixed right-4 top-[4.5rem] bottom-6 w-full sm:w-96 bg-base-100 shadow-2xl z-50 flex flex-col transition-all duration-300 rounded-2xl overflow-hidden " <>
        "max-sm:right-0 max-sm:top-0 max-sm:bottom-0 max-sm:rounded-none " <>
        if @open, do: "translate-x-0 opacity-100", else: "translate-x-[110%] opacity-0"
      }>
        <!-- Header -->
        <div class="border-b border-base-200 bg-base-100 rounded-t-2xl max-sm:rounded-t-none">
          <div class="flex items-center gap-3 px-4 py-3 min-h-[60px]">
            <button phx-click="close_chat_drawer" class="btn btn-ghost btn-sm btn-circle shrink-0">
              <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
              </svg>
            </button>
            <%= if @other_user && @conversation do %>
              <div class="relative shrink-0">
                <.user_avatar name={@other_user.name} avatar={@other_user.avatar} size="w-11 h-11" />
                <span
                  :if={@online}
                  class="absolute bottom-0 right-0 h-3 w-3 rounded-full bg-success border-2 border-base-100"
                />
              </div>
              <div class="flex-1 min-w-0 py-0.5">
                <h2 class="font-semibold text-base truncate leading-tight">{@other_user.name}</h2>
                <p class="text-xs text-base-content/60 mt-0.5 leading-tight">
                  <%= cond do %>
                    <% @typing -> %>
                      <span class="text-primary">écrit...</span>
                    <% @online -> %>
                      En ligne
                    <% true -> %>
                      Hors ligne
                  <% end %>
                </p>
              </div>
            <% end %>
          </div>
        </div>

        <!-- Messages — utilise exactement le même composant que le chat complet -->
        <div
          class="flex-1 overflow-y-auto bg-base-200/30 overscroll-contain"
          id="drawer-messages"
          phx-hook="DrawerScrollBottom"
          phx-click="close_reaction_picker"
          phx-target={@myself}
        >
          <%= if @conversation do %>
            <.message_list
              messages={@messages}
              current_user={@current_user}
              reaction_picker_message_id={@reaction_picker_message_id}
            />
          <% end %>
        </div>

        <!-- Input — version compacte pour le drawer -->
        <%= if @conversation do %>
          <div class="sm:pb-1">
            <.chat_input
              form={@form}
              input_id="drawer-message-input"
              phx_target={@myself}
              reply_message={@reply_message}
              compact={true}
            />
          </div>
        <% end %>
      </div>

      <!-- Modal preview image -->
      <.image_preview_modal :if={@preview_image} src={@preview_image} />

      <!-- Context menu mobile (long press) -->
      <.message_context_menu
        :if={@context_menu_message}
        message={@context_menu_message}
        is_mine={@context_menu_message.sender_id == @current_user.id}
      />

      <!-- Delete modal -->
      <.delete_message_modal
        :if={@delete_modal_message}
        message={@delete_modal_message}
        is_mine={@delete_modal_message.sender_id == @current_user.id}
      />
    </div>
    """
  end
end
