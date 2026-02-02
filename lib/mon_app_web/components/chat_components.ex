defmodule MonAppWeb.ChatComponents do
  @moduledoc """
  Composants réutilisables pour le chat.
  """

  use Phoenix.Component

  alias MonApp.Chat.Message
  alias MonApp.Chat.MessageAttachment
  alias MonApp.Chat.Conversation

  # ============== CONVERSATION LIST ==============

  attr :conversations, :list, required: true
  attr :current_user, :map, required: true
  attr :online_users, :list, default: []
  attr :filter, :string, default: "all"

  def conversation_list(assigns) do
    # Filtrer les conversations
    filtered_conversations = case assigns.filter do
      "unread" -> Enum.filter(assigns.conversations, fn c -> (c.unread_count || 0) > 0 end)
      _ -> assigns.conversations
    end
    assigns = assign(assigns, :filtered_conversations, filtered_conversations)

    ~H"""
    <div>
      <.conversation_item
        :for={conv <- @filtered_conversations}
        conversation={conv}
        current_user={@current_user}
        online_users={@online_users}
      />
      <div :if={@filtered_conversations == []} class="p-12 text-center text-base-content/50">
        <svg xmlns="http://www.w3.org/2000/svg" class="h-16 w-16 mx-auto mb-4 opacity-30" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z" />
        </svg>
        <p class="font-medium text-base">
          {if @filter == "unread", do: "Aucun message non lu", else: "Aucune conversation"}
        </p>
        <p class="text-sm mt-1">
          {if @filter == "unread", do: "Vous êtes à jour !", else: "Commencez une discussion avec un ami !"}
        </p>
      </div>
    </div>
    """
  end

  attr :conversation, :map, required: true
  attr :current_user, :map, required: true
  attr :online_users, :list, default: []

  def conversation_item(assigns) do
    conversation = assigns.conversation
    current_user_id = assigns.current_user.id
    last_message = conversation.last_message
    unread_count = conversation.unread_count || 0

    # Déterminer le nom et l'avatar à afficher
    {display_name, avatar_name, online} = if conversation.is_group do
      # Pour les groupes
      {conversation.name, conversation.name, false}
    else
      # Pour les chats 1-à-1
      other_user = Conversation.other_user(conversation, current_user_id)
      other_user_id = Conversation.other_user_id(conversation, current_user_id)
      is_online = other_user_id in assigns.online_users
      {other_user.name, other_user.name, is_online}
    end

    assigns =
      assigns
      |> assign(:display_name, display_name)
      |> assign(:avatar_name, avatar_name)
      |> assign(:online, online)
      |> assign(:last_message, last_message)
      |> assign(:unread_count, unread_count)
      |> assign(:is_group, conversation.is_group)
      |> assign(:participant_count, if(conversation.is_group, do: length(conversation.participants || []), else: 0))

    ~H"""
    <button
      type="button"
      phx-click="open_chat"
      phx-value-id={@conversation.id}
      class="w-full flex items-center gap-3 px-4 py-3 hover:bg-base-200/70 active:bg-base-200 transition-colors cursor-pointer text-left rounded-xl mx-2 my-0.5"
    >
      <!-- Avatar avec indicateur online ou icône groupe -->
      <div class="relative shrink-0">
        <%= if @is_group do %>
          <.group_avatar name={@avatar_name} size="w-14 h-14" text_size="text-xl" />
        <% else %>
          <.user_avatar name={@avatar_name} size="w-14 h-14" text_size="text-xl" />
          <span
            :if={@online}
            class="absolute bottom-0.5 right-0.5 h-3.5 w-3.5 rounded-full bg-success border-[2.5px] border-base-100"
          />
        <% end %>
      </div>

      <!-- Contenu -->
      <div class="flex-1 min-w-0">
        <div class="flex items-center gap-2">
          <span class={"flex-1 truncate text-[15px] " <> if @unread_count > 0, do: "font-bold text-base-content", else: "font-semibold text-base-content"}>
            {@display_name}
          </span>
          <div class="flex items-center gap-1.5 shrink-0">
            <span
              :if={@last_message}
              id={"conv-time-#{@conversation.id}"}
              phx-hook="LocalTimeCompact"
              data-time={NaiveDateTime.to_iso8601(@last_message.inserted_at)}
              class={"text-xs " <> if @unread_count > 0, do: "text-primary font-medium", else: "text-base-content/50"}
            >
              {format_time_compact(@last_message.inserted_at)}
            </span>
            <!-- Blue dot pour non lu -->
            <span
              :if={@unread_count > 0}
              class="w-3 h-3 rounded-full bg-primary shrink-0"
            />
          </div>
        </div>
        <p class={"text-sm truncate mt-0.5 " <>
          if @unread_count > 0, do: "text-base-content font-medium", else: "text-base-content/50"}>
          <%= if @is_group do %>
            <span :if={@last_message}>
              {@last_message.sender.name}:
            </span>
          <% else %>
            <span :if={@last_message && @last_message.sender_id == @current_user.id}>
              Vous :
            </span>
          <% end %>
          <%= cond do %>
            <% @last_message && (@last_message.body == nil || @last_message.body == "") && length(Map.get(@last_message, :attachments, [])) > 0 -> %>
              <span class="inline-flex items-center gap-1">
                <svg xmlns="http://www.w3.org/2000/svg" class="h-3.5 w-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z" />
                </svg>
                Photo
              </span>
            <% @last_message -> %>
              {@last_message.body}
            <% true -> %>
              Nouvelle conversation
          <% end %>
        </p>
        <!-- Nombre de participants pour les groupes -->
        <p :if={@is_group} class="text-xs text-base-content/40 mt-0.5">
          {@participant_count} participants
        </p>
      </div>
    </button>
    """
  end

  # ============== MESSAGES ==============

  attr :messages, :list, required: true
  attr :current_user, :map, required: true
  attr :is_group, :boolean, default: false

  def message_list(assigns) do
    # Grouper les messages par date
    messages_with_dates = group_messages_by_date(assigns.messages)
    assigns = assign(assigns, :messages_with_dates, messages_with_dates)

    ~H"""
    <div class="flex flex-col gap-1 p-4">
      <%= for {date, messages} <- @messages_with_dates do %>
        <!-- Séparateur de date -->
        <div class="flex items-center justify-center my-3">
          <div class="flex-1 border-t border-base-300"></div>
          <span
            id={"date-divider-#{date}"}
            phx-hook="LocalDate"
            data-date={date}
            class="px-3 text-xs text-base-content/50 font-medium"
          >
            {format_date_divider(date)}
          </span>
          <div class="flex-1 border-t border-base-300"></div>
        </div>
        <!-- Messages de cette date -->
        <.message_bubble
          :for={message <- messages}
          message={message}
          is_mine={message.sender_id == @current_user.id}
          is_group={@is_group}
        />
      <% end %>
    </div>
    """
  end

  defp group_messages_by_date(messages) do
    messages
    |> Enum.group_by(fn msg ->
      msg.inserted_at
      |> NaiveDateTime.to_date()
      |> Date.to_iso8601()
    end)
    |> Enum.sort_by(fn {date, _} -> date end)
  end

  defp format_date_divider(date_string) do
    {:ok, date} = Date.from_iso8601(date_string)
    today = Date.utc_today()
    diff = Date.diff(today, date)

    cond do
      diff == 0 -> "Aujourd'hui"
      diff == 1 -> "Hier"
      diff < 7 ->
        day_name = case Date.day_of_week(date) do
          1 -> "Lundi"
          2 -> "Mardi"
          3 -> "Mercredi"
          4 -> "Jeudi"
          5 -> "Vendredi"
          6 -> "Samedi"
          7 -> "Dimanche"
        end
        day_name
      true ->
        month_name = case date.month do
          1 -> "janvier"
          2 -> "février"
          3 -> "mars"
          4 -> "avril"
          5 -> "mai"
          6 -> "juin"
          7 -> "juillet"
          8 -> "août"
          9 -> "septembre"
          10 -> "octobre"
          11 -> "novembre"
          12 -> "décembre"
        end
        if date.year == today.year do
          "#{date.day} #{month_name}"
        else
          "#{date.day} #{month_name} #{date.year}"
        end
    end
  end

  attr :message, :map, required: true
  attr :is_mine, :boolean, required: true
  attr :is_group, :boolean, default: false

  def message_bubble(assigns) do
    attachments = Map.get(assigns.message, :attachments) || []
    has_attachments = length(attachments) > 0
    has_body = assigns.message.body && String.trim(assigns.message.body || "") != ""

    assigns =
      assigns
      |> assign(:attachments, attachments)
      |> assign(:has_attachments, has_attachments)
      |> assign(:has_body, has_body)

    ~H"""
    <div class={"flex group gap-2 " <> if @is_mine, do: "justify-end", else: "justify-start"}>
      <!-- Avatar pour les messages de groupe (autres utilisateurs) -->
      <div :if={@is_group && !@is_mine} class="shrink-0 self-end">
        <.user_avatar name={@message.sender.name} size="w-8 h-8" text_size="text-xs" />
      </div>

      <div class={"max-w-[70%] " <> if @is_mine, do: "order-2", else: ""}>
        <!-- Nom de l'expéditeur pour les groupes -->
        <p :if={@is_group && !@is_mine} class="text-xs text-base-content/60 mb-1 ml-1">
          {@message.sender.name}
        </p>

        <!-- Images attachées -->
        <div :if={@has_attachments} class={"mb-1 " <> if @is_mine, do: "text-right", else: "text-left"}>
          <div class={
            "inline-grid gap-1 " <>
            cond do
              length(@attachments) == 1 -> "grid-cols-1"
              length(@attachments) == 2 -> "grid-cols-2"
              true -> "grid-cols-2"
            end
          }>
            <div
              :for={attachment <- @attachments}
              class="relative overflow-hidden rounded-xl cursor-pointer"
              phx-click="open_image_preview"
              phx-value-src={MessageAttachment.url(attachment)}
            >
              <img
                src={MessageAttachment.url(attachment)}
                alt={attachment.original_filename}
                class="w-full h-auto max-h-64 object-cover hover:scale-105 transition-transform duration-200"
              />
            </div>
          </div>
        </div>

        <!-- Bulle du message (seulement si il y a du texte) -->
        <div :if={@has_body} class={
          "px-4 py-2 rounded-2xl " <>
          if @is_mine do
            "bg-primary text-primary-content rounded-br-md"
          else
            "bg-base-200 text-base-content rounded-bl-md"
          end
        }>
          <p class="text-[15px] whitespace-pre-wrap break-words">{@message.body}</p>
        </div>

        <!-- Heure, statut et bouton supprimer -->
        <div class={"flex items-center gap-1 mt-0.5 text-xs text-base-content/50 " <>
          if @is_mine, do: "justify-end", else: "justify-start"}>
          <!-- Bouton supprimer (visible au hover pour mes messages) -->
          <button
            :if={@is_mine}
            type="button"
            phx-click="delete_message"
            phx-value-id={@message.id}
            class="opacity-0 group-hover:opacity-100 transition-opacity btn btn-ghost btn-xs btn-circle text-error mr-1"
            title="Supprimer"
          >
            <svg xmlns="http://www.w3.org/2000/svg" class="h-3 w-3" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
            </svg>
          </button>
          <span
            id={"msg-time-#{@message.id}"}
            phx-hook="LocalTime"
            data-time={NaiveDateTime.to_iso8601(@message.inserted_at)}
          >
            {format_message_time(@message.inserted_at)}
          </span>
          <span :if={@is_mine} class={Message.status_class(@message.status)}>
            {Message.status_icon(@message.status)}
          </span>
        </div>
      </div>
    </div>
    """
  end

  # ============== CHAT INPUT ==============

  attr :form, :any, required: true
  attr :uploads, :any, default: nil
  attr :disabled, :boolean, default: false

  def chat_input(assigns) do
    ~H"""
    <.form
      for={@form}
      phx-submit="send_message"
      phx-change="validate_chat"
      class="p-3 border-t border-base-200 bg-base-100"
    >
      <!-- Preview des images à uploader -->
      <div :if={@uploads && @uploads.chat_images.entries != []} class="mb-2 flex flex-wrap gap-2">
        <div
          :for={entry <- @uploads.chat_images.entries}
          class="relative group"
        >
          <div class="w-16 h-16 rounded-lg overflow-hidden bg-base-200">
            <.live_img_preview entry={entry} class="w-full h-full object-cover" />
          </div>
          <!-- Bouton supprimer -->
          <button
            type="button"
            phx-click="cancel-chat-upload"
            phx-value-ref={entry.ref}
            class="absolute -top-1.5 -right-1.5 btn btn-circle btn-xs bg-error border-none text-white hover:bg-error/80"
          >
            <svg xmlns="http://www.w3.org/2000/svg" class="h-3 w-3" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
            </svg>
          </button>
          <!-- Barre de progression -->
          <div :if={entry.progress > 0 && entry.progress < 100} class="absolute bottom-0 left-0 right-0 h-1 bg-base-300 rounded-b-lg overflow-hidden">
            <div class="h-full bg-primary transition-all" style={"width: #{entry.progress}%"}></div>
          </div>
        </div>
      </div>

      <!-- Erreurs d'upload -->
      <%= if @uploads && get_upload_errors(@uploads.chat_images) != [] do %>
        <div class="mb-2">
          <p :for={err <- get_upload_errors(@uploads.chat_images)} class="text-error text-xs">
            {upload_error_to_string(err)}
          </p>
        </div>
      <% end %>

      <div class="flex items-end gap-2 bg-base-200/50 rounded-2xl p-2">
        <!-- Bouton photo -->
        <label
          class={"btn btn-ghost btn-sm btn-circle text-base-content/50 hover:text-base-content cursor-pointer " <>
            if @disabled, do: "btn-disabled", else: ""}
        >
          <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z" />
          </svg>
          <.live_file_input :if={@uploads} upload={@uploads.chat_images} class="hidden" />
        </label>

        <!-- Zone de texte -->
        <div class="flex-1 min-w-0">
          <textarea
            name="message[body]"
            rows="1"
            class="w-full bg-transparent border-none focus:ring-0 focus:outline-none resize-none text-base placeholder-base-content/40 py-2 px-1 min-h-[40px] max-h-28"
            placeholder="Écrivez un message..."
            phx-debounce="300"
            phx-hook="ChatInput"
            id="message-input"
            disabled={@disabled}
          />
        </div>

        <!-- Bouton envoyer -->
        <button
          type="submit"
          class="btn btn-primary btn-sm btn-circle shrink-0 transition-all duration-200"
          disabled={@disabled}
        >
          <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" viewBox="0 0 24 24" fill="currentColor">
            <path d="M3.478 2.404a.75.75 0 0 0-.926.941l2.432 7.905H13.5a.75.75 0 0 1 0 1.5H4.984l-2.432 7.905a.75.75 0 0 0 .926.94 60.519 60.519 0 0 0 18.445-8.986.75.75 0 0 0 0-1.218A60.517 60.517 0 0 0 3.478 2.404Z" />
          </svg>
        </button>
      </div>
    </.form>
    """
  end

  defp get_upload_errors(upload) do
    # Erreurs au niveau de la config (ex: trop de fichiers)
    config_errors = Phoenix.Component.upload_errors(upload)

    # Erreurs au niveau de chaque entrée (ex: fichier trop gros, format non supporté)
    entry_errors =
      Enum.flat_map(upload.entries, fn entry ->
        Phoenix.Component.upload_errors(upload, entry)
      end)

    config_errors ++ entry_errors
  end

  defp upload_error_to_string(:too_large), do: "Image trop volumineuse (max 10 Mo)"
  defp upload_error_to_string(:too_many_files), do: "Trop d'images (max 5)"
  defp upload_error_to_string(:not_accepted), do: "Format non supporté (JPG, PNG, GIF, WebP)"
  defp upload_error_to_string(_), do: "Erreur lors de l'upload"

  # ============== CHAT HEADER ==============

  attr :other_user, :map, required: true
  attr :online, :boolean, default: false
  attr :typing, :boolean, default: false

  def chat_header(assigns) do
    ~H"""
    <div class="border-b border-base-200 bg-base-100 safe-area-top">
      <div class="flex items-center gap-3 px-4 py-3 min-h-[60px]">
        <a href="/conversations" class="btn btn-ghost btn-sm btn-circle shrink-0">
          <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7" />
          </svg>
        </a>
        <div class="relative shrink-0">
          <.user_avatar name={@other_user.name} size="w-11 h-11" />
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
      </div>
    </div>
    """
  end

  # ============== CHAT BOTTOM SHEET ==============

  attr :conversation, :map, required: true
  attr :display_name, :string, required: true
  attr :messages, :list, required: true
  attr :current_user, :map, required: true
  attr :online, :boolean, default: false
  attr :typing, :boolean, default: false
  attr :form, :any, required: true
  attr :uploads, :any, default: nil
  attr :preview_image, :string, default: nil

  def chat_bottom_sheet(assigns) do
    is_group = assigns.conversation.is_group
    participant_count = if is_group, do: length(assigns.conversation.participants || []), else: 0

    assigns =
      assigns
      |> assign(:is_group, is_group)
      |> assign(:participant_count, participant_count)

    ~H"""
    <div class="fixed inset-0 z-50 md:flex md:justify-end">
      <!-- Overlay (hidden on mobile) -->
      <div
        class="hidden md:block absolute inset-0 bg-black/30"
        phx-click="close_chat"
      />

      <!-- Chat Panel - Full screen on mobile, side panel on desktop -->
      <div class="relative w-full md:max-w-md h-full flex flex-col bg-base-100 shadow-2xl md:animate-slide-in-right">
        <!-- Header avec safe area -->
        <div class="border-b border-base-200 bg-base-100 safe-area-top">
          <div class="flex items-center gap-3 px-4 py-3 min-h-[60px]">
            <button
              type="button"
              phx-click="close_chat"
              class="btn btn-ghost btn-sm btn-circle shrink-0"
            >
              <!-- Flèche retour sur mobile, X sur desktop -->
              <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 md:hidden" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7" />
              </svg>
              <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 hidden md:block" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
              </svg>
            </button>
            <div class="relative shrink-0">
              <%= if @is_group do %>
                <.group_avatar name={@display_name} size="w-11 h-11" />
              <% else %>
                <.user_avatar name={@display_name} size="w-11 h-11" />
                <span
                  :if={@online}
                  class="absolute bottom-0 right-0 h-3 w-3 rounded-full bg-success border-2 border-base-100"
                />
              <% end %>
            </div>
            <div class="flex-1 min-w-0 py-0.5">
              <h2 class="font-semibold text-base truncate leading-tight">{@display_name}</h2>
              <p class="text-xs text-base-content/60 mt-0.5 leading-tight">
                <%= cond do %>
                  <% @typing -> %>
                    <span class="text-primary">écrit...</span>
                  <% @is_group -> %>
                    {@participant_count} participants
                  <% @online -> %>
                    En ligne
                  <% true -> %>
                    Hors ligne
                <% end %>
              </p>
            </div>
          </div>
        </div>

        <!-- Messages -->
        <div
          class="flex-1 overflow-y-auto bg-base-200/30 overscroll-contain"
          id="sheet-messages-container"
          phx-hook="ScrollToBottom"
        >
          <.message_list messages={@messages} current_user={@current_user} is_group={@is_group} />
        </div>

        <!-- Input avec safe area pour mobile -->
        <div class="safe-area-bottom">
          <.chat_input form={@form} uploads={@uploads} />
        </div>
      </div>

      <!-- Modal preview image -->
      <.image_preview_modal :if={@preview_image} src={@preview_image} />
    </div>
    """
  end

  # ============== IMAGE PREVIEW MODAL ==============

  attr :src, :string, required: true

  def image_preview_modal(assigns) do
    ~H"""
    <div
      class="fixed inset-0 z-[100] bg-black/90 flex items-center justify-center p-4"
      phx-click="close_image_preview"
    >
      <!-- Bouton fermer -->
      <button
        type="button"
        phx-click="close_image_preview"
        class="absolute top-4 right-4 btn btn-circle btn-ghost text-white hover:bg-white/20"
      >
        <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
        </svg>
      </button>

      <!-- Image -->
      <img
        src={@src}
        alt="Preview"
        class="max-w-full max-h-full object-contain rounded-lg"
        phx-click="close_image_preview"
      />
    </div>
    """
  end

  # ============== NEW CONVERSATION MODAL ==============

  attr :friends, :list, required: true
  attr :online_users, :list, default: []
  attr :modal_tab, :string, default: "direct"
  attr :selected_friends, :list, default: []
  attr :group_name, :string, default: ""
  attr :search_query, :string, default: ""

  def new_conversation_modal(assigns) do
    # Filtrer les amis selon la recherche
    filtered_friends = if assigns.search_query == "" do
      assigns.friends
    else
      query = String.downcase(assigns.search_query)
      Enum.filter(assigns.friends, fn friend ->
        String.contains?(String.downcase(friend.name), query)
      end)
    end

    assigns = assign(assigns, :filtered_friends, filtered_friends)
    ~H"""
    <div class="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
      <div
        class="bg-base-100 rounded-xl shadow-2xl w-full max-w-md max-h-[80vh] flex flex-col"
        phx-click-away="close_new_conversation"
      >
        <div class="flex items-center justify-between p-4 border-b border-base-200">
          <h3 class="text-lg font-bold">Nouvelle conversation</h3>
          <button
            type="button"
            phx-click="close_new_conversation"
            class="btn btn-ghost btn-sm btn-circle"
          >
            <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
            </svg>
          </button>
        </div>

        <!-- Tabs -->
        <div class="flex border-b border-base-200">
          <button
            type="button"
            phx-click="set_modal_tab"
            phx-value-tab="direct"
            class={"flex-1 py-3 text-sm font-medium transition-colors " <>
              if @modal_tab == "direct", do: "text-primary border-b-2 border-primary", else: "text-base-content/60 hover:text-base-content"}
          >
            <div class="flex items-center justify-center gap-2">
              <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
              </svg>
              Chat privé
            </div>
          </button>
          <button
            type="button"
            phx-click="set_modal_tab"
            phx-value-tab="group"
            class={"flex-1 py-3 text-sm font-medium transition-colors " <>
              if @modal_tab == "group", do: "text-primary border-b-2 border-primary", else: "text-base-content/60 hover:text-base-content"}
          >
            <div class="flex items-center justify-center gap-2">
              <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z" />
              </svg>
              Groupe
            </div>
          </button>
        </div>

        <!-- Contenu basé sur le tab -->
        <%= if @modal_tab == "direct" do %>
          <!-- Barre de recherche -->
          <div class="p-3 border-b border-base-200">
            <div class="relative">
              <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 absolute left-3 top-1/2 -translate-y-1/2 text-base-content/40" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
              </svg>
              <input
                type="text"
                placeholder="Rechercher un ami..."
                class="w-full h-9 pl-9 pr-3 text-sm bg-base-200 border-none rounded-full focus:outline-none focus:ring-2 focus:ring-primary/20"
                phx-change="search_modal_friends"
                phx-debounce="200"
                name="query"
                value={@search_query}
              />
            </div>
          </div>

          <!-- Liste des amis pour chat direct -->
          <div class="flex-1 overflow-y-auto">
            <div :if={@filtered_friends == [] && @search_query != ""} class="p-8 text-center text-base-content/50">
              <p>Aucun ami trouvé pour "{@search_query}"</p>
            </div>
            <div :if={@friends == [] && @search_query == ""} class="p-8 text-center text-base-content/50">
              <p>Vous n'avez pas encore d'amis.</p>
              <p class="text-sm mt-1">Ajoutez des amis pour commencer à discuter !</p>
            </div>
            <div :for={friend <- @filtered_friends} class="border-b border-base-200 last:border-0">
              <button
                type="button"
                phx-click="start_conversation"
                phx-value-user-id={friend.id}
                class="w-full flex items-center gap-3 p-3 hover:bg-base-200 transition-colors"
              >
                <div class="relative">
                  <.user_avatar name={friend.name} size="w-10 h-10" />
                  <span
                    :if={friend.id in @online_users}
                    class="absolute bottom-0 right-0 h-3 w-3 rounded-full bg-success border-2 border-base-100"
                  />
                </div>
                <div class="flex-1 text-left">
                  <span class="font-medium">{friend.name}</span>
                  <p class="text-xs text-base-content/50">
                    {if friend.id in @online_users, do: "En ligne", else: "Hors ligne"}
                  </p>
                </div>
              </button>
            </div>
          </div>
        <% else %>
          <!-- Création de groupe -->
          <div class="flex-1 overflow-y-auto flex flex-col">
            <!-- Header avec avatar et nom du groupe -->
            <div class="p-4 border-b border-base-200 bg-gradient-to-b from-base-200/50 to-transparent">
              <div class="flex items-center gap-4">
                <!-- Prévisualisation de l'avatar du groupe -->
                <div class="relative">
                  <div class={"w-16 h-16 rounded-full flex items-center justify-center transition-all duration-300 " <>
                    if String.trim(@group_name) != "", do: "bg-gradient-to-br from-primary to-secondary", else: "bg-base-300"}>
                    <%= if String.trim(@group_name) != "" do %>
                      <span class="text-xl font-bold text-white">
                        {String.trim(@group_name) |> String.split(" ") |> Enum.map(&String.first/1) |> Enum.take(2) |> Enum.join() |> String.upcase()}
                      </span>
                    <% else %>
                      <svg xmlns="http://www.w3.org/2000/svg" class="h-8 w-8 text-base-content/30" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z" />
                      </svg>
                    <% end %>
                  </div>
                  <!-- Badge nombre de participants -->
                  <div :if={length(@selected_friends) > 0} class="absolute -bottom-1 -right-1 bg-primary text-primary-content text-xs font-bold w-6 h-6 rounded-full flex items-center justify-center border-2 border-base-100">
                    {length(@selected_friends) + 1}
                  </div>
                </div>

                <!-- Input nom du groupe -->
                <form phx-change="update_group_name" class="flex-1">
                  <label class="text-xs font-medium text-base-content/50 mb-1 block">Nom du groupe</label>
                  <input
                    type="text"
                    placeholder="Donnez un nom à votre groupe..."
                    class="w-full bg-transparent border-none text-lg font-semibold placeholder-base-content/30 focus:outline-none focus:ring-0 p-0"
                    phx-debounce="200"
                    name="group_name"
                    value={@group_name}
                    autofocus
                  />
                  <p class="text-xs text-base-content/40 mt-1">
                    {String.length(String.trim(@group_name))}/50 caractères
                  </p>
                </form>
              </div>
            </div>

            <!-- Amis sélectionnés -->
            <div :if={@selected_friends != []} class="px-4 py-3 border-b border-base-200 bg-base-200/20">
              <p class="text-xs font-medium text-base-content/60 mb-2">
                <span class="text-primary">{length(@selected_friends)}</span> membre(s) sélectionné(s)
              </p>
              <div class="flex flex-wrap gap-2">
                <div
                  :for={friend <- @selected_friends}
                  class="flex items-center gap-2 bg-base-100 border border-base-300 pl-1 pr-2 py-1 rounded-full text-sm shadow-sm"
                >
                  <.user_avatar name={friend.name} size="w-6 h-6" text_size="text-xs" />
                  <span class="font-medium text-base-content/80">{friend.name}</span>
                  <button
                    type="button"
                    phx-click="toggle_friend_selection"
                    phx-value-friend-id={friend.id}
                    class="text-base-content/40 hover:text-error transition-colors"
                  >
                    <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
                    </svg>
                  </button>
                </div>
              </div>
            </div>

            <!-- Liste des amis à sélectionner -->
            <div class="flex-1 overflow-y-auto">
              <div class="sticky top-0 bg-base-100 z-10">
                <p class="px-4 py-2 text-xs font-medium text-base-content/50 bg-base-200/30">
                  Ajouter des membres <span class="text-base-content/30">(min. 2)</span>
                </p>
                <!-- Barre de recherche pour groupe -->
                <div class="px-3 py-2 border-b border-base-200">
                  <div class="relative">
                    <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 absolute left-3 top-1/2 -translate-y-1/2 text-base-content/40" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
                    </svg>
                    <input
                      type="text"
                      placeholder="Rechercher un ami..."
                      class="w-full h-8 pl-9 pr-3 text-sm bg-base-200 border-none rounded-full focus:outline-none focus:ring-2 focus:ring-primary/20"
                      phx-change="search_modal_friends"
                      phx-debounce="200"
                      name="query"
                      value={@search_query}
                    />
                  </div>
                </div>
              </div>
              <div :if={@filtered_friends == [] && @search_query != ""} class="p-8 text-center text-base-content/50">
                <p>Aucun ami trouvé pour "{@search_query}"</p>
              </div>
              <div :if={@friends == [] && @search_query == ""} class="p-8 text-center text-base-content/50">
                <p>Vous n'avez pas encore d'amis.</p>
                <p class="text-sm mt-1">Ajoutez des amis pour créer un groupe !</p>
              </div>
              <div :for={friend <- @filtered_friends} class="border-b border-base-200 last:border-0">
                <button
                  type="button"
                  phx-click="toggle_friend_selection"
                  phx-value-friend-id={friend.id}
                  class={"w-full flex items-center gap-3 p-3 hover:bg-base-200 transition-colors " <>
                    if friend in @selected_friends, do: "bg-primary/10", else: ""}
                >
                  <div class="relative">
                    <.user_avatar name={friend.name} size="w-10 h-10" />
                    <span
                      :if={friend.id in @online_users}
                      class="absolute bottom-0 right-0 h-3 w-3 rounded-full bg-success border-2 border-base-100"
                    />
                  </div>
                  <div class="flex-1 text-left">
                    <span class="font-medium">{friend.name}</span>
                    <p class="text-xs text-base-content/50">
                      {if friend.id in @online_users, do: "En ligne", else: "Hors ligne"}
                    </p>
                  </div>
                  <!-- Checkbox -->
                  <div class={"w-6 h-6 rounded-full border-2 flex items-center justify-center " <>
                    if friend in @selected_friends, do: "bg-primary border-primary", else: "border-base-300"}>
                    <svg
                      :if={friend in @selected_friends}
                      xmlns="http://www.w3.org/2000/svg"
                      class="h-4 w-4 text-primary-content"
                      fill="none"
                      viewBox="0 0 24 24"
                      stroke="currentColor"
                    >
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="3" d="M5 13l4 4L19 7" />
                    </svg>
                  </div>
                </button>
              </div>
            </div>

            <!-- Bouton créer groupe -->
            <div class="p-4 border-t border-base-200 bg-base-100">
              <!-- Indicateur de progression -->
              <div class="flex items-center gap-2 mb-3 text-xs">
                <div class={"flex items-center gap-1.5 " <> if String.trim(@group_name) != "", do: "text-success", else: "text-base-content/40"}>
                  <div class={"w-5 h-5 rounded-full flex items-center justify-center " <>
                    if String.trim(@group_name) != "", do: "bg-success/20", else: "bg-base-200"}>
                    <%= if String.trim(@group_name) != "" do %>
                      <svg xmlns="http://www.w3.org/2000/svg" class="h-3 w-3" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="3" d="M5 13l4 4L19 7" />
                      </svg>
                    <% else %>
                      <span class="text-[10px] font-bold">1</span>
                    <% end %>
                  </div>
                  <span>Nom</span>
                </div>
                <div class="flex-1 h-px bg-base-300"></div>
                <div class={"flex items-center gap-1.5 " <> if length(@selected_friends) >= 2, do: "text-success", else: "text-base-content/40"}>
                  <div class={"w-5 h-5 rounded-full flex items-center justify-center " <>
                    if length(@selected_friends) >= 2, do: "bg-success/20", else: "bg-base-200"}>
                    <%= if length(@selected_friends) >= 2 do %>
                      <svg xmlns="http://www.w3.org/2000/svg" class="h-3 w-3" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="3" d="M5 13l4 4L19 7" />
                      </svg>
                    <% else %>
                      <span class="text-[10px] font-bold">2</span>
                    <% end %>
                  </div>
                  <span>Membres ({length(@selected_friends)}/2+)</span>
                </div>
              </div>

              <button
                type="button"
                phx-click="create_group"
                disabled={length(@selected_friends) < 2 || String.trim(@group_name) == ""}
                class={"btn w-full transition-all duration-200 " <>
                  if length(@selected_friends) >= 2 && String.trim(@group_name) != "",
                    do: "btn-primary shadow-lg shadow-primary/25",
                    else: "btn-disabled bg-base-200 text-base-content/30"}
              >
                <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z" />
                </svg>
                Créer le groupe
              </button>
            </div>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  # ============== HELPERS ==============

  attr :name, :string, required: true
  attr :size, :string, default: "w-10 h-10"
  attr :text_size, :string, default: "text-sm"

  def user_avatar(assigns) do
    initials = assigns.name
      |> String.split(" ")
      |> Enum.map(&String.first/1)
      |> Enum.take(2)
      |> Enum.join()
      |> String.upcase()

    # Générer une couleur basée sur le nom (pour varier les couleurs d'avatar)
    colors = [
      "bg-primary/15 text-primary",
      "bg-secondary/15 text-secondary",
      "bg-accent/15 text-accent",
      "bg-info/15 text-info",
      "bg-success/15 text-success",
      "bg-warning/15 text-warning",
      "bg-error/15 text-error"
    ]
    color_index = :erlang.phash2(assigns.name, length(colors))
    color_class = Enum.at(colors, color_index)

    assigns =
      assigns
      |> assign(:initials, initials)
      |> assign(:color_class, color_class)

    ~H"""
    <div class={"#{@size} rounded-full #{@color_class} flex items-center justify-center"}>
      <span class={"font-bold #{@text_size}"}>{@initials}</span>
    </div>
    """
  end

  attr :name, :string, required: true
  attr :size, :string, default: "w-10 h-10"
  attr :text_size, :string, default: "text-sm"

  def group_avatar(assigns) do
    initials = assigns.name
      |> String.split(" ")
      |> Enum.map(&String.first/1)
      |> Enum.take(2)
      |> Enum.join()
      |> String.upcase()

    assigns = assign(assigns, :initials, initials)

    ~H"""
    <div class={"#{@size} rounded-full bg-gradient-to-br from-primary to-secondary flex items-center justify-center"}>
      <span class={"font-bold #{@text_size} text-white"}>{@initials}</span>
    </div>
    """
  end

  # Format compact pour la liste des conversations (style Messenger: "3h", "2j", etc.)
  defp format_time_compact(datetime) do
    datetime = to_datetime(datetime)
    now = DateTime.utc_now()
    diff = DateTime.diff(now, datetime, :second)

    cond do
      diff < 60 -> "1m"
      diff < 3600 -> "#{div(diff, 60)}m"
      diff < 86400 -> "#{div(diff, 3600)}h"
      diff < 604800 -> "#{div(diff, 86400)}j"
      true ->
        datetime
        |> DateTime.to_date()
        |> Calendar.strftime("%d/%m")
    end
  end

  defp format_message_time(datetime) do
    datetime
    |> NaiveDateTime.to_time()
    |> Calendar.strftime("%H:%M")
  end

  # Helper pour convertir NaiveDateTime en DateTime
  defp to_datetime(%NaiveDateTime{} = ndt) do
    DateTime.from_naive!(ndt, "Etc/UTC")
  end
  defp to_datetime(%DateTime{} = dt), do: dt
end
