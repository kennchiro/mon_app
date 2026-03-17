defmodule MonAppWeb.Navbar do
  use Phoenix.Component
  use MonAppWeb, :verified_routes

  defp time_ago(datetime) do
    now = NaiveDateTime.utc_now()
    diff = NaiveDateTime.diff(now, datetime, :second)

    cond do
      diff < 60 -> "à l'instant"
      diff < 3600 -> "il y a #{div(diff, 60)} min"
      diff < 86400 -> "il y a #{div(diff, 3600)} h"
      diff < 604_800 -> "il y a #{div(diff, 86400)} j"
      true -> Calendar.strftime(datetime, "%d/%m/%Y")
    end
  end

  def logout_link(assigns) do
    ~H"""
    <form action={~p"/auth/logout"} method="post" class="contents">
      <input type="hidden" name="_method" value="delete" />
      <input type="hidden" name="_csrf_token" value={Phoenix.Controller.get_csrf_token()} />
      <button type="submit" class="flex items-center gap-2 w-full text-error hover:bg-base-200 px-4 py-2 rounded-lg">
        <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1" />
        </svg>
        Déconnexion
      </button>
    </form>
    """
  end

  attr :current_user, :map, required: true
  attr :current_path, :string, default: "/"
  attr :pending_requests_count, :integer, default: 0
  attr :unread_messages_count, :integer, default: 0
  attr :notifications, :list, default: []
  attr :unread_notifications_count, :integer, default: 0

  def navbar(assigns) do
    ~H"""
    <!-- ===== TOP HEADER (mobile + desktop) ===== -->
    <nav class="bg-base-100 shadow-sm sticky top-0 z-50 px-4 h-14 flex items-center">
      <!-- Logo -->
      <div class="flex-1 min-w-0">
        <.link navigate={~p"/posts"} class="flex items-center gap-1.5 text-xl font-bold truncate">
          <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 text-pink-500" viewBox="0 0 24 24" fill="currentColor">
            <path d="M12 21.35l-1.45-1.32C5.4 15.36 2 12.28 2 8.5 2 5.42 4.42 3 7.5 3c1.74 0 3.41.81 4.5 2.09C13.09 3.81 14.76 3 16.5 3 19.58 3 22 5.42 22 8.5c0 3.78-3.4 6.86-8.55 11.54L12 21.35z" />
          </svg>
          <span class="text-base-content">Date<span class="text-pink-500">App</span></span>
        </.link>
      </div>

      <!-- Navigation centrale (desktop only) -->
      <div class="hidden md:flex gap-1 bg-base-200/60 rounded-full p-1">
        <.nav_link href={~p"/posts"} active={@current_path == "/posts"}>
          <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
            <path stroke-linecap="round" stroke-linejoin="round" d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6" />
          </svg>
        </.nav_link>
        <.nav_link href={~p"/my-dates"} active={@current_path == "/my-dates"}>
          <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <path stroke-linecap="round" stroke-linejoin="round" d="M4.318 6.318a4.5 4.5 0 000 6.364L12 20.364l7.682-7.682a4.5 4.5 0 00-6.364-6.364L12 7.636l-1.318-1.318a4.5 4.5 0 00-6.364 0z" />
          </svg>
        </.nav_link>
        <.nav_link href={~p"/users"} active={@current_path == "/users"} badge={@pending_requests_count}>
          <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
            <path stroke-linecap="round" stroke-linejoin="round" d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z" />
          </svg>
        </.nav_link>
        <.nav_link href={~p"/conversations"} active={@current_path == "/conversations"} badge={@unread_messages_count}>
          <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
            <path stroke-linecap="round" stroke-linejoin="round" d="M17 8h2a2 2 0 012 2v6a2 2 0 01-2 2h-2v4l-4-4H9a1.994 1.994 0 01-1.414-.586m0 0L11 14h4a2 2 0 002-2V6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2v4l.586-.586z" />
          </svg>
        </.nav_link>
      </div>

      <!-- Right side: Notifications + Avatar -->
      <div class="flex-1 flex justify-end items-center gap-1.5">
        <!-- Notifications -->
        <div class="dropdown dropdown-end">
          <div tabindex="0" role="button" class="cursor-pointer relative w-9 h-9 rounded-full bg-base-200 grid place-items-center">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-4.5 w-4.5 text-base-content" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
              <path stroke-linecap="round" stroke-linejoin="round" d="M15 17h5l-1.405-1.405A2.032 2.032 0 0118 14.158V11a6.002 6.002 0 00-4-5.659V5a2 2 0 10-4 0v.341C7.67 6.165 6 8.388 6 11v3.159c0 .538-.214 1.055-.595 1.436L4 17h5m6 0v1a3 3 0 11-6 0v-1m6 0H9" />
            </svg>
            <span :if={@unread_notifications_count > 0} class="absolute -top-0.5 -right-0.5 badge badge-primary badge-xs text-primary-content text-[10px] min-w-[16px] h-4">
              {@unread_notifications_count}
            </span>
          </div>
          <div tabindex="0" class="dropdown-content bg-base-100 rounded-2xl z-[1] w-80 max-w-[calc(100vw-2rem)] shadow-xl mt-2 border border-base-200">
            <div class="p-3 border-b border-base-200 flex items-center justify-between">
              <h3 class="font-semibold">Notifications</h3>
              <button :if={@unread_notifications_count > 0} phx-click="mark_all_notifications_read" class="btn btn-xs btn-ghost text-primary">
                Tout lire
              </button>
            </div>
            <%= if @notifications == [] do %>
              <div class="p-6 text-center text-base-content/50">
                <svg xmlns="http://www.w3.org/2000/svg" class="h-10 w-10 mx-auto mb-2 opacity-50" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M20 13V6a2 2 0 00-2-2H6a2 2 0 00-2 2v7m16 0v5a2 2 0 01-2 2H6a2 2 0 01-2-2v-5m16 0h-2.586a1 1 0 00-.707.293l-2.414 2.414a1 1 0 01-.707.293h-3.172a1 1 0 01-.707-.293l-2.414-2.414A1 1 0 006.586 13H4" />
                </svg>
                <p class="text-sm">Aucune notification</p>
              </div>
            <% else %>
              <div class="max-h-80 overflow-y-auto divide-y divide-base-200">
                <%= for notification <- @notifications do %>
                  <a
                    href={if notification.type in ["date_application", "date_accepted"], do: ~p"/my-dates", else: ~p"/posts?post_id=#{notification.post_id}"}
                    phx-click="mark_notification_read"
                    phx-value-id={notification.id}
                    class={"flex items-start gap-2.5 p-3 hover:bg-base-200/50 transition-colors #{unless notification.read, do: "bg-primary/5", else: ""}"}
                  >
                    <%= if notification.actor.avatar do %>
                      <div class="w-8 h-8 rounded-full overflow-hidden flex-shrink-0">
                        <img src={"/uploads/avatars/#{notification.actor.avatar}"} alt="" class="w-full h-full object-cover" />
                      </div>
                    <% else %>
                      <div class="w-8 h-8 rounded-full bg-primary grid place-items-center flex-shrink-0">
                        <span class="text-primary-content text-xs font-bold">{String.first(notification.actor.name)}</span>
                      </div>
                    <% end %>
                    <div class="flex-1 min-w-0">
                      <p class="text-sm text-base-content/70 line-clamp-2">{notification.message}</p>
                      <p class="text-xs text-base-content/40 mt-0.5">{time_ago(notification.inserted_at)}</p>
                    </div>
                    <div :if={!notification.read} class="w-2 h-2 rounded-full bg-primary flex-shrink-0 mt-2"></div>
                  </a>
                <% end %>
              </div>
            <% end %>
          </div>
        </div>

        <!-- Avatar / Profile -->
        <div class="dropdown dropdown-end">
          <div tabindex="0" role="button" class="cursor-pointer">
            <%= if @current_user.avatar do %>
              <div class="w-9 h-9 rounded-full overflow-hidden ring-2 ring-base-200">
                <img src={"/uploads/avatars/#{@current_user.avatar}"} alt="Avatar" class="w-full h-full object-cover" />
              </div>
            <% else %>
              <div class="w-9 h-9 rounded-full bg-primary grid place-items-center">
                <span class="text-primary-content text-sm font-bold leading-none">{String.first(@current_user.name)}</span>
              </div>
            <% end %>
          </div>
          <ul tabindex="0" class="dropdown-content menu bg-base-100 rounded-2xl z-[1] w-52 p-2 shadow-xl mt-2 border border-base-200">
            <li class="px-3 py-2">
              <div class="flex flex-col gap-0 hover:bg-transparent cursor-default p-0">
                <span class="font-semibold text-sm">{@current_user.name}</span>
                <span class="text-xs text-base-content/50">{@current_user.email}</span>
              </div>
            </li>
            <div class="divider my-0"></div>
            <li>
              <.link navigate={~p"/profile"} class="text-sm flex items-center gap-2">
                <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
                </svg>
                Mon profil
              </.link>
            </li>
            <li>
              <.logout_link />
            </li>
          </ul>
        </div>
      </div>
    </nav>

    <!-- ===== BOTTOM NAV (mobile only) ===== -->
    <nav class="md:hidden fixed bottom-0 left-0 right-0 z-50 bg-base-100 border-t border-base-200 safe-area-bottom">
      <div class="flex justify-around items-center h-14">
        <.bottom_nav_item href={~p"/posts"} active={@current_path == "/posts"} label="Accueil">
          <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill={if @current_path == "/posts", do: "currentColor", else: "none"} viewBox="0 0 24 24" stroke="currentColor" stroke-width={if @current_path == "/posts", do: "0", else: "2"}>
            <path stroke-linecap="round" stroke-linejoin="round" d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6" />
          </svg>
        </.bottom_nav_item>
        <.bottom_nav_item href={~p"/my-dates"} active={@current_path == "/my-dates"} label="Dates">
          <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" viewBox="0 0 24 24" fill={if @current_path == "/my-dates", do: "currentColor", else: "none"} stroke="currentColor" stroke-width={if @current_path == "/my-dates", do: "0", else: "2"}>
            <path stroke-linecap="round" stroke-linejoin="round" d="M4.318 6.318a4.5 4.5 0 000 6.364L12 20.364l7.682-7.682a4.5 4.5 0 00-6.364-6.364L12 7.636l-1.318-1.318a4.5 4.5 0 00-6.364 0z" />
          </svg>
        </.bottom_nav_item>
        <.bottom_nav_item href={~p"/users"} active={@current_path == "/users"} label="Amis" badge={@pending_requests_count}>
          <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill={if @current_path == "/users", do: "currentColor", else: "none"} viewBox="0 0 24 24" stroke="currentColor" stroke-width={if @current_path == "/users", do: "0", else: "2"}>
            <path stroke-linecap="round" stroke-linejoin="round" d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z" />
          </svg>
        </.bottom_nav_item>
        <.bottom_nav_item href={~p"/conversations"} active={@current_path == "/conversations"} label="Chat" badge={@unread_messages_count}>
          <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill={if @current_path == "/conversations", do: "currentColor", else: "none"} viewBox="0 0 24 24" stroke="currentColor" stroke-width={if @current_path == "/conversations", do: "0", else: "2"}>
            <path stroke-linecap="round" stroke-linejoin="round" d="M17 8h2a2 2 0 012 2v6a2 2 0 01-2 2h-2v4l-4-4H9a1.994 1.994 0 01-1.414-.586m0 0L11 14h4a2 2 0 002-2V6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2v4l.586-.586z" />
          </svg>
        </.bottom_nav_item>
      </div>
    </nav>
    """
  end

  # Desktop nav link
  attr :href, :string, required: true
  attr :active, :boolean, default: false
  attr :badge, :integer, default: 0
  slot :inner_block, required: true

  defp nav_link(assigns) do
    ~H"""
    <.link
      navigate={@href}
      class={"relative px-5 py-1.5 rounded-full text-sm font-medium transition-all duration-300 #{if @active, do: "bg-pink-500 text-white shadow-sm nav-tab-active", else: "text-base-content/50 hover:text-base-content hover:bg-base-200"}"}
    >
      {render_slot(@inner_block)}
      <span :if={@badge > 0} class="absolute -top-1 -right-1 badge badge-primary badge-xs text-primary-content text-[10px] min-w-[16px] h-4">
        {@badge}
      </span>
    </.link>
    """
  end

  # Mobile bottom nav item
  attr :href, :string, required: true
  attr :active, :boolean, default: false
  attr :label, :string, required: true
  attr :badge, :integer, default: 0
  slot :inner_block, required: true

  defp bottom_nav_item(assigns) do
    ~H"""
    <.link navigate={@href} class={"flex flex-col items-center justify-center gap-0.5 relative w-16 transition-all duration-300 #{if @active, do: "text-pink-500 nav-tab-active", else: "text-base-content/40"}"}>
      <div class="relative">
        {render_slot(@inner_block)}
        <span :if={@badge > 0} class="absolute -top-1.5 -right-2.5 badge badge-primary badge-xs text-primary-content text-[10px] min-w-[14px] h-3.5">
          {@badge}
        </span>
      </div>
      <span class="text-[10px] font-medium">{@label}</span>
    </.link>
    """
  end
end
