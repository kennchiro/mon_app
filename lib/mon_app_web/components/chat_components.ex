defmodule MonAppWeb.ChatComponents do
  @moduledoc """
  Composants réutilisables pour le chat.
  """

  use Phoenix.Component

  alias MonApp.Chat.Message
  alias MonApp.Chat.MessageAttachment
  alias MonApp.Chat.MessageReaction
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
  attr :reaction_picker_message_id, :integer, default: nil

  def message_list(assigns) do
    # Grouper les messages par date
    messages_with_dates = group_messages_by_date(assigns.messages)
    assigns = assign(assigns, :messages_with_dates, messages_with_dates)

    ~H"""
    <div class="flex flex-col gap-2 p-4">
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
          current_user_id={@current_user.id}
          show_reaction_picker={@reaction_picker_message_id == message.id}
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
  attr :current_user_id, :integer, default: nil
  attr :show_reaction_picker, :boolean, default: false

  def message_bubble(assigns) do
    attachments = Map.get(assigns.message, :attachments) || []
    has_attachments = length(attachments) > 0
    has_body = assigns.message.body && String.trim(assigns.message.body || "") != ""
    is_deleted = assigns.message.deleted_for_all_at != nil

    # Vérifier si reply_to est chargé et non nil
    reply_to = case Map.get(assigns.message, :reply_to) do
      %Ecto.Association.NotLoaded{} -> nil
      nil -> nil
      loaded -> loaded
    end

    # Récupérer les réactions groupées
    reactions = case Map.get(assigns.message, :reactions) do
      %Ecto.Association.NotLoaded{} -> []
      nil -> []
      loaded -> loaded
    end

    reactions_grouped = group_reactions(reactions)

    assigns =
      assigns
      |> assign(:attachments, attachments)
      |> assign(:has_attachments, has_attachments)
      |> assign(:has_body, has_body)
      |> assign(:reply_to, reply_to)
      |> assign(:is_deleted, is_deleted)
      |> assign(:reactions, reactions)
      |> assign(:reactions_grouped, reactions_grouped)
      |> assign(:has_reactions, length(reactions) > 0)

    ~H"""
    <div
      id={"message-#{@message.id}"}
      class={"flex flex-col group " <> if @is_mine, do: "items-end", else: "items-start"}
      phx-hook="MessageContextMenu"
      data-message-id={@message.id}
      data-is-mine={@is_mine}
    >
      <!-- Row principale: Avatar + Bulle + Actions alignés -->
      <div class={"flex items-end gap-2 " <> if @is_mine, do: "flex-row-reverse", else: ""}>
        <!-- Actions à droite de la bulle pour les messages des autres (apparaissent au hover) -->
        <div :if={!@is_deleted && !@is_mine} class="hidden md:flex items-center gap-0.5 opacity-0 group-hover:opacity-100 transition-opacity self-center order-last">
          <button
            type="button"
            phx-click="open_reaction_picker"
            phx-value-id={@message.id}
            class="btn btn-ghost btn-xs btn-circle hover:bg-base-200"
            title="Réagir"
          >
            <svg xmlns="http://www.w3.org/2000/svg" class="h-3.5 w-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M14.828 14.828a4 4 0 01-5.656 0M9 10h.01M15 10h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
          </button>
          <button
            type="button"
            phx-click="reply_to_message"
            phx-value-id={@message.id}
            class="btn btn-ghost btn-xs btn-circle hover:bg-base-200"
            title="Répondre"
          >
            <svg xmlns="http://www.w3.org/2000/svg" class="h-3.5 w-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 10h10a8 8 0 018 8v2M3 10l6 6m-6-6l6-6" />
            </svg>
          </button>
        </div>

        <!-- Avatar pour les messages de groupe (autres utilisateurs) -->
        <div :if={@is_group && !@is_mine} class="shrink-0 self-end">
          <.user_avatar name={@message.sender.name} size="w-7 h-7" text_size="text-[10px]" />
        </div>

        <div class="max-w-[70%]">
          <!-- Nom de l'expéditeur pour les groupes -->
          <p :if={@is_group && !@is_mine && !@is_deleted} class="text-xs text-base-content/60 mb-0.5 ml-1">
            {@message.sender.name}
          </p>

        <!-- Reaction picker inline (au-dessus du message) -->
        <div :if={@show_reaction_picker && !@is_deleted} class={"mb-2 " <> if @is_mine, do: "text-right", else: "text-left"}>
          <div class="inline-flex bg-base-100 rounded-full shadow-lg border border-base-200 p-1 gap-0.5">
            <button
              :for={emoji <- MessageReaction.available_emojis()}
              type="button"
              phx-click="toggle_reaction"
              phx-value-message-id={@message.id}
              phx-value-emoji={emoji}
              class="text-lg hover:scale-125 active:scale-95 transition-transform p-1.5 hover:bg-base-200 rounded-full"
            >
              {emoji}
            </button>
          </div>
        </div>

        <!-- Message supprimé -->
        <%= if @is_deleted do %>
          <div class="px-3 py-2 rounded-2xl bg-base-200/50 text-base-content/40 italic text-sm">
            <div class="flex items-center gap-2">
              <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M18.364 18.364A9 9 0 005.636 5.636m12.728 12.728A9 9 0 015.636 5.636m12.728 12.728L5.636 5.636" />
              </svg>
              <span class="flex-1">{if @is_mine, do: "Vous avez supprimé ce message", else: "Ce message a été supprimé"}</span>
              <span class="text-[10px] opacity-70 ml-1">
                {format_message_time(@message.inserted_at)}
              </span>
            </div>
          </div>
        <% else %>
          <!-- Header de réponse style Messenger -->
          <div :if={@reply_to} class={"flex items-center gap-1 mb-1 text-xs text-base-content/50 " <> if @is_mine, do: "justify-end", else: "justify-start"}>
            <svg xmlns="http://www.w3.org/2000/svg" class="h-3 w-3" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 10h10a8 8 0 018 8v2M3 10l6 6m-6-6l6-6" />
            </svg>
            <span>
              {@message.sender.name} a répondu à {@reply_to.sender && @reply_to.sender.name || "un message"}
            </span>
          </div>

          <!-- Container pour réponse + message (visuellement connectés) -->
          <div :if={@reply_to} class={
            "rounded-2xl overflow-hidden " <>
            if @is_mine, do: "rounded-br-md", else: "rounded-bl-md"
          }>
            <!-- Preview du message original -->
            <div
              class={"px-3 py-2 cursor-pointer transition-colors " <>
                if @is_mine, do: "bg-primary/30 hover:bg-primary/40", else: "bg-base-300 hover:bg-base-300/80"}
              phx-click="scroll_to_message"
              phx-value-id={@reply_to.id}
            >
              <p class={"text-sm line-clamp-2 " <> if @is_mine, do: "text-primary-content/70", else: "text-base-content/60"}>
                {@reply_to.body || "📷 Photo"}
              </p>
            </div>
            <!-- Message de réponse (collé en dessous) avec heure intégrée -->
            <div :if={@has_body} class={
              "px-3 pt-2 pb-1 " <>
              if @is_mine do
                "bg-primary text-primary-content"
              else
                "bg-base-200 text-base-content"
              end
            }>
              <p class="text-[15px] whitespace-pre-wrap break-words">{@message.body}</p>
              <!-- Heure et statut intégrés -->
              <div class={"flex items-center gap-1 justify-end mt-1 " <>
                if @is_mine, do: "text-primary-content/60", else: "text-base-content/50"}>
                <span
                  id={"msg-time-#{@message.id}"}
                  phx-hook="LocalTime"
                  data-time={NaiveDateTime.to_iso8601(@message.inserted_at)}
                  class="text-[10px]"
                >
                  {format_message_time(@message.inserted_at)}
                </span>
                <span :if={@is_mine} class="text-[10px]">
                  {Message.status_icon(@message.status)}
                </span>
              </div>
            </div>
          </div>

          <!-- Message sans réponse -->
          <%= if !@reply_to do %>
            <!-- Images attachées avec overlay heure -->
            <div :if={@has_attachments && !@has_body} class={"relative inline-block " <> if @is_mine, do: "text-right", else: "text-left"}>
              <div class={
                "inline-grid gap-1 rounded-2xl overflow-hidden " <>
                (cond do
                  length(@attachments) == 1 -> "grid-cols-1"
                  length(@attachments) == 2 -> "grid-cols-2"
                  true -> "grid-cols-2"
                end) <>
                (if @is_mine, do: " rounded-br-md", else: " rounded-bl-md")
              }>
                <div
                  :for={attachment <- @attachments}
                  class="relative overflow-hidden cursor-pointer"
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
              <!-- Heure overlay sur image -->
              <div class="absolute bottom-2 right-2 flex items-center gap-1 bg-black/50 text-white px-1.5 py-0.5 rounded text-[10px]">
                <span id={"msg-time-#{@message.id}"} phx-hook="LocalTime" data-time={NaiveDateTime.to_iso8601(@message.inserted_at)}>
                  {format_message_time(@message.inserted_at)}
                </span>
                <span :if={@is_mine}>{Message.status_icon(@message.status)}</span>
              </div>
            </div>

            <!-- Images avec texte -->
            <div :if={@has_attachments && @has_body} class={if @is_mine, do: "text-right", else: "text-left"}>
              <div class={
                "inline-block rounded-2xl overflow-hidden " <>
                if @is_mine, do: "bg-primary rounded-br-md", else: "bg-base-200 rounded-bl-md"
              }>
                <div class={
                  "grid gap-1 " <>
                  cond do
                    length(@attachments) == 1 -> "grid-cols-1"
                    length(@attachments) == 2 -> "grid-cols-2"
                    true -> "grid-cols-2"
                  end
                }>
                  <div
                    :for={attachment <- @attachments}
                    class="relative overflow-hidden cursor-pointer"
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
                <!-- Texte avec heure intégrée -->
                <div class={
                  "px-3 pt-2 pb-1 " <>
                  if @is_mine, do: "text-primary-content", else: "text-base-content"
                }>
                  <p class="text-[15px] whitespace-pre-wrap break-words">{@message.body}</p>
                  <div class={"flex items-center gap-1 justify-end mt-1 " <>
                    if @is_mine, do: "text-primary-content/60", else: "text-base-content/50"}>
                    <span id={"msg-time-#{@message.id}"} phx-hook="LocalTime" data-time={NaiveDateTime.to_iso8601(@message.inserted_at)} class="text-[10px]">
                      {format_message_time(@message.inserted_at)}
                    </span>
                    <span :if={@is_mine} class="text-[10px]">
                      {Message.status_icon(@message.status)}
                    </span>
                  </div>
                </div>
              </div>
            </div>

            <!-- Bulle du message texte seulement (heure intégrée style WhatsApp) -->
            <div :if={@has_body && !@has_attachments} class={
              "inline-block px-3 pt-2 pb-1 rounded-2xl " <>
              if @is_mine do
                "bg-primary text-primary-content rounded-br-md"
              else
                "bg-base-200 text-base-content rounded-bl-md"
              end
            }>
              <p class="text-[15px] whitespace-pre-wrap break-words">{@message.body}</p>
              <!-- Heure et statut intégrés en bas à droite -->
              <div class={"flex items-center gap-1 justify-end mt-1 " <>
                if @is_mine, do: "text-primary-content/60", else: "text-base-content/50"}>
                <span
                  id={"msg-time-#{@message.id}"}
                  phx-hook="LocalTime"
                  data-time={NaiveDateTime.to_iso8601(@message.inserted_at)}
                  class="text-[10px]"
                >
                  {format_message_time(@message.inserted_at)}
                </span>
                <span :if={@is_mine} class="text-[10px]">
                  {Message.status_icon(@message.status)}
                </span>
              </div>
            </div>
          <% end %>

          <!-- Images attachées pour messages avec réponse -->
          <div :if={@reply_to && @has_attachments} class={"mt-1 " <> if @is_mine, do: "text-right", else: "text-left"}>
            <div class={
              "inline-grid gap-1 rounded-2xl overflow-hidden " <>
              cond do
                length(@attachments) == 1 -> "grid-cols-1"
                length(@attachments) == 2 -> "grid-cols-2"
                true -> "grid-cols-2"
              end
            }>
              <div
                :for={attachment <- @attachments}
                class="relative overflow-hidden cursor-pointer"
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
        <% end %>
        </div>

        <!-- Actions à droite pour mes messages (apparaissent au hover) -->
        <div :if={!@is_deleted && @is_mine} class="hidden md:flex items-center gap-0.5 opacity-0 group-hover:opacity-100 transition-opacity self-center">
          <button
            type="button"
            phx-click="reply_to_message"
            phx-value-id={@message.id}
            class="btn btn-ghost btn-xs btn-circle hover:bg-base-200"
            title="Répondre"
          >
            <svg xmlns="http://www.w3.org/2000/svg" class="h-3.5 w-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 10h10a8 8 0 018 8v2M3 10l6 6m-6-6l6-6" />
            </svg>
          </button>
          <button
            type="button"
            phx-click="open_reaction_picker"
            phx-value-id={@message.id}
            class="btn btn-ghost btn-xs btn-circle hover:bg-base-200"
            title="Réagir"
          >
            <svg xmlns="http://www.w3.org/2000/svg" class="h-3.5 w-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M14.828 14.828a4 4 0 01-5.656 0M9 10h.01M15 10h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
          </button>
          <button
            type="button"
            phx-click="open_delete_modal"
            phx-value-id={@message.id}
            class="btn btn-ghost btn-xs btn-circle hover:bg-base-200 text-error/70 hover:text-error"
            title="Supprimer"
          >
            <svg xmlns="http://www.w3.org/2000/svg" class="h-3.5 w-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
            </svg>
          </button>
        </div>
      </div>
      <!-- Fin de la row Avatar + Bulle -->

      <!-- Réactions affichées (en dehors de la row avatar pour ne pas affecter l'alignement) -->
      <div :if={@has_reactions && !@is_deleted} class={
        "flex flex-wrap gap-1 mt-1 " <>
        (if @is_group && !@is_mine, do: "ml-9 ", else: "") <>
        (if @is_mine, do: "justify-end", else: "justify-start")
      }>
        <button
          :for={reaction <- @reactions_grouped}
          type="button"
          phx-click="toggle_reaction"
          phx-value-message-id={@message.id}
          phx-value-emoji={reaction.emoji}
          class={"inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-xs transition-colors " <>
            if @current_user_id in reaction.user_ids,
              do: "bg-primary/20 border border-primary/30 text-primary",
              else: "bg-base-200 hover:bg-base-300 border border-base-300"}
        >
          <span>{reaction.emoji}</span>
          <span class="font-medium">{reaction.count}</span>
        </button>
      </div>

    </div>
    """
  end

  # Helper pour grouper les réactions par emoji
  defp group_reactions(reactions) when is_list(reactions) do
    reactions
    |> Enum.group_by(& &1.emoji)
    |> Enum.map(fn {emoji, reactions} ->
      %{
        emoji: emoji,
        count: length(reactions),
        user_ids: Enum.map(reactions, & &1.user_id)
      }
    end)
    |> Enum.sort_by(& &1.count, :desc)
  end
  defp group_reactions(_), do: []

  # ============== REPLY PREVIEW ==============

  attr :reply_message, :map, required: true

  def reply_preview(assigns) do
    ~H"""
    <div class="flex items-center gap-2 px-4 py-2 bg-base-200/50 border-l-4 border-primary">
      <div class="flex-1 min-w-0">
        <p class="text-xs font-medium text-primary">
          Répondre à {@reply_message.sender.name}
        </p>
        <p class="text-sm text-base-content/60 truncate">
          {@reply_message.body || "Photo"}
        </p>
      </div>
      <button
        type="button"
        phx-click="cancel_reply"
        class="btn btn-ghost btn-xs btn-circle"
      >
        <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
        </svg>
      </button>
    </div>
    """
  end

  # ============== DELETE MODAL ==============

  attr :message, :map, required: true
  attr :is_mine, :boolean, default: true

  def delete_message_modal(assigns) do
    is_deleted_for_all = assigns.message.deleted_for_all_at != nil
    assigns = assign(assigns, :is_deleted_for_all, is_deleted_for_all)

    ~H"""
    <div class="fixed inset-0 bg-black/60 z-[100] flex items-end md:items-center justify-center">
      <div
        class="bg-base-100 rounded-t-2xl md:rounded-2xl shadow-2xl w-full md:max-w-sm overflow-hidden animate-slide-up md:animate-none safe-area-bottom"
        phx-click-away="close_delete_modal"
      >
        <%= if @is_deleted_for_all do %>
          <!-- Message déjà supprimé pour tous - proposer de masquer de sa vue -->
          <div class="p-5 pb-3 text-center">
            <div class="w-14 h-14 mx-auto mb-3 rounded-full bg-base-200 flex items-center justify-center">
              <svg xmlns="http://www.w3.org/2000/svg" class="h-7 w-7 text-base-content/40" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M18.364 18.364A9 9 0 005.636 5.636m12.728 12.728A9 9 0 015.636 5.636m12.728 12.728L5.636 5.636" />
              </svg>
            </div>
            <h3 class="text-lg font-bold text-base-content">Message supprimé</h3>
            <p class="text-sm text-base-content/60 mt-1">Ce message a été supprimé pour tous</p>
          </div>

          <!-- Option: Masquer de ma vue (pour le sender uniquement) -->
          <div :if={@is_mine} class="px-4 pb-4">
            <button
              type="button"
              phx-click="delete_message_for_me"
              phx-value-id={@message.id}
              class="w-full flex items-center gap-4 p-4 rounded-xl bg-base-200/50 hover:bg-base-200 border border-transparent hover:border-base-300 transition-all duration-200 group"
            >
              <div class="w-10 h-10 rounded-full bg-base-300 flex items-center justify-center group-hover:bg-base-content/10 transition-colors">
                <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 text-base-content/70" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13.875 18.825A10.05 10.05 0 0112 19c-4.478 0-8.268-2.943-9.543-7a9.97 9.97 0 011.563-3.029m5.858.908a3 3 0 114.243 4.243M9.878 9.878l4.242 4.242M9.878 9.878L3 3m6.878 6.878L21 21" />
                </svg>
              </div>
              <div class="flex-1 text-left">
                <p class="font-semibold text-base-content">Masquer de ma vue</p>
                <p class="text-xs text-base-content/50 mt-0.5">Cacher complètement ce message</p>
              </div>
              <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 text-base-content/30 group-hover:text-base-content/50 transition-colors" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7" />
              </svg>
            </button>
          </div>

          <div class="px-4 pb-5">
            <button
              type="button"
              phx-click="close_delete_modal"
              class="btn btn-ghost w-full h-12 rounded-xl text-base-content/70 hover:text-base-content font-medium"
            >
              Fermer
            </button>
          </div>
        <% else %>
          <!-- Header avec icône -->
          <div class="p-5 pb-3 text-center">
            <div class="w-14 h-14 mx-auto mb-3 rounded-full bg-error/10 flex items-center justify-center">
              <svg xmlns="http://www.w3.org/2000/svg" class="h-7 w-7 text-error" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
              </svg>
            </div>
            <h3 class="text-lg font-bold text-base-content">Supprimer le message ?</h3>
            <p class="text-sm text-base-content/60 mt-1">Choisissez comment supprimer ce message</p>
          </div>

          <!-- Preview du message -->
          <div class="px-5 pb-4">
            <div class="bg-base-200/70 rounded-xl p-3 border border-base-300/50">
              <p class="text-sm text-base-content/70 line-clamp-2 italic">
                "{@message.body || "📷 Photo"}"
              </p>
            </div>
          </div>

          <!-- Options de suppression -->
          <div class="px-4 pb-4 space-y-2">
            <!-- Option: Supprimer pour moi -->
            <button
              type="button"
              phx-click="delete_message_for_me"
              phx-value-id={@message.id}
              class="w-full flex items-center gap-4 p-4 rounded-xl bg-base-200/50 hover:bg-base-200 border border-transparent hover:border-base-300 transition-all duration-200 group"
            >
              <div class="w-10 h-10 rounded-full bg-base-300 flex items-center justify-center group-hover:bg-base-content/10 transition-colors">
                <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 text-base-content/70" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13.875 18.825A10.05 10.05 0 0112 19c-4.478 0-8.268-2.943-9.543-7a9.97 9.97 0 011.563-3.029m5.858.908a3 3 0 114.243 4.243M9.878 9.878l4.242 4.242M9.878 9.878L3 3m6.878 6.878L21 21" />
                </svg>
              </div>
              <div class="flex-1 text-left">
                <p class="font-semibold text-base-content">Supprimer pour moi</p>
                <p class="text-xs text-base-content/50 mt-0.5">Visible uniquement pour vous</p>
              </div>
              <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 text-base-content/30 group-hover:text-base-content/50 transition-colors" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7" />
              </svg>
            </button>

            <!-- Option: Supprimer pour tous -->
            <button
              type="button"
              phx-click="delete_message_for_all"
              phx-value-id={@message.id}
              class="w-full flex items-center gap-4 p-4 rounded-xl bg-error/5 hover:bg-error/10 border border-error/20 hover:border-error/30 transition-all duration-200 group"
            >
              <div class="w-10 h-10 rounded-full bg-error/10 flex items-center justify-center group-hover:bg-error/20 transition-colors">
                <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 text-error" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
                </svg>
              </div>
              <div class="flex-1 text-left">
                <p class="font-semibold text-error">Supprimer pour tous</p>
                <p class="text-xs text-base-content/50 mt-0.5">Plus personne ne verra ce message</p>
              </div>
              <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 text-error/30 group-hover:text-error/50 transition-colors" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7" />
              </svg>
            </button>
          </div>

          <!-- Bouton Annuler -->
          <div class="px-4 pb-5">
            <button
              type="button"
              phx-click="close_delete_modal"
              class="btn btn-ghost w-full h-12 rounded-xl text-base-content/70 hover:text-base-content font-medium"
            >
              Annuler
            </button>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  # ============== MOBILE CONTEXT MENU ==============

  attr :message, :map, required: true
  attr :is_mine, :boolean, required: true

  def message_context_menu(assigns) do
    is_deleted = assigns.message.deleted_for_all_at != nil
    assigns = assign(assigns, :is_deleted, is_deleted)

    ~H"""
    <div
      class="fixed inset-0 bg-black/50 z-[100] flex items-end md:hidden"
      phx-click="close_context_menu"
    >
      <div
        class="bg-base-100 w-full rounded-t-2xl overflow-hidden animate-slide-up safe-area-bottom"
        phx-click-away="close_context_menu"
      >
        <!-- Message supprimé - actions limitées -->
        <%= if @is_deleted do %>
          <div class="p-6 text-center">
            <div class="w-12 h-12 mx-auto mb-3 rounded-full bg-base-200 flex items-center justify-center">
              <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6 text-base-content/40" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M18.364 18.364A9 9 0 005.636 5.636m12.728 12.728A9 9 0 015.636 5.636m12.728 12.728L5.636 5.636" />
              </svg>
            </div>
            <p class="text-base-content/60 text-sm">Ce message a été supprimé</p>
          </div>
        <% else %>
          <!-- Réactions rapides -->
          <div class="flex justify-center gap-2 p-4 border-b border-base-200 bg-base-200/30">
            <button
              :for={emoji <- MessageReaction.available_emojis()}
              type="button"
              phx-click="toggle_reaction"
              phx-value-message-id={@message.id}
              phx-value-emoji={emoji}
              class="text-2xl hover:scale-125 active:scale-95 transition-transform p-2"
            >
              {emoji}
            </button>
          </div>

          <!-- Preview du message -->
          <div class="px-4 py-3 border-b border-base-200">
            <p class="text-sm text-base-content/70 line-clamp-2">
              {@message.body || "Photo"}
            </p>
          </div>

          <!-- Actions -->
          <div class="py-2">
            <button
              type="button"
              phx-click="reply_to_message"
              phx-value-id={@message.id}
              class="w-full flex items-center gap-4 px-4 py-3 hover:bg-base-200 transition-colors"
            >
              <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 text-base-content/70" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 10h10a8 8 0 018 8v2M3 10l6 6m-6-6l6-6" />
              </svg>
              <span class="font-medium">Répondre</span>
            </button>

            <button
              type="button"
              phx-click="copy_message"
              phx-value-id={@message.id}
              class="w-full flex items-center gap-4 px-4 py-3 hover:bg-base-200 transition-colors"
            >
              <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 text-base-content/70" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 16H6a2 2 0 01-2-2V6a2 2 0 012-2h8a2 2 0 012 2v2m-6 12h8a2 2 0 002-2v-8a2 2 0 00-2-2h-8a2 2 0 00-2 2v8a2 2 0 002 2z" />
              </svg>
              <span class="font-medium">Copier</span>
            </button>

            <button
              type="button"
              phx-click="forward_message"
              phx-value-id={@message.id}
              class="w-full flex items-center gap-4 px-4 py-3 hover:bg-base-200 transition-colors"
            >
              <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 text-base-content/70" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8.684 13.342C8.886 12.938 9 12.482 9 12c0-.482-.114-.938-.316-1.342m0 2.684a3 3 0 110-2.684m0 2.684l6.632 3.316m-6.632-6l6.632-3.316m0 0a3 3 0 105.367-2.684 3 3 0 00-5.367 2.684zm0 9.316a3 3 0 105.368 2.684 3 3 0 00-5.368-2.684z" />
              </svg>
              <span class="font-medium">Transférer</span>
            </button>

            <button
              :if={@is_mine}
              type="button"
              phx-click="open_delete_modal"
              phx-value-id={@message.id}
              class="w-full flex items-center gap-4 px-4 py-3 hover:bg-base-200 transition-colors text-error"
            >
              <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
              </svg>
              <span class="font-medium">Supprimer</span>
            </button>
          </div>
        <% end %>

        <!-- Bouton annuler -->
        <div class="p-4 border-t border-base-200">
          <button
            type="button"
            phx-click="close_context_menu"
            class="btn btn-ghost w-full"
          >
            Annuler
          </button>
        </div>
      </div>
    </div>
    """
  end

  # ============== REACTION PICKER (Desktop) ==============

  attr :message_id, :integer, required: true

  def reaction_picker(assigns) do
    ~H"""
    <div
      class="fixed inset-0 z-[100]"
      phx-click="close_reaction_picker"
    >
      <div
        class="absolute bg-base-100 rounded-full shadow-xl border border-base-200 p-2 flex gap-1"
        style="top: 50%; left: 50%; transform: translate(-50%, -50%)"
        phx-click-away="close_reaction_picker"
      >
        <button
          :for={emoji <- MessageReaction.available_emojis()}
          type="button"
          phx-click="toggle_reaction"
          phx-value-message-id={@message_id}
          phx-value-emoji={emoji}
          class="text-xl hover:scale-125 active:scale-95 transition-transform p-2 hover:bg-base-200 rounded-full"
        >
          {emoji}
        </button>
      </div>
    </div>
    """
  end

  # ============== CHAT INPUT ==============

  attr :form, :any, required: true
  attr :uploads, :any, default: nil
  attr :disabled, :boolean, default: false
  attr :reply_message, :map, default: nil

  def chat_input(assigns) do
    ~H"""
    <div class="border-t border-base-200 bg-base-100">
      <!-- Reply preview -->
      <.reply_preview :if={@reply_message} reply_message={@reply_message} />

      <.form
        for={@form}
        phx-submit="send_message"
        phx-change="validate_chat"
        class="p-3"
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
    </div>
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
  attr :reply_message, :map, default: nil
  attr :context_menu_message, :map, default: nil
  attr :delete_modal_message, :map, default: nil
  attr :reaction_picker_message_id, :integer, default: nil

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
          phx-click="close_reaction_picker"
        >
          <.message_list
            messages={@messages}
            current_user={@current_user}
            is_group={@is_group}
            reaction_picker_message_id={@reaction_picker_message_id}
          />
        </div>

        <!-- Input avec safe area pour mobile -->
        <div class="safe-area-bottom">
          <.chat_input form={@form} uploads={@uploads} reply_message={@reply_message} />
        </div>
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
      <.delete_message_modal :if={@delete_modal_message} message={@delete_modal_message} is_mine={@delete_modal_message.sender_id == @current_user.id} />
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
