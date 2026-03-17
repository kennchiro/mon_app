defmodule MonAppWeb.ProfileLive do
  use MonAppWeb, :live_view

  alias MonApp.Blog
  alias MonApp.Blog.Post
  alias MonApp.Social
  alias MonApp.Chat
  alias MonApp.Accounts
  alias MonApp.Notifications
  alias MonAppWeb.Presence

  import MonAppWeb.Navbar
  import MonAppWeb.PostComponents
  import MonAppWeb.Toast, only: [toast_popup: 1]
  alias MonAppWeb.ToastHandler

  # ============== LIFECYCLE ==============

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_user
    user_id = user.id

    if connected?(socket) do
      {:ok, _} = Presence.track(self(), "users:online", to_string(user_id), %{
        user_id: user_id,
        name: user.name,
        online_at: System.system_time(:second)
      })

      Phoenix.PubSub.subscribe(MonApp.PubSub, "user:#{user_id}")
    end

    pending_count = length(Social.list_pending_requests(user_id))
    unread_messages_count = Chat.count_total_unread(user_id)
    friends_count = Social.count_friends(user_id)
    dates_count = Blog.count_user_dates(user_id)
    posts_count = Blog.count_user_posts(user_id)
    dates_by_category = Blog.count_user_dates_by_category(user_id)

    {date_posts, date_has_more} = Blog.list_user_date_posts_paginated(user_id, 1)
    {standard_posts, standard_has_more} = Blog.list_user_standard_posts_paginated(user_id, 1)

    {:ok,
     socket
     |> assign(:pending_requests_count, pending_count)
     |> assign(:unread_messages_count, unread_messages_count)
     |> assign(:friends_count, friends_count)
     |> assign(:dates_count, dates_count)
     |> assign(:posts_count, posts_count)
     |> assign(:dates_by_category, dates_by_category)
     |> assign(:profile_tab, "dates")
     |> assign(:date_posts, date_posts)
     |> assign(:date_page, 1)
     |> assign(:date_has_more, date_has_more)
     |> assign(:standard_posts, standard_posts)
     |> assign(:standard_page, 1)
     |> assign(:standard_has_more, standard_has_more)
     |> assign(:show_edit_modal, false)
     |> assign(:profile_form, to_form(Accounts.change_profile(user)))
     |> assign(:show_delete_confirm, false)
     |> assign(:nationality_search, "")
     |> assign(:nationality_open, false)
     |> assign(:theme, get_connect_params(socket)["theme"] || "light")
     |> allow_upload(:avatar,
       accept: ~w(.jpg .jpeg .png .gif .webp),
       max_entries: 1,
       max_file_size: 5_000_000,
       auto_upload: true
     )
     |> ToastHandler.init_toast()}
  end

  # ============== RENDER ==============

  @impl true
  def render(assigns) do
    has_upload = length(assigns.uploads.avatar.entries) > 0
    upload_ready = has_upload && Enum.all?(assigns.uploads.avatar.entries, & &1.done?)
    upload_in_progress = has_upload && Enum.any?(assigns.uploads.avatar.entries, fn e -> e.progress > 0 && e.progress < 100 end)

    assigns =
      assigns
      |> assign(:has_upload, has_upload)
      |> assign(:upload_ready, upload_ready)
      |> assign(:upload_in_progress, upload_in_progress)

    ~H"""
    <div class="min-h-screen bg-base-200 overflow-x-hidden">
      <.navbar current_user={@current_user} current_path="/profile" pending_requests_count={@pending_requests_count} unread_messages_count={@unread_messages_count} notifications={@notifications} unread_notifications_count={@unread_notifications_count} />
      <.toast_popup toast={@toast} />

      <main class="max-w-2xl mx-auto p-4 sm:p-6 pb-20 md:pb-6">
        <!-- Profile Header Card -->
        <div class="bg-base-100 rounded-2xl shadow-sm overflow-hidden mb-4">
          <div class="p-5 sm:p-6">
            <div class="flex flex-col sm:flex-row items-center gap-5">
              <!-- Avatar -->
              <div class="flex flex-col items-center gap-3">
                <div class="relative group">
                  <%= if @has_upload do %>
                    <%= for entry <- @uploads.avatar.entries do %>
                      <div class="relative">
                        <div class="w-24 h-24 sm:w-28 sm:h-28 rounded-full overflow-hidden ring-4 ring-pink-500/20">
                          <.live_img_preview entry={entry} class="w-full h-full object-cover" />
                        </div>
                        <div :if={entry.progress > 0 && entry.progress < 100} class="absolute inset-0 rounded-full bg-black/50 flex items-center justify-center">
                          <span class="text-white text-sm font-bold">{entry.progress}%</span>
                        </div>
                        <div :if={entry.done?} class="absolute inset-0 rounded-full bg-success/20 flex items-center justify-center">
                          <svg xmlns="http://www.w3.org/2000/svg" class="h-8 w-8 text-success" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                            <path stroke-linecap="round" stroke-linejoin="round" d="M5 13l4 4L19 7" />
                          </svg>
                        </div>
                      </div>
                      <p :for={err <- upload_errors(@uploads.avatar, entry)} class="text-error text-xs mt-1">{error_to_string(err)}</p>
                    <% end %>
                  <% else %>
                    <div class="w-24 h-24 sm:w-28 sm:h-28 rounded-full overflow-hidden bg-primary grid place-items-center ring-4 ring-base-200">
                      <%= if @current_user.avatar do %>
                        <img src={"/uploads/avatars/#{@current_user.avatar}"} alt="Avatar" class="w-full h-full object-cover" />
                      <% else %>
                        <span class="text-primary-content text-3xl sm:text-4xl font-bold leading-none">{String.first(@current_user.name)}</span>
                      <% end %>
                    </div>
                    <!-- Camera badge -->
                    <label
                      for={@uploads.avatar.ref}
                      class="absolute bottom-0 right-0 w-9 h-9 rounded-full bg-pink-500 text-white grid place-items-center cursor-pointer hover:bg-pink-600 transition-colors border-3 border-base-100"
                    >
                      <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2.5">
                        <path stroke-linecap="round" stroke-linejoin="round" d="M3 9a2 2 0 012-2h.93a2 2 0 001.664-.89l.812-1.22A2 2 0 0110.07 4h3.86a2 2 0 011.664.89l.812 1.22A2 2 0 0018.07 7H19a2 2 0 012 2v9a2 2 0 01-2 2H5a2 2 0 01-2-2V9z" />
                        <path stroke-linecap="round" stroke-linejoin="round" d="M15 13a3 3 0 11-6 0 3 3 0 016 0z" />
                      </svg>
                    </label>
                  <% end %>
                </div>

                <form phx-change="validate_avatar" phx-submit="save_avatar" class="hidden">
                  <.live_file_input upload={@uploads.avatar} class="hidden" />
                </form>

                <div :if={@has_upload} class="flex gap-2">
                  <button type="button" phx-click="save_avatar" disabled={!@upload_ready} class={"btn btn-sm bg-base-content text-base-100 hover:bg-pink-500 hover:text-white border-none " <> if @upload_ready, do: "", else: "btn-disabled"}>
                    Enregistrer
                  </button>
                  <button type="button" phx-click="cancel_avatar" class="btn btn-ghost btn-sm">Annuler</button>
                </div>
              </div>

              <!-- User Info -->
              <div class="text-center sm:text-left flex-1 min-w-0">
                <div class="flex items-center justify-center sm:justify-start gap-2">
                  <h1 class="text-xl sm:text-2xl font-bold truncate">@{@current_user.name}</h1>
                  <button
                    phx-click="open_edit_modal"
                    class="w-7 h-7 rounded-full bg-base-200 grid place-items-center hover:bg-pink-500 hover:text-white transition-all shrink-0"
                    title="Modifier le profil"
                  >
                    <svg xmlns="http://www.w3.org/2000/svg" class="h-3.5 w-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                      <path stroke-linecap="round" stroke-linejoin="round" d="M15.232 5.232l3.536 3.536m-2.036-5.036a2.5 2.5 0 113.536 3.536L6.5 21.036H3v-3.572L16.732 3.732z" />
                    </svg>
                  </button>
                </div>
                <p class="text-base-content/50 text-sm truncate">{@current_user.email}</p>

                <!-- Bio -->
                <p :if={@current_user.bio && @current_user.bio != ""} class="text-sm text-base-content/70 mt-2 line-clamp-3">
                  {@current_user.bio}
                </p>

                <!-- Profile details pills -->
                <div class="flex flex-wrap justify-center sm:justify-start gap-1.5 mt-2">
                  <span :if={@current_user.gender} class="inline-flex items-center gap-1 px-2.5 py-1 bg-base-200/60 rounded-full text-xs text-base-content/60">
                    {MonApp.Accounts.User.gender_label(@current_user.gender)}
                  </span>
                  <span :if={@current_user.location && @current_user.location != ""} class="inline-flex items-center gap-1 px-2.5 py-1 bg-base-200/60 rounded-full text-xs text-base-content/60">
                    <svg xmlns="http://www.w3.org/2000/svg" class="h-3 w-3" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                      <path stroke-linecap="round" stroke-linejoin="round" d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z" />
                      <path stroke-linecap="round" stroke-linejoin="round" d="M15 11a3 3 0 11-6 0 3 3 0 016 0z" />
                    </svg>
                    {@current_user.location}
                  </span>
                  <span :if={@current_user.looking_for && @current_user.looking_for != "any"} class="inline-flex items-center gap-1 px-2.5 py-1 bg-pink-500/10 rounded-full text-xs text-pink-500">
                    <svg xmlns="http://www.w3.org/2000/svg" class="h-3 w-3" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                      <path stroke-linecap="round" stroke-linejoin="round" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
                    </svg>
                    {MonApp.Accounts.User.looking_for_label(@current_user.looking_for)}
                  </span>
                  <span :if={@current_user.nationality} class="inline-flex items-center gap-1 px-2.5 py-1 bg-base-200/60 rounded-full text-xs text-base-content/60">
                    {MonApp.Accounts.User.nationality_flag(@current_user.nationality)} {MonApp.Accounts.User.nationality_label(@current_user.nationality)}
                  </span>
                  <span :if={@current_user.birthdate} class="inline-flex items-center gap-1 px-2.5 py-1 bg-base-200/60 rounded-full text-xs text-base-content/60">
                    {trunc(Date.diff(Date.utc_today(), @current_user.birthdate) / 365)} ans
                  </span>
                </div>

                <p class="text-xs text-base-content/40 mt-2">
                  Membre depuis {Calendar.strftime(@current_user.inserted_at, "%B %Y")}
                </p>

                <!-- Stats -->
                <div class="flex justify-center sm:justify-start gap-5 mt-3">
                  <div class="text-center">
                    <div class="text-lg font-bold text-base-content">{@friends_count}</div>
                    <div class="text-xs text-base-content/50">Amis</div>
                  </div>
                  <div class="text-center">
                    <div class="text-lg font-bold text-pink-500">{@dates_count}</div>
                    <div class="text-xs text-base-content/50">Dates</div>
                  </div>
                  <div class="text-center">
                    <div class="text-lg font-bold text-base-content">{@posts_count}</div>
                    <div class="text-xs text-base-content/50">Posts</div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- Date Categories Stats -->
        <div :if={@dates_by_category != %{}} class="bg-base-100 rounded-2xl shadow-sm p-4 sm:p-5 mb-4">
          <h3 class="text-sm font-semibold text-base-content/70 mb-3">Dates par catégorie</h3>
          <div class="flex flex-wrap gap-2">
            <%= for {cat, count} <- Enum.sort_by(@dates_by_category, fn {_, c} -> -c end) do %>
              <div class="flex items-center gap-1.5 px-3 py-1.5 bg-base-200/60 rounded-full text-sm">
                <span>{Post.date_category_emoji(cat)}</span>
                <span class="text-base-content/70">{Post.date_category_label(cat)}</span>
                <span class="font-bold text-pink-500">{count}</span>
              </div>
            <% end %>
          </div>
        </div>

        <!-- Tabs: Dates / Publications -->
        <div class="flex gap-1 bg-base-100 rounded-xl p-1 mb-4 shadow-sm">
          <button
            phx-click="switch_profile_tab"
            phx-value-tab="dates"
            class={"flex-1 py-2 px-3 rounded-lg text-sm font-medium transition-all #{if @profile_tab == "dates", do: "bg-pink-500 text-white shadow-sm", else: "text-base-content/50 hover:text-base-content"}"}
          >
            Dates ({@dates_count})
          </button>
          <button
            phx-click="switch_profile_tab"
            phx-value-tab="posts"
            class={"flex-1 py-2 px-3 rounded-lg text-sm font-medium transition-all #{if @profile_tab == "posts", do: "bg-pink-500 text-white shadow-sm", else: "text-base-content/50 hover:text-base-content"}"}
          >
            Publications ({@posts_count})
          </button>
        </div>

        <!-- Date Posts Tab -->
        <div :if={@profile_tab == "dates"} class="space-y-4">
          <div :if={@date_posts == []} class="bg-base-100 rounded-2xl shadow-sm p-8 text-center">
            <div class="w-14 h-14 mx-auto bg-pink-500/10 rounded-full flex items-center justify-center mb-3">
              <svg xmlns="http://www.w3.org/2000/svg" class="h-7 w-7 text-pink-400" viewBox="0 0 24 24" fill="currentColor">
                <path d="M12 21.35l-1.45-1.32C5.4 15.36 2 12.28 2 8.5 2 5.42 4.42 3 7.5 3c1.74 0 3.41.81 4.5 2.09C13.09 3.81 14.76 3 16.5 3 19.58 3 22 5.42 22 8.5c0 3.78-3.4 6.86-8.55 11.54L12 21.35z" />
              </svg>
            </div>
            <p class="text-base-content/50 font-medium">Aucun date publié</p>
          </div>

          <.date_post_card :for={post <- @date_posts} post={post} current_user={@current_user} />

          <button
            :if={@date_has_more}
            phx-click="load_more_dates"
            class="btn btn-ghost w-full border border-base-300 rounded-xl text-sm"
          >
            Voir plus de dates
          </button>
        </div>

        <!-- Standard Posts Tab -->
        <div :if={@profile_tab == "posts"} class="space-y-4">
          <div :if={@standard_posts == []} class="bg-base-100 rounded-2xl shadow-sm p-8 text-center">
            <div class="w-14 h-14 mx-auto bg-base-200 rounded-full flex items-center justify-center mb-3">
              <svg xmlns="http://www.w3.org/2000/svg" class="h-7 w-7 text-base-content/30" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.5">
                <path stroke-linecap="round" stroke-linejoin="round" d="M19 20H5a2 2 0 01-2-2V6a2 2 0 012-2h10a2 2 0 012 2v1m2 13a2 2 0 01-2-2V7m2 13a2 2 0 002-2V9a2 2 0 00-2-2h-2m-4-3H9M7 16h6M7 8h6v4H7V8z" />
              </svg>
            </div>
            <p class="text-base-content/50 font-medium">Aucune publication</p>
          </div>

          <.post_item :for={post <- @standard_posts} post={post} current_user={@current_user} />

          <button
            :if={@standard_has_more}
            phx-click="load_more_posts"
            class="btn btn-ghost w-full border border-base-300 rounded-xl text-sm"
          >
            Voir plus de publications
          </button>
        </div>

        <!-- Deletion scheduled banner -->
        <div :if={Accounts.deletion_scheduled?(@current_user)} class="bg-error/10 border border-error/20 rounded-2xl p-4 mt-4">
          <div class="flex items-start gap-3">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 text-error shrink-0 mt-0.5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
              <path stroke-linecap="round" stroke-linejoin="round" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
            </svg>
            <div class="flex-1">
              <p class="text-sm font-semibold text-error">Suppression programmée</p>
              <p class="text-xs text-error/70 mt-0.5">
                Votre compte sera supprimé dans {Accounts.days_until_deletion(@current_user)} jours.
                Vous pouvez annuler à tout moment.
              </p>
              <button phx-click="cancel_deletion" class="btn btn-sm btn-outline btn-error mt-2">
                Annuler la suppression
              </button>
            </div>
          </div>
        </div>
      </main>

      <!-- Edit Profile Modal -->
      <div :if={@show_edit_modal} class="fixed inset-0 bg-black/50 z-50 flex items-end md:items-center justify-center md:p-4">
        <div class="bg-base-100 w-full md:rounded-2xl md:shadow-2xl md:max-w-lg h-full md:h-auto md:max-h-[90vh] flex flex-col overflow-hidden">
          <div class="safe-area-top md:rounded-t-2xl">
            <div class="h-14 px-4 border-b border-base-200 flex items-center relative">
              <button type="button" phx-click="close_edit_modal" class="w-8 h-8 rounded-full bg-base-200 flex items-center justify-center hover:bg-base-300 transition-colors z-10">
                <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12" />
                </svg>
              </button>
              <h3 class="text-lg font-bold text-base-content absolute inset-0 flex items-center justify-center pointer-events-none">
                Modifier le profil
              </h3>
            </div>
          </div>

          <.form for={@profile_form} phx-submit="save_profile" phx-change="validate_profile" class="flex flex-col flex-1 overflow-hidden">
            <div class="p-4 sm:p-5 flex-1 overflow-y-auto overflow-x-hidden space-y-4">
              <!-- Pseudo (non modifiable) -->
              <div>
                <label class="text-sm font-medium text-base-content/70 mb-1.5 block">Pseudo</label>
                <div class="relative">
                  <span class="text-base-content/30 absolute left-3.5 top-1/2 -translate-y-1/2 text-lg font-medium">@</span>
                  <input
                    type="text"
                    value={@current_user.name}
                    class="w-full pl-10 pr-4 py-3 bg-base-200/30 border border-base-300/50 rounded-xl text-sm text-base-content/50 cursor-not-allowed"
                    disabled
                  />
                </div>
                <p class="text-xs text-base-content/40 mt-1">Le pseudo ne peut pas être modifié</p>
              </div>

              <!-- Bio -->
              <div>
                <label class="text-sm font-medium text-base-content/70 mb-1.5 block">Bio</label>
                <textarea
                  name="profile[bio]"
                  class="w-full px-4 py-3 bg-base-200/50 border border-base-300 rounded-xl text-sm focus:outline-none focus:border-pink-400 transition-all resize-none min-h-[80px]"
                  placeholder="Dis quelque chose sur toi..."
                  maxlength="500"
                >{@profile_form[:bio].value}</textarea>
                <div class="text-xs text-base-content/40 text-right mt-0.5">
                  {String.length(@profile_form[:bio].value || "")}/500
                </div>
              </div>

              <!-- Gender -->
              <div>
                <label class="text-sm font-medium text-base-content/70 mb-1.5 block">Genre</label>
                <select name="profile[gender]" class="w-full px-4 py-3 bg-base-200/50 border border-base-300 rounded-xl text-sm focus:outline-none focus:border-pink-400 transition-all appearance-none">
                  <option value="">Non précisé</option>
                  <option :for={g <- MonApp.Accounts.User.genders()} value={g} selected={@profile_form[:gender].value == g}>
                    {MonApp.Accounts.User.gender_label(g)}
                  </option>
                </select>
              </div>

              <!-- Birthdate -->
              <div>
                <label class="text-sm font-medium text-base-content/70 mb-1.5 block">Date de naissance</label>
                <input
                  type="date"
                  name="profile[birthdate]"
                  value={@profile_form[:birthdate].value}
                  class="w-full px-4 py-3 bg-base-200/50 border border-base-300 rounded-xl text-sm focus:outline-none focus:border-pink-400 transition-all"
                />
              </div>

              <!-- Looking for -->
              <div>
                <label class="text-sm font-medium text-base-content/70 mb-1.5 block">Je cherche</label>
                <select name="profile[looking_for]" class="w-full px-4 py-3 bg-base-200/50 border border-base-300 rounded-xl text-sm focus:outline-none focus:border-pink-400 transition-all appearance-none">
                  <option :for={l <- MonApp.Accounts.User.looking_for_options()} value={l} selected={@profile_form[:looking_for].value == l}>
                    {MonApp.Accounts.User.looking_for_label(l)}
                  </option>
                </select>
              </div>

              <!-- Location & Nationality -->
              <div class="grid grid-cols-1 sm:grid-cols-2 gap-3">
                <div>
                  <label class="text-sm font-medium text-base-content/70 mb-1.5 block">Localisation</label>
                  <input
                    type="text"
                    name="profile[location]"
                    value={@profile_form[:location].value}
                    class="w-full px-4 py-3 bg-base-200/50 border border-base-300 rounded-xl text-sm focus:outline-none focus:border-pink-400 transition-all"
                    placeholder="Paris, France"
                  />
                </div>
                <div>
                  <label class="text-sm font-medium text-base-content/70 mb-1.5 block">Nationalité</label>
                  <input type="hidden" name="profile[nationality]" value={@profile_form[:nationality].value || ""} />
                  <div class="relative">
                    <!-- Display current or search -->
                    <input
                      type="text"
                      value={if @nationality_open, do: @nationality_search, else: nationality_display(@profile_form[:nationality].value)}
                      phx-focus="open_nationality"
                      phx-keyup="search_nationality"
                      phx-debounce="150"
                      placeholder="Rechercher..."
                      autocomplete="off"
                      class="w-full px-4 py-3 bg-base-200/50 border border-base-300 rounded-xl text-sm focus:outline-none focus:border-pink-400 transition-all"
                    />
                    <!-- Clear button -->
                    <button
                      :if={@profile_form[:nationality].value && @profile_form[:nationality].value != "" && !@nationality_open}
                      type="button"
                      phx-click="clear_nationality"
                      class="absolute right-3 top-1/2 -translate-y-1/2 text-base-content/30 hover:text-base-content/60"
                    >
                      <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                        <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12" />
                      </svg>
                    </button>
                    <!-- Dropdown -->
                    <div :if={@nationality_open} class="absolute z-50 mt-1 w-full bg-base-100 border border-base-200 rounded-xl shadow-xl max-h-48 overflow-y-auto">
                      <%
                        search = String.downcase(@nationality_search)
                        filtered = if search == "" do
                          MonApp.Accounts.User.nationalities()
                        else
                          Enum.filter(MonApp.Accounts.User.nationalities(), fn {_code, _flag, label} ->
                            String.downcase(label) |> String.contains?(search)
                          end)
                        end
                      %>
                      <div :if={filtered == []} class="px-4 py-3 text-sm text-base-content/40 text-center">
                        Aucun résultat
                      </div>
                      <button
                        :for={{code, flag, label} <- filtered}
                        type="button"
                        phx-click="select_nationality"
                        phx-value-code={code}
                        class={"w-full text-left px-4 py-2.5 text-sm hover:bg-base-200/50 transition-colors flex items-center gap-2 #{if @profile_form[:nationality].value == code, do: "bg-pink-500/5 text-pink-500 font-medium", else: "text-base-content/70"}"}
                      >
                        <span class="text-base">{flag}</span>
                        <span>{label}</span>
                      </button>
                    </div>
                  </div>
                </div>
              </div>

              <!-- Privacy Settings -->
              <div class="pt-4 mt-2 border-t border-base-200">
                <h4 class="text-sm font-semibold text-base-content/70 mb-3">Visibilité du profil</h4>

                <div class="space-y-3">
                  <label class="flex items-center justify-between cursor-pointer">
                    <div class="flex items-center gap-2.5">
                      <div class="w-8 h-8 rounded-full bg-pink-500/10 grid place-items-center shrink-0">
                        <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 text-pink-500" viewBox="0 0 24 24" fill="currentColor">
                          <path d="M12 21.35l-1.45-1.32C5.4 15.36 2 12.28 2 8.5 2 5.42 4.42 3 7.5 3c1.74 0 3.41.81 4.5 2.09C13.09 3.81 14.76 3 16.5 3 19.58 3 22 5.42 22 8.5c0 3.78-3.4 6.86-8.55 11.54L12 21.35z" />
                        </svg>
                      </div>
                      <div>
                        <div class="text-sm font-medium">Afficher mes dates</div>
                        <div class="text-xs text-base-content/40">Visible par les autres sur votre profil</div>
                      </div>
                    </div>
                    <input type="hidden" name="profile[show_dates_on_profile]" value="false" />
                    <input
                      type="checkbox"
                      name="profile[show_dates_on_profile]"
                      value="true"
                      checked={@profile_form[:show_dates_on_profile].value in [true, "true"]}
                      class="toggle toggle-sm toggle-primary"
                    />
                  </label>

                  <label class="flex items-center justify-between cursor-pointer">
                    <div class="flex items-center gap-2.5">
                      <div class="w-8 h-8 rounded-full bg-blue-500/10 grid place-items-center shrink-0">
                        <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 text-blue-500" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                          <path stroke-linecap="round" stroke-linejoin="round" d="M19 20H5a2 2 0 01-2-2V6a2 2 0 012-2h10a2 2 0 012 2v1m2 13a2 2 0 01-2-2V7m2 13a2 2 0 002-2V9a2 2 0 00-2-2h-2m-4-3H9M7 16h6M7 8h6v4H7V8z" />
                        </svg>
                      </div>
                      <div>
                        <div class="text-sm font-medium">Afficher mes publications</div>
                        <div class="text-xs text-base-content/40">Visible par les autres sur votre profil</div>
                      </div>
                    </div>
                    <input type="hidden" name="profile[show_posts_on_profile]" value="false" />
                    <input
                      type="checkbox"
                      name="profile[show_posts_on_profile]"
                      value="true"
                      checked={@profile_form[:show_posts_on_profile].value in [true, "true"]}
                      class="toggle toggle-sm toggle-primary"
                    />
                  </label>
                </div>
              </div>

              <!-- Account Deletion -->
              <div class="pt-4 mt-2 border-t border-base-200">
                <button
                  type="button"
                  phx-click="show_delete_confirm"
                  class="w-full flex items-center justify-between py-3 text-left group"
                >
                  <div class="flex items-center gap-2.5">
                    <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 text-base-content/30 group-hover:text-error transition-colors" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                      <path stroke-linecap="round" stroke-linejoin="round" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
                    </svg>
                    <span class="text-sm text-base-content/40 group-hover:text-error transition-colors">Supprimer le compte</span>
                  </div>
                  <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 text-base-content/20" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M9 5l7 7-7 7" />
                  </svg>
                </button>
              </div>
            </div>

            <div class="p-4 border-t border-base-200 safe-area-bottom">
              <button type="submit" class="btn w-full border-0 bg-base-content text-base-100 hover:bg-pink-500 hover:text-white rounded-xl transition-all duration-300">
                Enregistrer
              </button>
            </div>
          </.form>
        </div>
      </div>

      <!-- Delete Account Confirm Modal -->
      <div :if={@show_delete_confirm} class="fixed inset-0 bg-black/50 z-[110] flex items-center justify-center px-4">
        <div class="bg-base-100 rounded-2xl shadow-2xl max-w-sm w-full overflow-hidden" phx-click-away="cancel_delete">
          <div class="p-6">
            <h3 class="text-lg font-bold text-base-content">Supprimer votre compte ?</h3>
            <div class="mt-4 space-y-3">
              <div class="flex items-start gap-2.5">
                <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 text-base-content/40 shrink-0 mt-0.5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
                </svg>
                <p class="text-sm text-base-content/60">Votre compte sera désactivé immédiatement et supprimé après <strong class="text-base-content">30 jours</strong>.</p>
              </div>
              <div class="flex items-start gap-2.5">
                <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 text-base-content/40 shrink-0 mt-0.5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
                </svg>
                <p class="text-sm text-base-content/60">Toutes vos données seront perdues : profil, dates, messages, amis.</p>
              </div>
              <div class="flex items-start gap-2.5">
                <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 text-base-content/40 shrink-0 mt-0.5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
                </svg>
                <p class="text-sm text-base-content/60">Vous pouvez annuler en vous reconnectant dans les 30 jours.</p>
              </div>
            </div>
          </div>
          <div class="flex border-t border-base-200">
            <button phx-click="cancel_delete" class="flex-1 py-3.5 text-sm font-medium text-base-content/60 hover:bg-base-200/50 transition-colors border-r border-base-200">
              Annuler
            </button>
            <button phx-click="confirm_delete" class="flex-1 py-3.5 text-sm font-semibold text-error hover:bg-error/5 transition-colors">
              Supprimer le compte
            </button>
          </div>
        </div>
      </div>
    </div>
    """
  end

  # ============== EVENTS ==============

  @impl true
  def handle_event("switch_profile_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, :profile_tab, tab)}
  end

  # --- Edit Profile ---

  @impl true
  def handle_event("open_edit_modal", _, socket) do
    form = Accounts.change_profile(socket.assigns.current_user) |> to_form()
    {:noreply, socket |> assign(:show_edit_modal, true) |> assign(:profile_form, form)}
  end

  @impl true
  def handle_event("close_edit_modal", _, socket) do
    {:noreply, assign(socket, :show_edit_modal, false)}
  end

  @impl true
  def handle_event("validate_profile", %{"profile" => params}, socket) do
    changeset =
      socket.assigns.current_user
      |> Accounts.change_profile(params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :profile_form, to_form(changeset))}
  end

  @impl true
  def handle_event("save_profile", %{"profile" => params}, socket) do
    case Accounts.update_profile(socket.assigns.current_user, params) do
      {:ok, updated_user} ->
        {:noreply,
         socket
         |> assign(:current_user, updated_user)
         |> assign(:show_edit_modal, false)
         |> put_flash(:info, "Profil mis à jour")}

      {:error, changeset} ->
        {:noreply, assign(socket, :profile_form, to_form(changeset))}
    end
  end

  # --- Theme ---

  @impl true
  def handle_event("toggle_theme", _, socket) do
    new_theme = if socket.assigns.theme == "dark", do: "light", else: "dark"
    {:noreply,
     socket
     |> assign(:theme, new_theme)
     |> push_event("set-theme", %{theme: new_theme})}
  end

  # --- Nationality Picker ---

  @impl true
  def handle_event("open_nationality", _, socket) do
    {:noreply, socket |> assign(:nationality_open, true) |> assign(:nationality_search, "")}
  end

  @impl true
  def handle_event("search_nationality", %{"value" => value}, socket) do
    {:noreply, assign(socket, :nationality_search, String.trim(value))}
  end

  @impl true
  def handle_event("select_nationality", %{"code" => code}, socket) do
    form = socket.assigns.profile_form
    changeset = Accounts.change_profile(socket.assigns.current_user, %{
      "nationality" => code,
      "bio" => form[:bio].value,
      "gender" => form[:gender].value,
      "birthdate" => form[:birthdate].value,
      "looking_for" => form[:looking_for].value,
      "location" => form[:location].value
    })

    {:noreply,
     socket
     |> assign(:profile_form, to_form(changeset))
     |> assign(:nationality_open, false)
     |> assign(:nationality_search, "")}
  end

  @impl true
  def handle_event("clear_nationality", _, socket) do
    form = socket.assigns.profile_form
    changeset = Accounts.change_profile(socket.assigns.current_user, %{
      "nationality" => nil,
      "bio" => form[:bio].value,
      "gender" => form[:gender].value,
      "birthdate" => form[:birthdate].value,
      "looking_for" => form[:looking_for].value,
      "location" => form[:location].value
    })

    {:noreply, assign(socket, :profile_form, to_form(changeset))}
  end

  # --- Account Deletion ---

  @impl true
  def handle_event("show_delete_confirm", _, socket) do
    {:noreply, assign(socket, :show_delete_confirm, true)}
  end

  @impl true
  def handle_event("cancel_delete", _, socket) do
    {:noreply, assign(socket, :show_delete_confirm, false)}
  end

  @impl true
  def handle_event("confirm_delete", _, socket) do
    case Accounts.schedule_deletion(socket.assigns.current_user) do
      {:ok, updated_user} ->
        {:noreply,
         socket
         |> assign(:current_user, updated_user)
         |> assign(:show_delete_confirm, false)
         |> put_flash(:info, "Suppression programmée dans 30 jours. Vous pouvez annuler à tout moment.")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Erreur")}
    end
  end

  @impl true
  def handle_event("cancel_deletion", _, socket) do
    case Accounts.cancel_deletion(socket.assigns.current_user) do
      {:ok, updated_user} ->
        {:noreply,
         socket
         |> assign(:current_user, updated_user)
         |> put_flash(:info, "Suppression annulée. Votre compte est restauré.")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Erreur")}
    end
  end

  @impl true
  def handle_event("load_more_dates", _, socket) do
    user_id = socket.assigns.current_user.id
    next_page = socket.assigns.date_page + 1
    {new_posts, has_more} = Blog.list_user_date_posts_paginated(user_id, next_page)

    {:noreply,
     socket
     |> assign(:date_posts, socket.assigns.date_posts ++ new_posts)
     |> assign(:date_page, next_page)
     |> assign(:date_has_more, has_more)}
  end

  @impl true
  def handle_event("load_more_posts", _, socket) do
    user_id = socket.assigns.current_user.id
    next_page = socket.assigns.standard_page + 1
    {new_posts, has_more} = Blog.list_user_standard_posts_paginated(user_id, next_page)

    {:noreply,
     socket
     |> assign(:standard_posts, socket.assigns.standard_posts ++ new_posts)
     |> assign(:standard_page, next_page)
     |> assign(:standard_has_more, has_more)}
  end

  # --- Avatar ---

  @impl true
  def handle_event("validate_avatar", _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("save_avatar", _params, socket) do
    user = socket.assigns.current_user
    entries = socket.assigns.uploads.avatar.entries

    if Enum.empty?(entries) || !Enum.all?(entries, & &1.done?) do
      {:noreply, put_flash(socket, :error, "Veuillez attendre la fin de l'upload")}
    else
      uploaded_files =
        consume_uploaded_entries(socket, :avatar, fn %{path: path}, entry ->
          ext = Path.extname(entry.client_name)
          filename = "avatar_#{user.id}_#{System.unique_integer([:positive])}#{ext}"
          dest = Path.join(Accounts.avatars_dir(), filename)
          File.mkdir_p!(Path.dirname(dest))
          File.cp!(path, dest)
          {:ok, filename}
        end)

      case uploaded_files do
        [filename] ->
          case Accounts.update_avatar(user, filename) do
            {:ok, updated_user} ->
              {:noreply,
               socket
               |> assign(:current_user, updated_user)
               |> put_flash(:info, "Photo de profil mise à jour")}

            {:error, _} ->
              {:noreply, put_flash(socket, :error, "Erreur lors de la mise à jour")}
          end

        [] ->
          {:noreply, put_flash(socket, :error, "Aucun fichier à enregistrer")}
      end
    end
  end

  @impl true
  def handle_event("cancel_avatar", _params, socket) do
    socket =
      Enum.reduce(socket.assigns.uploads.avatar.entries, socket, fn entry, acc ->
        cancel_upload(acc, :avatar, entry.ref)
      end)

    {:noreply, socket}
  end

  @impl true
  def handle_event("delete_avatar", _params, socket) do
    user = socket.assigns.current_user

    case Accounts.delete_avatar(user) do
      {:ok, updated_user} ->
        {:noreply,
         socket
         |> assign(:current_user, updated_user)
         |> put_flash(:info, "Photo de profil supprimée")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Erreur lors de la suppression")}
    end
  end

  # ============== TOAST EVENTS ==============

  @impl true
  def handle_event("dismiss_toast", _, socket) do
    Process.send_after(self(), :clear_toast, 300)
    {:noreply, ToastHandler.dismiss_toast(socket)}
  end

  # ============== NOTIFICATION EVENTS ==============

  @impl true
  def handle_event("mark_notification_read", %{"id" => id}, socket) do
    user_id = socket.assigns.current_user.id
    notification_id = String.to_integer(id)
    Notifications.mark_as_read(notification_id, user_id)

    notifications =
      Enum.map(socket.assigns.notifications, fn n ->
        if n.id == notification_id, do: %{n | read: true}, else: n
      end)

    unread_count = Enum.count(notifications, fn n -> !n.read end)

    {:noreply,
     socket
     |> assign(:notifications, notifications)
     |> assign(:unread_notifications_count, unread_count)}
  end

  @impl true
  def handle_event("mark_all_notifications_read", _, socket) do
    user_id = socket.assigns.current_user.id
    Notifications.mark_all_as_read(user_id)

    notifications = Enum.map(socket.assigns.notifications, fn n -> %{n | read: true} end)

    {:noreply,
     socket
     |> assign(:notifications, notifications)
     |> assign(:unread_notifications_count, 0)}
  end

  # ============== PUBSUB HANDLERS ==============

  @impl true
  def handle_info({:new_message, message}, socket) do
    user_id = socket.assigns.current_user.id
    unread_count = Chat.count_total_unread(user_id)

    # Toast for new message (not from self)
    socket =
      if message.sender_id != user_id do
        sender = MonApp.Accounts.get_user(message.sender_id)
        if sender do
          ToastHandler.show_message_toast(socket, message, sender.name, sender.avatar)
        else
          socket
        end
      else
        socket
      end

    {:noreply, assign(socket, :unread_messages_count, unread_count)}
  end

  @impl true
  def handle_info({:new_notification, notification}, socket) do
    notifications = [notification | socket.assigns.notifications]
    unread_count = socket.assigns.unread_notifications_count + 1

    {:noreply,
     socket
     |> assign(:notifications, notifications)
     |> assign(:unread_notifications_count, unread_count)
     |> ToastHandler.show_notification_toast(notification)}
  end

  @impl true
  def handle_info(:auto_dismiss_toast, socket) do
    {:noreply, ToastHandler.dismiss_toast(socket)}
  end

  @impl true
  def handle_info(:clear_toast, socket) do
    {:noreply, ToastHandler.clear_toast(socket)}
  end

  @impl true
  def handle_info(_msg, socket) do
    {:noreply, socket}
  end

  # ============== HELPERS ==============

  defp nationality_display(nil), do: ""
  defp nationality_display(""), do: ""
  defp nationality_display(code) do
    flag = MonApp.Accounts.User.nationality_flag(code)
    label = MonApp.Accounts.User.nationality_label(code)
    if label, do: "#{flag} #{label}", else: ""
  end

  defp error_to_string(:too_large), do: "Fichier trop volumineux (max 5 Mo)"
  defp error_to_string(:not_accepted), do: "Type de fichier non accepté"
  defp error_to_string(:too_many_files), do: "Une seule image autorisée"
  defp error_to_string(_), do: "Erreur de téléchargement"
end
