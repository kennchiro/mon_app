defmodule MonAppWeb.Toast do
  use Phoenix.Component
  use MonAppWeb, :verified_routes

  @doc """
  Toast notification popup component.

  Toast data structure:
  %{
    id: unique_integer,
    type: :message | :notification,
    title: "string",
    body: "string",
    avatar: "filename" | nil,
    initial: "A",
    href: "/path",
    exiting: false
  }
  """

  attr :toast, :map, default: nil

  def toast_popup(assigns) do
    ~H"""
    <div
      :if={@toast}
      class={"fixed z-[100] top-2 left-2 right-2 md:top-4 md:left-auto md:right-4 md:w-96 #{if @toast[:exiting], do: "toast-exit", else: "toast-enter"}"}
    >
      <a
        href={@toast.href}
        phx-click="dismiss_toast"
        class="block bg-base-100 rounded-2xl shadow-2xl border border-base-200 overflow-hidden hover:shadow-xl transition-shadow"
      >
        <div class="flex items-start gap-3 p-3.5">
          <!-- Icon / Avatar -->
          <div class="shrink-0">
            <%= if @toast.type == :message do %>
              <!-- Message: show avatar -->
              <%= if @toast[:avatar] do %>
                <div class="w-11 h-11 rounded-full overflow-hidden">
                  <img src={"/uploads/avatars/#{@toast.avatar}"} alt="" class="w-full h-full object-cover" />
                </div>
              <% else %>
                <div class="w-11 h-11 rounded-full bg-pink-500 grid place-items-center">
                  <span class="text-white text-lg font-bold">{@toast.initial}</span>
                </div>
              <% end %>
            <% else %>
              <!-- Notification: show type icon -->
              <div class={"w-11 h-11 rounded-full grid place-items-center #{toast_icon_bg(@toast[:notif_type])}"}>
                <.toast_icon type={@toast[:notif_type]} />
              </div>
            <% end %>
          </div>

          <!-- Content -->
          <div class="flex-1 min-w-0 pt-0.5">
            <div class="flex items-center justify-between gap-2">
              <span class="text-sm font-semibold text-base-content truncate">{@toast.title}</span>
              <span class="text-[10px] text-base-content/40 shrink-0">maintenant</span>
            </div>
            <p class="text-sm text-base-content/60 line-clamp-2 mt-0.5">{@toast.body}</p>
          </div>

          <!-- Close -->
          <button
            type="button"
            phx-click="dismiss_toast"
            class="shrink-0 w-6 h-6 rounded-full grid place-items-center hover:bg-base-200 transition-colors mt-0.5"
            onclick="event.preventDefault(); event.stopPropagation();"
          >
            <svg xmlns="http://www.w3.org/2000/svg" class="h-3.5 w-3.5 text-base-content/30" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
              <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12" />
            </svg>
          </button>
        </div>

        <!-- Progress bar -->
        <div class="h-0.5 bg-base-200">
          <div class={"h-full rounded-full toast-progress-bar #{toast_progress_color(@toast.type)}"}></div>
        </div>
      </a>
    </div>
    """
  end

  defp toast_progress_color(:message), do: "bg-pink-500"
  defp toast_progress_color(_), do: "bg-primary"

  defp toast_icon_bg("friend_request"), do: "bg-blue-500/10"
  defp toast_icon_bg("friend_accepted"), do: "bg-green-500/10"
  defp toast_icon_bg("date_application"), do: "bg-pink-500/10"
  defp toast_icon_bg("date_accepted"), do: "bg-pink-500/10"
  defp toast_icon_bg("comment"), do: "bg-blue-500/10"
  defp toast_icon_bg("reply"), do: "bg-blue-500/10"
  defp toast_icon_bg(_), do: "bg-base-200"

  attr :type, :string, default: nil

  defp toast_icon(%{type: "friend_request"} = assigns) do
    ~H"""
    <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 text-blue-500" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
      <path stroke-linecap="round" stroke-linejoin="round" d="M18 9v3m0 0v3m0-3h3m-3 0h-3m-2-5a4 4 0 11-8 0 4 4 0 018 0zM3 20a6 6 0 0112 0v1H3v-1z" />
    </svg>
    """
  end

  defp toast_icon(%{type: "friend_accepted"} = assigns) do
    ~H"""
    <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 text-green-500" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
      <path stroke-linecap="round" stroke-linejoin="round" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
    </svg>
    """
  end

  defp toast_icon(%{type: "date_application"} = assigns) do
    ~H"""
    <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 text-pink-500" viewBox="0 0 24 24" fill="currentColor">
      <path d="M12 21.35l-1.45-1.32C5.4 15.36 2 12.28 2 8.5 2 5.42 4.42 3 7.5 3c1.74 0 3.41.81 4.5 2.09C13.09 3.81 14.76 3 16.5 3 19.58 3 22 5.42 22 8.5c0 3.78-3.4 6.86-8.55 11.54L12 21.35z" />
    </svg>
    """
  end

  defp toast_icon(%{type: "date_accepted"} = assigns) do
    ~H"""
    <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 text-pink-500" viewBox="0 0 24 24" fill="currentColor">
      <path d="M12 21.35l-1.45-1.32C5.4 15.36 2 12.28 2 8.5 2 5.42 4.42 3 7.5 3c1.74 0 3.41.81 4.5 2.09C13.09 3.81 14.76 3 16.5 3 19.58 3 22 5.42 22 8.5c0 3.78-3.4 6.86-8.55 11.54L12 21.35z" />
    </svg>
    """
  end

  defp toast_icon(%{type: "comment"} = assigns) do
    ~H"""
    <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 text-blue-500" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
      <path stroke-linecap="round" stroke-linejoin="round" d="M7 8h10M7 12h4m1 8l-4-4H5a2 2 0 01-2-2V6a2 2 0 012-2h14a2 2 0 012 2v8a2 2 0 01-2 2h-3l-4 4z" />
    </svg>
    """
  end

  defp toast_icon(%{type: "reply"} = assigns) do
    ~H"""
    <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 text-blue-500" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
      <path stroke-linecap="round" stroke-linejoin="round" d="M3 10h10a8 8 0 018 8v2M3 10l6 6m-6-6l6-6" />
    </svg>
    """
  end

  defp toast_icon(assigns) do
    ~H"""
    <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 text-base-content/50" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
      <path stroke-linecap="round" stroke-linejoin="round" d="M15 17h5l-1.405-1.405A2.032 2.032 0 0118 14.158V11a6.002 6.002 0 00-4-5.659V5a2 2 0 10-4 0v.341C7.67 6.165 6 8.388 6 11v3.159c0 .538-.214 1.055-.595 1.436L4 17h5m6 0v1a3 3 0 11-6 0v-1m6 0H9" />
    </svg>
    """
  end

  # ============== HELPER FUNCTIONS ==============

  @doc "Build toast data from a notification"
  def toast_from_notification(notification) do
    %{
      id: System.unique_integer([:positive]),
      type: :notification,
      notif_type: notification.type,
      title: toast_title(notification.type),
      body: notification.message,
      avatar: notification.actor && notification.actor.avatar,
      initial: notification.actor && String.first(notification.actor.name),
      href: toast_href(notification),
      exiting: false
    }
  end

  @doc "Build toast data from a chat message"
  def toast_from_message(message, sender_name, sender_avatar) do
    %{
      id: System.unique_integer([:positive]),
      type: :message,
      notif_type: nil,
      title: sender_name,
      body: message.body || "Nouveau message",
      avatar: sender_avatar,
      initial: String.first(sender_name || "?"),
      href: "/conversations",
      exiting: false
    }
  end

  defp toast_title("friend_request"), do: "Demande d'ami"
  defp toast_title("friend_accepted"), do: "Ami accepté"
  defp toast_title("date_application"), do: "Nouvelle candidature"
  defp toast_title("date_accepted"), do: "Candidature acceptée"
  defp toast_title("comment"), do: "Nouveau commentaire"
  defp toast_title("reply"), do: "Nouvelle réponse"
  defp toast_title(_), do: "Notification"

  defp toast_href(%{type: type}) when type in ["date_application", "date_accepted"], do: "/my-dates"
  defp toast_href(%{type: "friend_request"}), do: "/users?tab=pending"
  defp toast_href(%{type: "friend_accepted"}), do: "/users?tab=friends"
  defp toast_href(%{post_id: post_id}) when not is_nil(post_id), do: "/posts?post_id=#{post_id}"
  defp toast_href(_), do: "/posts"
end
