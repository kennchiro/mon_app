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
     |> assign(:modal_tab, "direct")
     |> assign(:selected_friends, [])
     |> assign(:group_name, "")
     |> assign(:modal_search_query, "")
     |> assign(:active_conversation, nil)
     |> assign(:active_messages, [])
     |> assign(:active_other_user, nil)
     |> assign(:active_display_name, nil)
     |> assign(:typing, false)
     |> assign(:form, to_form(%{"body" => ""}))
     |> assign(:filter, "all")
     |> assign(:search_query, "")
     |> assign(:preview_image, nil)
     |> allow_upload(:chat_images,
       accept: ~w(.jpg .jpeg .png .gif .webp),
       max_entries: 5,
       max_file_size: 10_000_000
     )}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class={["min-h-screen bg-base-100", @active_conversation && "chat-open"]}>
      <!-- Navbar cachée sur mobile quand le chat est ouvert -->
      <div class={@active_conversation && "hidden md:block"}>
        <.navbar current_user={@current_user} current_path="/conversations" pending_requests_count={@pending_requests_count} unread_messages_count={@unread_count} />
      </div>

      <main class="max-w-2xl mx-auto pb-safe">
        <!-- Header style Messenger - caché sur mobile quand le chat est ouvert -->
        <div class={["bg-base-100 sticky top-0 z-10", @active_conversation && "hidden md:block"]}>
          <!-- Titre et recherche sur la même ligne -->
          <div class="flex items-center gap-3 px-4 pt-4 pb-3">
            <h1 class="text-2xl font-bold shrink-0">Chats</h1>

            <!-- Barre de recherche -->
            <div class="flex-1 relative">
              <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 absolute left-3 top-1/2 -translate-y-1/2 text-base-content/40" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
              </svg>
              <input
                type="text"
                placeholder="Rechercher"
                class="w-full h-9 pl-9 pr-3 text-sm bg-base-200 border-none rounded-full focus:outline-none focus:ring-2 focus:ring-primary/20"
                phx-change="search"
                phx-debounce="300"
                name="query"
                value={@search_query}
              />
            </div>

            <!-- Bouton nouvelle conversation -->
            <button
              type="button"
              phx-click="open_new_conversation"
              class="btn btn-circle btn-sm bg-base-200 border-none hover:bg-base-300 shrink-0"
              title="Nouvelle conversation"
            >
              <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z" />
              </svg>
            </button>
          </div>

          <!-- Filtres -->
          <div class="flex gap-2 px-4 pb-3 overflow-x-auto scrollbar-hide">
            <button
              type="button"
              phx-click="filter"
              phx-value-filter="all"
              class={"px-4 py-1.5 rounded-full text-sm font-medium transition-colors " <>
                if @filter == "all", do: "bg-primary/15 text-primary", else: "bg-base-200 text-base-content/70 hover:bg-base-300"}
            >
              Tous
            </button>
            <button
              type="button"
              phx-click="filter"
              phx-value-filter="unread"
              class={"px-4 py-1.5 rounded-full text-sm font-medium transition-colors " <>
                if @filter == "unread", do: "bg-primary/15 text-primary", else: "bg-base-200 text-base-content/70 hover:bg-base-300"}
            >
              Non lus
            </button>
          </div>
        </div>

        <!-- Liste des conversations - cachée sur mobile quand le chat est ouvert -->
        <div class={["bg-base-100 min-h-[50vh]", @active_conversation && "hidden md:block"]}>
          <.conversation_list
            conversations={@conversations}
            current_user={@current_user}
            online_users={@online_users}
            filter={@filter}
          />
        </div>

        <!-- Modal nouvelle conversation -->
        <.new_conversation_modal
          :if={@show_new_conversation}
          friends={@friends}
          online_users={@online_users}
          modal_tab={@modal_tab}
          selected_friends={@selected_friends}
          group_name={@group_name}
          search_query={@modal_search_query}
        />

        <!-- Chat Bottom Sheet -->
        <.chat_bottom_sheet
          :if={@active_conversation}
          conversation={@active_conversation}
          display_name={@active_display_name}
          messages={@active_messages}
          current_user={@current_user}
          online={@active_other_user && @active_other_user.id in @online_users}
          typing={@typing}
          form={@form}
          uploads={@uploads}
          preview_image={@preview_image}
        />
      </main>
    </div>
    """
  end

  # ============== EVENTS ==============

  @impl true
  def handle_event("open_new_conversation", _, socket) do
    {:noreply,
     socket
     |> assign(:show_new_conversation, true)
     |> assign(:modal_tab, "direct")
     |> assign(:selected_friends, [])
     |> assign(:group_name, "")
     |> assign(:modal_search_query, "")}
  end

  @impl true
  def handle_event("close_new_conversation", _, socket) do
    {:noreply,
     socket
     |> assign(:show_new_conversation, false)
     |> assign(:selected_friends, [])
     |> assign(:group_name, "")
     |> assign(:modal_search_query, "")}
  end

  @impl true
  def handle_event("set_modal_tab", %{"tab" => tab}, socket) do
    {:noreply,
     socket
     |> assign(:modal_tab, tab)
     |> assign(:selected_friends, [])
     |> assign(:group_name, "")
     |> assign(:modal_search_query, "")}
  end

  @impl true
  def handle_event("toggle_friend_selection", %{"friend-id" => friend_id}, socket) do
    friend_id = String.to_integer(friend_id)
    friends = socket.assigns.friends
    selected = socket.assigns.selected_friends

    friend = Enum.find(friends, &(&1.id == friend_id))

    selected =
      if friend in selected do
        Enum.reject(selected, &(&1.id == friend_id))
      else
        selected ++ [friend]
      end

    {:noreply, assign(socket, :selected_friends, selected)}
  end

  @impl true
  def handle_event("update_group_name", %{"group_name" => name}, socket) do
    {:noreply, assign(socket, :group_name, name)}
  end

  @impl true
  def handle_event("search_modal_friends", %{"query" => query}, socket) do
    {:noreply, assign(socket, :modal_search_query, query)}
  end

  @impl true
  def handle_event("create_group", _, socket) do
    user = socket.assigns.current_user
    selected_friends = socket.assigns.selected_friends
    group_name = String.trim(socket.assigns.group_name)

    if length(selected_friends) < 2 || group_name == "" do
      {:noreply, put_flash(socket, :error, "Sélectionnez au moins 2 amis et donnez un nom au groupe")}
    else
      participant_ids = Enum.map(selected_friends, & &1.id)

      case Chat.create_group_conversation(user.id, participant_ids, group_name) do
        {:ok, conversation} ->
          # S'abonner au channel
          Phoenix.PubSub.subscribe(MonApp.PubSub, "chat:#{conversation.id}")

          # Rafraîchir les conversations
          conversations = Chat.list_conversations(user.id)
          messages = Chat.list_messages(conversation.id)

          {:noreply,
           socket
           |> assign(:show_new_conversation, false)
           |> assign(:selected_friends, [])
           |> assign(:group_name, "")
           |> assign(:active_conversation, conversation)
           |> assign(:active_messages, messages)
           |> assign(:active_other_user, nil)
           |> assign(:active_display_name, conversation.name)
           |> assign(:conversations, conversations)
           |> assign(:form, to_form(%{"body" => ""}))}

        {:error, :not_friends_with_all} ->
          {:noreply, put_flash(socket, :error, "Vous devez être ami avec tous les participants")}

        {:error, _} ->
          {:noreply, put_flash(socket, :error, "Erreur lors de la création du groupe")}
      end
    end
  end

  @impl true
  def handle_event("filter", %{"filter" => filter}, socket) do
    {:noreply, assign(socket, :filter, filter)}
  end

  @impl true
  def handle_event("search", %{"query" => query}, socket) do
    {:noreply, assign(socket, :search_query, query)}
  end

  @impl true
  def handle_event("open_chat", %{"id" => conversation_id}, socket) do
    user = socket.assigns.current_user
    conversation_id = String.to_integer(conversation_id)

    conversation = Chat.get_conversation(conversation_id)

    if conversation && Chat.user_in_conversation?(conversation_id, user.id) do
      messages = Chat.list_messages(conversation_id)

      # S'abonner au channel de la conversation
      Phoenix.PubSub.subscribe(MonApp.PubSub, "chat:#{conversation_id}")

      # Marquer les messages comme vus
      Chat.mark_conversation_as_seen(conversation_id, user.id)

      # Déterminer le nom à afficher et l'autre utilisateur (pour les chats 1-à-1)
      {display_name, other_user} = if conversation.is_group do
        {conversation.name, nil}
      else
        other_user = Conversation.other_user(conversation, user.id)
        notify_messages_seen(conversation_id, user.id, other_user.id)
        {other_user.name, other_user}
      end

      # Rafraîchir les conversations pour mettre à jour les compteurs
      conversations = Chat.list_conversations(user.id)
      unread_count = Chat.count_total_unread(user.id)

      {:noreply,
       socket
       |> assign(:active_conversation, conversation)
       |> assign(:active_messages, messages)
       |> assign(:active_other_user, other_user)
       |> assign(:active_display_name, display_name)
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
     |> assign(:active_display_name, nil)
     |> assign(:typing, false)
     |> assign(:preview_image, nil)}
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
         |> assign(:active_display_name, other_user.name)
         |> assign(:conversations, conversations)
         |> assign(:form, to_form(%{"body" => ""}))}

      {:error, :not_friends} ->
        {:noreply, put_flash(socket, :error, "Vous devez être amis pour discuter")}
    end
  end

  @impl true
  def handle_event("send_message", %{"message" => %{"body" => body}}, socket) do
    body = String.trim(body)
    has_images = socket.assigns.uploads.chat_images.entries != []

    if body == "" && !has_images do
      {:noreply, socket}
    else
      user = socket.assigns.current_user
      conversation = socket.assigns.active_conversation

      case Chat.create_message(%{
        body: if(body == "", do: nil, else: body),
        conversation_id: conversation.id,
        sender_id: user.id
      }) do
        {:ok, message} ->
          # Sauvegarder les images uploadées
          save_chat_images(socket, message.id)

          # Recharger le message avec les attachements
          message = Chat.get_message(message.id)

          # Broadcast le nouveau message au channel de la conversation
          Phoenix.PubSub.broadcast(
            MonApp.PubSub,
            "chat:#{conversation.id}",
            {:new_message, message}
          )

          # Notifier les participants
          if conversation.is_group do
            # Pour les groupes, notifier tous les participants sauf l'expéditeur
            Enum.each(conversation.participants || [], fn participant ->
              if participant.user_id != user.id do
                Phoenix.PubSub.broadcast(
                  MonApp.PubSub,
                  "user:#{participant.user_id}",
                  {:new_message, message}
                )
              end
            end)
          else
            # Pour les 1-à-1, notifier l'autre utilisateur
            other_user = socket.assigns.active_other_user
            if other_user do
              Phoenix.PubSub.broadcast(
                MonApp.PubSub,
                "user:#{other_user.id}",
                {:new_message, message}
              )
            end
          end

          {:noreply, assign(socket, :form, to_form(%{"body" => ""}))}

        {:error, _changeset} ->
          {:noreply, put_flash(socket, :error, "Erreur lors de l'envoi")}
      end
    end
  end

  @impl true
  def handle_event("cancel-chat-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :chat_images, ref)}
  end

  @impl true
  def handle_event("validate_chat", _params, socket) do
    # Juste pour permettre le preview des images uploadées
    {:noreply, socket}
  end

  @impl true
  def handle_event("open_image_preview", %{"src" => src}, socket) do
    {:noreply, assign(socket, :preview_image, src)}
  end

  @impl true
  def handle_event("close_image_preview", _, socket) do
    {:noreply, assign(socket, :preview_image, nil)}
  end

  @impl true
  def handle_event("delete_message", %{"id" => message_id}, socket) do
    user = socket.assigns.current_user
    message_id = String.to_integer(message_id)
    message = Chat.get_message(message_id)

    if message && message.sender_id == user.id do
      case Chat.delete_message(message) do
        {:ok, _} ->
          # Mettre à jour la liste des messages
          messages = Enum.reject(socket.assigns.active_messages, &(&1.id == message_id))

          # Broadcast la suppression
          Phoenix.PubSub.broadcast(
            MonApp.PubSub,
            "chat:#{socket.assigns.active_conversation.id}",
            {:message_deleted, message_id}
          )

          {:noreply, assign(socket, :active_messages, messages)}

        {:error, _} ->
          {:noreply, put_flash(socket, :error, "Erreur lors de la suppression")}
      end
    else
      {:noreply, put_flash(socket, :error, "Non autorisé")}
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
        # Si le message vient de quelqu'un d'autre, le marquer comme vu
        socket =
          if message.sender_id != user.id do
            Chat.mark_conversation_as_seen(active_conversation.id, user.id)
            # Pour les 1-à-1, notifier que les messages sont vus
            if !active_conversation.is_group do
              notify_messages_seen(active_conversation.id, user.id, message.sender_id)
            end
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
    user = socket.assigns.current_user
    active_conversation = socket.assigns.active_conversation

    # Ne pas afficher notre propre indicateur de frappe
    if active_conversation && sender_id != user.id do
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
  def handle_info({:message_deleted, message_id}, socket) do
    if socket.assigns.active_conversation do
      messages = Enum.reject(socket.assigns.active_messages, &(&1.id == message_id))
      {:noreply, assign(socket, :active_messages, messages)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:friend_request_received, _}, socket) do
    user_id = socket.assigns.current_user.id
    pending_count = Social.count_pending_requests(user_id)
    {:noreply, assign(socket, :pending_requests_count, pending_count)}
  end

  @impl true
  def handle_info({:friend_request_updated, _}, socket) do
    user_id = socket.assigns.current_user.id
    pending_count = Social.count_pending_requests(user_id)
    friends = Social.list_friends(user_id)
    {:noreply,
     socket
     |> assign(:pending_requests_count, pending_count)
     |> assign(:friends, friends)}
  end

  @impl true
  def handle_info({:friend_request_accepted, _}, socket) do
    user_id = socket.assigns.current_user.id
    friends = Social.list_friends(user_id)
    {:noreply, assign(socket, :friends, friends)}
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

  defp save_chat_images(socket, message_id) do
    consume_uploaded_entries(socket, :chat_images, fn %{path: path}, entry ->
      # Générer un nom de fichier unique
      ext = Path.extname(entry.client_name)
      filename = "msg_#{message_id}_#{System.unique_integer([:positive])}#{ext}"
      dest = Path.join(Chat.uploads_dir(), filename)

      # S'assurer que le répertoire existe
      File.mkdir_p!(Chat.uploads_dir())

      # Copier le fichier
      File.cp!(path, dest)

      # Créer l'entrée en base
      Chat.create_message_attachment(%{
        filename: filename,
        original_filename: entry.client_name,
        content_type: entry.client_type,
        size: entry.client_size,
        message_id: message_id
      })

      {:ok, filename}
    end)
  end
end
