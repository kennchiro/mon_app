defmodule MonAppWeb.Navbar do
  use Phoenix.Component
  use MonAppWeb, :verified_routes

  attr :current_user, :map, required: true
  attr :current_path, :string, default: "/"
  attr :pending_requests_count, :integer, default: 0

  def navbar(assigns) do
    ~H"""
    <nav class="navbar bg-base-100 shadow-sm sticky top-0 z-50 px-4">
      <!-- Logo -->
      <div class="flex-1">
        <a href={~p"/posts"} class="text-2xl font-bold text-primary">
          MonBlog
        </a>
      </div>

      <!-- Navigation centrale -->
      <div class="flex-none">
        <div class="flex gap-1">
          <a
            href={~p"/posts"}
            class={"btn btn-ghost px-6 #{if @current_path == "/posts", do: "border-b-2 border-primary rounded-none", else: ""}"}
          >
            <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6" />
            </svg>
          </a>
          <a
            href={~p"/users"}
            class={"btn btn-ghost px-6 relative #{if @current_path == "/users", do: "border-b-2 border-primary rounded-none", else: ""}"}
          >
            <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z" />
            </svg>
            <span :if={@pending_requests_count > 0} class="absolute -top-1 -right-1 badge badge-error badge-sm text-white">
              {@pending_requests_count}
            </span>
          </a>
          <a
            href={~p"/chat"}
            class={"btn btn-ghost px-6 #{if @current_path == "/chat", do: "border-b-2 border-primary rounded-none", else: ""}"}
          >
            <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 8h2a2 2 0 012 2v6a2 2 0 01-2 2h-2v4l-4-4H9a1.994 1.994 0 01-1.414-.586m0 0L11 14h4a2 2 0 002-2V6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2v4l.586-.586z" />
            </svg>
          </a>
        </div>
      </div>

      <!-- User Menu -->
      <div class="flex-1 flex justify-end items-center gap-2">
        <!-- Notifications -->
        <div class="dropdown dropdown-end">
          <div tabindex="0" role="button" class="cursor-pointer">
            <div class="w-10 h-10 rounded-full bg-base-300 grid place-items-center">
              <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 text-base-content" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 17h5l-1.405-1.405A2.032 2.032 0 0118 14.158V11a6.002 6.002 0 00-4-5.659V5a2 2 0 10-4 0v.341C7.67 6.165 6 8.388 6 11v3.159c0 .538-.214 1.055-.595 1.436L4 17h5m6 0v1a3 3 0 11-6 0v-1m6 0H9" />
              </svg>
            </div>
          </div>
          <div tabindex="0" class="dropdown-content bg-base-100 rounded-box z-[1] w-80 shadow-lg mt-2">
            <div class="p-4 border-b border-base-300">
              <h3 class="font-semibold text-lg">Notifications</h3>
            </div>
            <div class="p-8 text-center text-base-content/50">
              <svg xmlns="http://www.w3.org/2000/svg" class="h-12 w-12 mx-auto mb-3 opacity-50" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M20 13V6a2 2 0 00-2-2H6a2 2 0 00-2 2v7m16 0v5a2 2 0 01-2 2H6a2 2 0 01-2-2v-5m16 0h-2.586a1 1 0 00-.707.293l-2.414 2.414a1 1 0 01-.707.293h-3.172a1 1 0 01-.707-.293l-2.414-2.414A1 1 0 006.586 13H4" />
              </svg>
              <p class="text-sm">Aucune notification</p>
              <p class="text-xs mt-1">Les nouvelles notifications apparaîtront ici</p>
            </div>
          </div>
        </div>

        <!-- Avatar -->
        <div class="dropdown dropdown-end">
          <div tabindex="0" role="button" class="cursor-pointer relative">
            <div class="w-10 h-10 rounded-full bg-primary grid place-items-center">
              <span class="text-primary-content text-lg font-bold leading-none">{String.first(@current_user.name)}</span>
            </div>
            <div class="absolute -bottom-1 -right-1 w-5 h-5 rounded-full bg-base-100 border-2 border-base-100 grid place-items-center">
              <svg xmlns="http://www.w3.org/2000/svg" class="h-3 w-3 text-base-content" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="3" d="M19 9l-7 7-7-7" />
              </svg>
            </div>
          </div>
          <ul tabindex="0" class="dropdown-content menu bg-base-100 rounded-box z-[1] w-52 p-2 shadow-lg mt-2">
            <li class="menu-title px-4 py-2">
              <span class="font-semibold">{@current_user.name}</span>
              <span class="text-xs font-normal text-base-content/50">{@current_user.email}</span>
            </li>
            <div class="divider my-0"></div>
            <li>
              <a href={~p"/profile"}>
                <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
                </svg>
                Mon profil
              </a>
            </li>
            <li>
              <a href={~p"/auth/logout"} data-method="delete" class="text-error">
                <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1" />
                </svg>
                Déconnexion
              </a>
            </li>
          </ul>
        </div>
      </div>
    </nav>
    """
  end
end
