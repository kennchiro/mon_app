defmodule MonAppWeb.ChatComponents do
  @moduledoc """
  Composants réutilisables pour le chat.
  """

  use Phoenix.Component
  import MonAppWeb.CoreComponents

  alias MonApp.Chat.Message
  alias MonApp.Chat.Conversation

  # ============== CONVERSATION LIST ==============

  attr :conversations, :list, required: true
  attr :current_user, :map, required: true
  attr :online_users, :list, default: []

  def conversation_list(assigns) do
    ~H"""
    <div class="divide-y divide-base-200">
      <.conversation_item
        :for={conv <- @conversations}
        conversation={conv}
        current_user={@current_user}
        online={other_user_id(conv, @current_user.id) in @online_users}
      />
      <div :if={@conversations == []} class="p-8 text-center text-base-content/50">
        <svg xmlns="http://www.w3.org/2000/svg" class="h-12 w-12 mx-auto mb-3 opacity-50" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z" />
        </svg>
        <p class="font-medium">Aucune conversation</p>
        <p class="text-sm mt-1">Commencez une discussion avec un ami !</p>
      </div>
    </div>
    """
  end

  attr :conversation, :map, required: true
  attr :current_user, :map, required: true
  attr :online, :boolean, default: false

  def conversation_item(assigns) do
    other_user = Conversation.other_user(assigns.conversation, assigns.current_user.id)
    last_message = assigns.conversation.last_message
    unread_count = assigns.conversation.unread_count || 0

    assigns =
      assigns
      |> assign(:other_user, other_user)
      |> assign(:last_message, last_message)
      |> assign(:unread_count, unread_count)

    ~H"""
    <button
      type="button"
      phx-click="open_chat"
      phx-value-id={@conversation.id}
      class={"w-full flex items-center gap-3 p-3 hover:bg-base-200 transition-colors cursor-pointer text-left " <>
        if @unread_count > 0, do: "bg-primary/5", else: ""}
    >
      <!-- Avatar avec indicateur online -->
      <div class="relative">
        <.user_avatar name={@other_user.name} size="w-12 h-12" />
        <span
          :if={@online}
          class="absolute bottom-0 right-0 h-3.5 w-3.5 rounded-full bg-success border-2 border-base-100"
        />
      </div>

      <!-- Contenu -->
      <div class="flex-1 min-w-0">
        <div class="flex items-center justify-between">
          <span class={"font-semibold truncate " <> if @unread_count > 0, do: "text-base-content", else: "text-base-content"}>
            {@other_user.name}
          </span>
          <span :if={@last_message} class="text-xs text-base-content/50">
            {format_time(@last_message.inserted_at)}
          </span>
        </div>
        <div class="flex items-center gap-2 mt-0.5">
          <p class={"text-sm truncate flex-1 " <>
            if @unread_count > 0, do: "text-base-content font-medium", else: "text-base-content/60"}>
            <span :if={@last_message && @last_message.sender_id == @current_user.id} class="text-base-content/50">
              Vous:
            </span>
            {if @last_message, do: @last_message.body, else: "Nouvelle conversation"}
          </p>
          <span
            :if={@unread_count > 0}
            class="badge badge-primary badge-sm"
          >
            {@unread_count}
          </span>
        </div>
      </div>
    </button>
    """
  end

  # ============== MESSAGES ==============

  attr :messages, :list, required: true
  attr :current_user, :map, required: true

  def message_list(assigns) do
    ~H"""
    <div class="flex flex-col gap-1 p-4">
      <.message_bubble
        :for={message <- @messages}
        message={message}
        is_mine={message.sender_id == @current_user.id}
      />
    </div>
    """
  end

  attr :message, :map, required: true
  attr :is_mine, :boolean, required: true

  def message_bubble(assigns) do
    ~H"""
    <div class={"flex " <> if @is_mine, do: "justify-end", else: "justify-start"}>
      <div class={"max-w-[75%] " <> if @is_mine, do: "order-2", else: ""}>
        <!-- Bulle du message -->
        <div class={
          "px-4 py-2 rounded-2xl " <>
          if @is_mine do
            "bg-primary text-primary-content rounded-br-md"
          else
            "bg-base-200 text-base-content rounded-bl-md"
          end
        }>
          <p class="text-[15px] whitespace-pre-wrap break-words">{@message.body}</p>
        </div>
        <!-- Heure et statut -->
        <div class={"flex items-center gap-1 mt-0.5 text-xs text-base-content/50 " <>
          if @is_mine, do: "justify-end", else: "justify-start"}>
          <span>{format_message_time(@message.inserted_at)}</span>
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
  attr :disabled, :boolean, default: false

  def chat_input(assigns) do
    ~H"""
    <.form
      for={@form}
      phx-submit="send_message"
      phx-change="typing"
      class="p-3 border-t border-base-200 bg-base-100"
    >
      <div class="flex items-end gap-2 bg-base-200/50 rounded-2xl p-2">
        <!-- Bouton emoji -->
        <button
          type="button"
          class="btn btn-ghost btn-sm btn-circle text-base-content/50 hover:text-base-content"
          disabled={@disabled}
        >
          <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M14.828 14.828a4 4 0 01-5.656 0M9 10h.01M15 10h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
          </svg>
        </button>

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

        <!-- Bouton pièce jointe -->
        <button
          type="button"
          class="btn btn-ghost btn-sm btn-circle text-base-content/50 hover:text-base-content"
          disabled={@disabled}
        >
          <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15.172 7l-6.586 6.586a2 2 0 102.828 2.828l6.414-6.586a4 4 0 00-5.656-5.656l-6.415 6.585a6 6 0 108.486 8.486L20.5 13" />
          </svg>
        </button>

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

  attr :other_user, :map, required: true
  attr :messages, :list, required: true
  attr :current_user, :map, required: true
  attr :online, :boolean, default: false
  attr :typing, :boolean, default: false
  attr :form, :any, required: true

  def chat_bottom_sheet(assigns) do
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

        <!-- Messages -->
        <div
          class="flex-1 overflow-y-auto bg-base-200/30 overscroll-contain"
          id="sheet-messages-container"
          phx-hook="ScrollToBottom"
        >
          <.message_list messages={@messages} current_user={@current_user} />
        </div>

        <!-- Input avec safe area pour mobile -->
        <div class="safe-area-bottom">
          <.chat_input form={@form} />
        </div>
      </div>
    </div>
    """
  end

  # ============== NEW CONVERSATION MODAL ==============

  attr :friends, :list, required: true
  attr :online_users, :list, default: []

  def new_conversation_modal(assigns) do
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

        <div class="flex-1 overflow-y-auto">
          <div :if={@friends == []} class="p-8 text-center text-base-content/50">
            <p>Vous n'avez pas encore d'amis.</p>
            <p class="text-sm mt-1">Ajoutez des amis pour commencer à discuter !</p>
          </div>
          <div :for={friend <- @friends} class="border-b border-base-200 last:border-0">
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
      </div>
    </div>
    """
  end

  # ============== HELPERS ==============

  attr :name, :string, required: true
  attr :size, :string, default: "w-10 h-10"

  def user_avatar(assigns) do
    initials = assigns.name
      |> String.split(" ")
      |> Enum.map(&String.first/1)
      |> Enum.take(2)
      |> Enum.join()
      |> String.upcase()

    assigns = assign(assigns, :initials, initials)

    ~H"""
    <div class={"#{@size} rounded-full bg-primary/10 flex items-center justify-center"}>
      <span class="text-primary font-semibold text-sm">{@initials}</span>
    </div>
    """
  end

  defp other_user_id(conversation, current_user_id) do
    Conversation.other_user_id(conversation, current_user_id)
  end

  defp format_time(datetime) do
    # Convertir NaiveDateTime en DateTime si nécessaire
    datetime = to_datetime(datetime)
    now = DateTime.utc_now()
    diff = DateTime.diff(now, datetime, :second)

    cond do
      diff < 60 -> "À l'instant"
      diff < 3600 -> "#{div(diff, 60)} min"
      diff < 86400 ->
        datetime
        |> DateTime.to_time()
        |> Calendar.strftime("%H:%M")
      diff < 604800 ->
        datetime
        |> DateTime.to_date()
        |> Calendar.strftime("%a")
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
