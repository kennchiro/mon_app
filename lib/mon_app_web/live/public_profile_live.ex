defmodule MonAppWeb.PublicProfileLive do
  use MonAppWeb, :live_view

  alias MonApp.Accounts
  alias MonApp.Blog
  alias MonApp.Blog.Post
  alias MonApp.Blog.Comment
  alias MonApp.Social
  alias MonApp.Chat
  alias MonApp.Notifications
  alias MonApp.Repo
  alias MonAppWeb.Presence

  import MonAppWeb.Navbar
  import MonAppWeb.PostComponents
  import MonAppWeb.Toast, only: [toast_popup: 1]
  alias MonAppWeb.ToastHandler

  # ============== LIFECYCLE ==============

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    current_user = socket.assigns.current_user
    profile_user_id = String.to_integer(id)

    # Si c'est son propre profil, rediriger vers /profile
    if profile_user_id == current_user.id do
      {:ok, push_navigate(socket, to: ~p"/profile")}
    else
      case Accounts.get_user(profile_user_id) do
        nil ->
          {:ok,
           socket
           |> put_flash(:error, "Utilisateur non trouvé")
           |> push_navigate(to: ~p"/posts")}

        profile_user ->
          if connected?(socket) do
            {:ok, _} = Presence.track(self(), "users:online", to_string(current_user.id), %{
              user_id: current_user.id,
              name: current_user.name,
              online_at: System.system_time(:second)
            })

            Phoenix.PubSub.subscribe(MonApp.PubSub, "user:#{current_user.id}")
          end

          friendship_status = Social.friendship_status(current_user.id, profile_user_id)
          friendship = Social.get_friendship(current_user.id, profile_user_id)
          friend_count = Social.count_friends(profile_user_id)
          dates_count = Blog.count_user_dates(profile_user_id)
          posts_count = Blog.count_user_posts(profile_user_id)
          dates_by_category = Blog.count_user_dates_by_category(profile_user_id)
          pending_count = length(Social.list_pending_requests(current_user.id))
          unread_messages_count = Chat.count_total_unread(current_user.id)

          {date_posts, date_has_more} = Blog.list_user_date_posts_paginated(profile_user_id, 1)
          {standard_posts, standard_has_more} = Blog.list_user_standard_posts_paginated(profile_user_id, 1)

          {:ok,
           socket
           |> assign(:profile_user, profile_user)
           |> assign(:friendship_status, friendship_status)
           |> assign(:friendship, friendship)
           |> assign(:friend_count, friend_count)
           |> assign(:dates_count, dates_count)
           |> assign(:posts_count, posts_count)
           |> assign(:dates_by_category, dates_by_category)
           |> assign(:profile_tab, if(profile_user.show_dates_on_profile, do: "dates", else: "posts"))
           |> assign(:date_posts, date_posts)
           |> assign(:date_page, 1)
           |> assign(:date_has_more, date_has_more)
           |> assign(:standard_posts, standard_posts)
           |> assign(:standard_page, 1)
           |> assign(:standard_has_more, standard_has_more)
           |> assign(:posts, date_posts ++ standard_posts)
           |> assign(:pending_requests_count, pending_count)
           |> assign(:unread_messages_count, unread_messages_count)
           |> assign(:chat_drawer_open, false)
           |> assign(:chat_conversation, nil)
           # Post interaction assigns
           |> assign(:viewing_post, nil)
           |> assign(:comment_form, nil)
           |> assign(:comment_form_id, nil)
           |> assign(:replying_to, nil)
           |> assign(:viewing_reactions_post, nil)
           |> assign(:reactions_filter, "all")
           |> assign(:friendship_statuses, %{})
           |> assign(:viewing_comment_reactions, nil)
           |> assign(:comment_reactions_filter, "all")
           |> assign(:comment_friendship_statuses, %{})
           |> assign(:preview_image, nil)
           |> assign(:sharing_post, nil)
           |> assign(:share_form, to_form(%{"visibility" => "public"}))
           |> assign(:show_remove_confirm, false)
           |> assign(:is_blocked, Social.blocked?(current_user.id, profile_user_id))
           |> assign(:profile_online, to_string(profile_user_id) in (Presence.list("users:online") |> Map.keys()))
           |> assign(:show_report_modal, false)
           |> assign(:report_reason, nil)
           |> allow_upload(:comment_images,
             accept: ~w(.jpg .jpeg .png .gif .webp),
             max_entries: 4,
             max_file_size: 5_000_000
           )
           |> ToastHandler.init_toast()}
      end
    end
  end

  # ============== RENDER ==============

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-base-200 overflow-x-hidden">
      <.navbar
        current_user={@current_user}
        current_path={"/profile/#{@profile_user.id}"}
        pending_requests_count={@pending_requests_count}
        unread_messages_count={@unread_messages_count}
        notifications={@notifications}
        unread_notifications_count={@unread_notifications_count}
      />
      <.toast_popup toast={@toast} />

      <main class={"max-w-2xl mx-auto p-4 sm:p-6 pb-20 md:pb-6 #{if @viewing_post || @viewing_reactions_post || @viewing_comment_reactions || @preview_image || @sharing_post, do: "overflow-hidden h-screen", else: ""}"}>
        <!-- Post Modals -->
        <.post_detail_modal
          :if={@viewing_post}
          post={@viewing_post}
          current_user={@current_user}
          comment_form={@comment_form}
          comment_form_id={@comment_form_id}
          replying_to={@replying_to}
          uploads={@uploads}
        />
        <.reactions_modal
          :if={@viewing_reactions_post}
          post={@viewing_reactions_post}
          current_user={@current_user}
          reactions={@viewing_reactions_post.reactions}
          filter={@reactions_filter}
          friendship_statuses={@friendship_statuses}
        />
        <.comment_reactions_modal
          :if={@viewing_comment_reactions}
          comment={@viewing_comment_reactions}
          current_user={@current_user}
          reactions={@viewing_comment_reactions.reactions}
          filter={@comment_reactions_filter}
          friendship_statuses={@comment_friendship_statuses}
        />
        <.image_preview_modal :if={@preview_image} src={@preview_image} />
        <.share_post_modal
          :if={@sharing_post}
          post={@sharing_post}
          current_user={@current_user}
          form={@share_form}
        />

        <!-- Profile Header Card -->
        <div class="bg-base-100 rounded-2xl shadow-sm overflow-hidden mb-4">
          <div class="p-5 sm:p-6">
            <div class="flex flex-col sm:flex-row items-center gap-5">
              <!-- Avatar -->
              <div class="relative shrink-0">
                <div class="w-24 h-24 sm:w-28 sm:h-28 rounded-full overflow-hidden bg-primary grid place-items-center ring-4 ring-base-200">
                  <%= if @profile_user.avatar do %>
                    <img src={"/uploads/avatars/#{@profile_user.avatar}"} alt="Avatar" class="w-full h-full object-cover" />
                  <% else %>
                    <span class="text-primary-content text-3xl sm:text-4xl font-bold leading-none">{String.first(@profile_user.name)}</span>
                  <% end %>
                </div>
                <span :if={@profile_online} class="absolute bottom-1 right-1 w-4 h-4 rounded-full bg-green-500 border-[3px] border-base-100"></span>
              </div>

              <!-- User Info -->
              <div class="text-center sm:text-left flex-1 min-w-0">
                <h1 class="text-xl sm:text-2xl font-bold truncate">@{@profile_user.name}</h1>
                <p class="text-base-content/50 text-sm truncate">{@profile_user.email}</p>

                <!-- Bio -->
                <p :if={@profile_user.bio && @profile_user.bio != ""} class="text-sm text-base-content/70 mt-2 line-clamp-3">
                  {@profile_user.bio}
                </p>

                <!-- Profile details pills -->
                <div class="flex flex-wrap justify-center sm:justify-start gap-1.5 mt-2">
                  <span :if={@profile_user.gender} class="inline-flex items-center gap-1 px-2.5 py-1 bg-base-200/60 rounded-full text-xs text-base-content/60">
                    {MonApp.Accounts.User.gender_label(@profile_user.gender)}
                  </span>
                  <span :if={@profile_user.location && @profile_user.location != ""} class="inline-flex items-center gap-1 px-2.5 py-1 bg-base-200/60 rounded-full text-xs text-base-content/60">
                    <svg xmlns="http://www.w3.org/2000/svg" class="h-3 w-3" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                      <path stroke-linecap="round" stroke-linejoin="round" d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z" />
                      <path stroke-linecap="round" stroke-linejoin="round" d="M15 11a3 3 0 11-6 0 3 3 0 016 0z" />
                    </svg>
                    {@profile_user.location}
                  </span>
                  <span :if={@profile_user.looking_for && @profile_user.looking_for != "any"} class="inline-flex items-center gap-1 px-2.5 py-1 bg-pink-500/10 rounded-full text-xs text-pink-500">
                    <svg xmlns="http://www.w3.org/2000/svg" class="h-3 w-3" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                      <path stroke-linecap="round" stroke-linejoin="round" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
                    </svg>
                    {MonApp.Accounts.User.looking_for_label(@profile_user.looking_for)}
                  </span>
                  <span :if={@profile_user.nationality} class="inline-flex items-center gap-1 px-2.5 py-1 bg-base-200/60 rounded-full text-xs text-base-content/60">
                    {MonApp.Accounts.User.nationality_flag(@profile_user.nationality)} {MonApp.Accounts.User.nationality_label(@profile_user.nationality)}
                  </span>
                  <span :if={@profile_user.birthdate} class="inline-flex items-center gap-1 px-2.5 py-1 bg-base-200/60 rounded-full text-xs text-base-content/60">
                    {trunc(Date.diff(Date.utc_today(), @profile_user.birthdate) / 365)} ans
                  </span>
                </div>

                <p class="text-xs text-base-content/40 mt-2">
                  Membre depuis {Calendar.strftime(@profile_user.inserted_at, "%B %Y")}
                </p>

                <!-- Stats -->
                <div class="flex justify-center sm:justify-start gap-5 mt-3">
                  <div class="text-center">
                    <div class="text-lg font-bold text-base-content">{@friend_count}</div>
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

            <!-- Action Buttons -->
            <div class="flex items-center gap-2 mt-4 justify-center sm:justify-start">
              <.friendship_actions status={@friendship_status} friendship={@friendship} profile_user={@profile_user} />
              <!-- More menu (block/report) -->
              <div class="dropdown dropdown-end">
                <div tabindex="0" role="button" class="btn btn-ghost btn-sm btn-circle">
                  <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 text-base-content/40" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M12 5v.01M12 12v.01M12 19v.01" />
                  </svg>
                </div>
                <ul tabindex="0" class="dropdown-content menu bg-base-100 rounded-xl z-[1] w-52 p-1.5 shadow-xl border border-base-200 mt-1">
                  <li>
                    <button phx-click="toggle_block" class="text-sm flex items-center gap-2">
                      <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                        <path stroke-linecap="round" stroke-linejoin="round" d="M18.364 18.364A9 9 0 005.636 5.636m12.728 12.728A9 9 0 015.636 5.636m12.728 12.728L5.636 5.636" />
                      </svg>
                      {if @is_blocked, do: "Débloquer", else: "Bloquer"}
                    </button>
                  </li>
                  <li>
                    <button phx-click="open_report_modal" class="text-sm text-error flex items-center gap-2">
                      <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                        <path stroke-linecap="round" stroke-linejoin="round" d="M3 21v-4m0 0V5a2 2 0 012-2h6.5l1 1H21l-3 6 3 6h-8.5l-1-1H5a2 2 0 00-2 2zm9-13.5V9" />
                      </svg>
                      Signaler
                    </button>
                  </li>
                </ul>
              </div>
            </div>
          </div>
        </div>

        <!-- Date Categories Stats -->
        <div :if={@dates_by_category != %{} && @profile_user.show_dates_on_profile} class="bg-base-100 rounded-2xl shadow-sm p-4 sm:p-5 mb-4">
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

        <%
          show_dates = @profile_user.show_dates_on_profile
          show_posts = @profile_user.show_posts_on_profile
        %>

        <!-- Tabs: Dates / Publications (only if at least one visible) -->
        <div :if={show_dates || show_posts} class="flex gap-1 bg-base-100 rounded-xl p-1 mb-4 shadow-sm">
          <button
            :if={show_dates}
            phx-click="switch_profile_tab"
            phx-value-tab="dates"
            class={"flex-1 py-2 px-3 rounded-lg text-sm font-medium transition-all #{if @profile_tab == "dates", do: "bg-pink-500 text-white shadow-sm", else: "text-base-content/50 hover:text-base-content"}"}
          >
            Dates ({@dates_count})
          </button>
          <button
            :if={show_posts}
            phx-click="switch_profile_tab"
            phx-value-tab="posts"
            class={"flex-1 py-2 px-3 rounded-lg text-sm font-medium transition-all #{if @profile_tab == "posts", do: "bg-pink-500 text-white shadow-sm", else: "text-base-content/50 hover:text-base-content"}"}
          >
            Publications ({@posts_count})
          </button>
        </div>

        <!-- Nothing visible -->
        <div :if={!show_dates && !show_posts} class="bg-base-100 rounded-2xl shadow-sm p-8 text-center">
          <svg xmlns="http://www.w3.org/2000/svg" class="h-10 w-10 mx-auto text-base-content/20 mb-2" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.5">
            <path stroke-linecap="round" stroke-linejoin="round" d="M13.875 18.825A10.05 10.05 0 0112 19c-4.478 0-8.268-2.943-9.543-7a9.97 9.97 0 011.563-3.029m5.858.908a3 3 0 114.243 4.243M9.878 9.878l4.242 4.242M9.88 9.88l-3.29-3.29m7.532 7.532l3.29 3.29M3 3l3.59 3.59m0 0A9.953 9.953 0 0112 5c4.478 0 8.268 2.943 9.543 7a10.025 10.025 0 01-4.132 5.411m0 0L21 21" />
          </svg>
          <p class="text-base-content/40 text-sm">Cet utilisateur a masqué ses publications</p>
        </div>

        <!-- Date Posts Tab -->
        <div :if={show_dates && @profile_tab == "dates"} class="space-y-4">
          <div :if={@date_posts == []} class="bg-base-100 rounded-2xl shadow-sm p-8 text-center">
            <p class="text-base-content/50">Aucun date publié</p>
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
        <div :if={show_posts && @profile_tab == "posts"} class="space-y-4">
          <div :if={@standard_posts == []} class="bg-base-100 rounded-2xl shadow-sm p-8 text-center">
            <p class="text-base-content/50">Aucune publication</p>
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
      </main>

      <!-- Chat Drawer -->
      <.live_component
        module={MonAppWeb.ChatDrawer}
        id="chat-drawer"
        open={@chat_drawer_open}
        conversation={@chat_conversation}
        other_user={@profile_user}
        current_user={@current_user}
      />

      <!-- Remove Friend Confirm Dialog -->
      <.confirm_dialog
        :if={@show_remove_confirm}
        id="remove-friend-dialog"
        title="Retirer cet ami ?"
        message={"Vous ne pourrez plus voir les publications privées de #{@profile_user.name}."}
        icon={:danger}
        confirm_text="Retirer"
        cancel_text="Annuler"
        confirm_event="confirm_remove_friend"
        on_cancel="cancel_remove_friend"
      />

      <!-- Report Modal -->
      <div :if={@show_report_modal} class="fixed inset-0 bg-black/50 z-[100] flex items-center justify-center px-4">
        <div class="bg-base-100 rounded-2xl shadow-2xl max-w-sm w-full overflow-hidden" phx-click-away="close_report_modal">
          <div class="p-5">
            <h3 class="text-lg font-bold text-base-content">Signaler @{@profile_user.name}</h3>
            <p class="text-sm text-base-content/50 mt-1">Choisissez la raison du signalement</p>

            <div class="space-y-1.5 mt-4">
              <button
                :for={reason <- MonApp.Social.UserReport.reasons_for("user")}
                type="button"
                phx-click="submit_report"
                phx-value-reason={reason}
                class="w-full text-left px-4 py-2.5 rounded-xl text-sm hover:bg-base-200/50 transition-colors flex items-center justify-between"
              >
                <span>{MonApp.Social.UserReport.reason_label(reason)}</span>
                <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 text-base-content/20" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M9 5l7 7-7 7" />
                </svg>
              </button>
            </div>
          </div>
          <div class="border-t border-base-200">
            <button phx-click="close_report_modal" class="w-full py-3 text-sm font-medium text-base-content/50 hover:bg-base-200/50 transition-colors">
              Annuler
            </button>
          </div>
        </div>
      </div>
    </div>
    """
  end

  # ============== FRIENDSHIP ACTIONS COMPONENT ==============

  attr :status, :atom, required: true
  attr :friendship, :map, default: nil
  attr :profile_user, :map, required: true

  defp friendship_actions(%{status: :none} = assigns) do
    ~H"""
    <button phx-click="send_friend_request" class="btn btn-primary btn-sm">
      <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M18 9v3m0 0v3m0-3h3m-3 0h-3m-2-5a4 4 0 11-8 0 4 4 0 018 0zM3 20a6 6 0 0112 0v1H3v-1z" />
      </svg>
      Ajouter en ami
    </button>
    """
  end

  defp friendship_actions(%{status: :request_sent} = assigns) do
    ~H"""
    <button class="btn btn-ghost btn-sm" disabled>
      <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
      </svg>
      Demande envoyée
    </button>
    """
  end

  defp friendship_actions(%{status: :request_received} = assigns) do
    ~H"""
    <button phx-click="accept_friend_request" phx-value-id={@friendship.id} class="btn btn-primary btn-sm">
      Accepter
    </button>
    <button phx-click="reject_friend_request" phx-value-id={@friendship.id} class="btn btn-ghost btn-sm">
      Refuser
    </button>
    """
  end

  defp friendship_actions(%{status: :friends} = assigns) do
    ~H"""
    <button phx-click="open_chat_drawer" class="btn btn-primary btn-sm">
      <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z" />
      </svg>
      Envoyer un message
    </button>
    <button phx-click="show_remove_confirm" class="btn btn-ghost btn-sm text-error">
      <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 7a4 4 0 11-8 0 4 4 0 018 0zM9 14a6 6 0 00-6 6v1h12v-1a6 6 0 00-6-6zM21 12h-6" />
      </svg>
    </button>
    """
  end

  # ============== PROFILE TAB & PAGINATION ==============

  @impl true
  def handle_event("switch_profile_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, :profile_tab, tab)}
  end

  @impl true
  def handle_event("load_more_dates", _, socket) do
    profile_user_id = socket.assigns.profile_user.id
    next_page = socket.assigns.date_page + 1
    {new_posts, has_more} = Blog.list_user_date_posts_paginated(profile_user_id, next_page)

    {:noreply,
     socket
     |> assign(:date_posts, socket.assigns.date_posts ++ new_posts)
     |> assign(:date_page, next_page)
     |> assign(:date_has_more, has_more)
     |> assign(:posts, (socket.assigns.date_posts ++ new_posts) ++ socket.assigns.standard_posts)}
  end

  @impl true
  def handle_event("load_more_posts", _, socket) do
    profile_user_id = socket.assigns.profile_user.id
    next_page = socket.assigns.standard_page + 1
    {new_posts, has_more} = Blog.list_user_standard_posts_paginated(profile_user_id, next_page)

    {:noreply,
     socket
     |> assign(:standard_posts, socket.assigns.standard_posts ++ new_posts)
     |> assign(:standard_page, next_page)
     |> assign(:standard_has_more, has_more)
     |> assign(:posts, socket.assigns.date_posts ++ (socket.assigns.standard_posts ++ new_posts))}
  end

  # ============== FRIENDSHIP EVENTS ==============

  @impl true
  def handle_event("send_friend_request", _params, socket) do
    current_user = socket.assigns.current_user
    profile_user = socket.assigns.profile_user

    case Social.send_friend_request(current_user.id, profile_user.id) do
      {:ok, friendship} ->
        Notifications.notify_friend_request(current_user, profile_user.id)
        {:noreply,
         socket
         |> assign(:friendship_status, :request_sent)
         |> assign(:friendship, friendship)}

      {:error, :already_exists} ->
        {:noreply, put_flash(socket, :info, "Demande déjà envoyée")}

      {:error, :daily_limit_reached} ->
        {:noreply, put_flash(socket, :error, "Vous avez atteint la limite de 20 demandes par jour")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Erreur lors de l'envoi")}
    end
  end

  @impl true
  def handle_event("accept_friend_request", %{"id" => id}, socket) do
    friendship_id = String.to_integer(id)
    current_user = socket.assigns.current_user

    case Social.accept_friend_request(friendship_id, current_user.id) do
      {:ok, friendship} ->
        Notifications.notify_friend_accepted(current_user, friendship.user_id)
        {:noreply,
         socket
         |> assign(:friendship_status, :friends)
         |> assign(:friendship, friendship)
         |> assign(:friend_count, socket.assigns.friend_count + 1)}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Erreur")}
    end
  end

  @impl true
  def handle_event("reject_friend_request", %{"id" => id}, socket) do
    friendship_id = String.to_integer(id)
    current_user = socket.assigns.current_user

    case Social.reject_friend_request(friendship_id, current_user.id) do
      {:ok, _} ->
        {:noreply,
         socket
         |> assign(:friendship_status, :none)
         |> assign(:friendship, nil)}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Erreur")}
    end
  end

  @impl true
  def handle_event("show_remove_confirm", _params, socket) do
    {:noreply, assign(socket, :show_remove_confirm, true)}
  end

  @impl true
  def handle_event("cancel_remove_friend", _params, socket) do
    {:noreply, assign(socket, :show_remove_confirm, false)}
  end

  @impl true
  def handle_event("confirm_remove_friend", _params, socket) do
    current_user = socket.assigns.current_user
    profile_user = socket.assigns.profile_user

    case Social.remove_friend(current_user.id, profile_user.id) do
      {:ok, _} ->
        {:noreply,
         socket
         |> assign(:friendship_status, :none)
         |> assign(:friendship, nil)
         |> assign(:friend_count, max(socket.assigns.friend_count - 1, 0))
         |> assign(:show_remove_confirm, false)}

      {:error, _} ->
        {:noreply,
         socket
         |> assign(:show_remove_confirm, false)
         |> put_flash(:error, "Erreur")}
    end
  end

  @impl true
  def handle_event("open_chat_drawer", _params, socket) do
    current_user = socket.assigns.current_user
    profile_user = socket.assigns.profile_user

    case Chat.get_or_create_conversation(current_user.id, profile_user.id) do
      {:ok, conversation} ->
        # S'abonner au channel de la conversation pour le temps réel
        if connected?(socket) do
          Phoenix.PubSub.subscribe(MonApp.PubSub, "chat:#{conversation.id}")
        end

        {:noreply,
         socket
         |> assign(:chat_conversation, conversation)
         |> assign(:chat_drawer_open, true)}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Erreur lors de l'ouverture du chat")}
    end
  end

  @impl true
  def handle_event("close_chat_drawer", _params, socket) do
    {:noreply, assign(socket, :chat_drawer_open, false)}
  end

  # ============== BLOCK / REPORT ==============

  @impl true
  def handle_event("toggle_block", _, socket) do
    current_user = socket.assigns.current_user
    profile_user = socket.assigns.profile_user

    if socket.assigns.is_blocked do
      Social.unblock_user(current_user.id, profile_user.id)
      {:noreply,
       socket
       |> assign(:is_blocked, false)
       |> put_flash(:info, "#{profile_user.name} a été débloqué")}
    else
      Social.block_user(current_user.id, profile_user.id)
      {:noreply,
       socket
       |> assign(:is_blocked, true)
       |> assign(:friendship_status, :none)
       |> assign(:friendship, nil)
       |> put_flash(:info, "#{profile_user.name} a été bloqué")}
    end
  end

  @impl true
  def handle_event("open_report_modal", _, socket) do
    {:noreply, assign(socket, :show_report_modal, true)}
  end

  @impl true
  def handle_event("close_report_modal", _, socket) do
    {:noreply, assign(socket, :show_report_modal, false)}
  end

  @impl true
  def handle_event("submit_report", %{"reason" => reason}, socket) do
    current_user = socket.assigns.current_user
    profile_user = socket.assigns.profile_user

    case Social.report_user(current_user.id, profile_user.id, reason) do
      {:ok, _} ->
        {:noreply,
         socket
         |> assign(:show_report_modal, false)
         |> put_flash(:info, "Signalement envoyé. Merci pour votre vigilance.")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Erreur lors du signalement")}
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

  # ============== POST INTERACTION EVENTS ==============

  @impl true
  def handle_event("open_comments", %{"id" => id}, socket) do
    post = Blog.get_post_with_comments(id)

    if post do
      comment_form = Blog.change_comment(%Comment{}) |> to_form()

      {:noreply,
       socket
       |> assign(:viewing_post, post)
       |> assign(:comment_form, comment_form)
       |> assign(:comment_form_id, System.unique_integer())
       |> assign(:replying_to, nil)}
    else
      {:noreply, put_flash(socket, :error, "Post non trouvé")}
    end
  end

  @impl true
  def handle_event("close_comments", _, socket) do
    if socket.assigns.viewing_comment_reactions || socket.assigns.preview_image do
      {:noreply, socket}
    else
      {:noreply,
       socket
       |> assign(:viewing_post, nil)
       |> assign(:comment_form, nil)
       |> assign(:replying_to, nil)}
    end
  end

  @impl true
  def handle_event("toggle_reaction", %{"post-id" => post_id, "type" => reaction_type}, socket) do
    user = socket.assigns.current_user
    post_id_int = String.to_integer(post_id)

    case Blog.toggle_reaction(user.id, post_id_int, reaction_type) do
      {:ok, _result} ->
        updated_posts = update_post_reactions(socket.assigns.posts, post_id_int)

        socket = assign(socket, :posts, updated_posts)
        socket = if socket.assigns.viewing_post && socket.assigns.viewing_post.id == post_id_int do
          updated_viewing_post = Enum.find(updated_posts, fn p -> p.id == post_id_int end)
          assign(socket, :viewing_post, updated_viewing_post)
        else
          socket
        end

        {:noreply, socket}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Erreur lors de la réaction")}
    end
  end

  @impl true
  def handle_event("open_reactions", %{"id" => id}, socket) do
    post = Blog.get_post(id) |> Repo.preload([:user, reactions: [:user]])
    user_id = socket.assigns.current_user.id

    if post do
      friendship_statuses =
        post.reactions
        |> Enum.map(fn r -> r.user_id end)
        |> Enum.uniq()
        |> Enum.reject(fn uid -> uid == user_id end)
        |> Enum.map(fn uid -> {uid, Social.friendship_status(user_id, uid)} end)
        |> Enum.into(%{})

      {:noreply,
       socket
       |> assign(:viewing_reactions_post, post)
       |> assign(:reactions_filter, "all")
       |> assign(:friendship_statuses, friendship_statuses)}
    else
      {:noreply, put_flash(socket, :error, "Post non trouvé")}
    end
  end

  @impl true
  def handle_event("close_reactions", _, socket) do
    {:noreply,
     socket
     |> assign(:viewing_reactions_post, nil)
     |> assign(:reactions_filter, "all")
     |> assign(:friendship_statuses, %{})}
  end

  @impl true
  def handle_event("filter_reactions", %{"filter" => filter}, socket) do
    {:noreply, assign(socket, :reactions_filter, filter)}
  end

  @impl true
  def handle_event("send_friend_request_from_reactions", %{"user-id" => friend_id}, socket) do
    user_id = socket.assigns.current_user.id
    friend_id = String.to_integer(friend_id)

    case Social.send_friend_request(user_id, friend_id) do
      {:ok, _} ->
        friendship_statuses = Map.put(socket.assigns.friendship_statuses, friend_id, :request_sent)
        {:noreply,
         socket
         |> assign(:friendship_statuses, friendship_statuses)
         |> put_flash(:info, "Demande d'ami envoyée")}

      {:error, :already_exists} ->
        {:noreply, put_flash(socket, :info, "Demande déjà envoyée ou vous êtes déjà amis")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Erreur lors de l'envoi de la demande")}
    end
  end

  @impl true
  def handle_event("cancel_friend_request_from_reactions", %{"user-id" => friend_id}, socket) do
    user_id = socket.assigns.current_user.id
    friend_id = String.to_integer(friend_id)

    case Social.cancel_friend_request(user_id, friend_id) do
      {:ok, _} ->
        friendship_statuses = Map.put(socket.assigns.friendship_statuses, friend_id, :none)
        {:noreply,
         socket
         |> assign(:friendship_statuses, friendship_statuses)
         |> put_flash(:info, "Demande annulée")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Erreur lors de l'annulation")}
    end
  end

  @impl true
  def handle_event("accept_friend_from_reactions", %{"user-id" => friend_id}, socket) do
    user_id = socket.assigns.current_user.id
    friend_id = String.to_integer(friend_id)

    pending_requests = Social.list_pending_requests(user_id)
    request = Enum.find(pending_requests, fn r -> r.user_id == friend_id end)

    if request do
      case Social.accept_friend_request(request.id, user_id) do
        {:ok, _} ->
          friendship_statuses = Map.put(socket.assigns.friendship_statuses, friend_id, :friends)
          pending_count = socket.assigns.pending_requests_count - 1
          {:noreply,
           socket
           |> assign(:friendship_statuses, friendship_statuses)
           |> assign(:pending_requests_count, pending_count)
           |> put_flash(:info, "Demande acceptée ! Vous êtes maintenant amis")}

        {:error, _} ->
          {:noreply, put_flash(socket, :error, "Erreur lors de l'acceptation")}
      end
    else
      {:noreply, put_flash(socket, :error, "Demande non trouvée")}
    end
  end

  # ============== COMMENT EVENTS ==============

  @impl true
  def handle_event("start_reply", %{"id" => comment_id}, socket) do
    comment = Blog.get_comment(comment_id) |> Repo.preload(:user)

    if comment do
      {:noreply, assign(socket, :replying_to, comment)}
    else
      {:noreply, put_flash(socket, :error, "Commentaire non trouvé")}
    end
  end

  @impl true
  def handle_event("cancel_reply", _, socket) do
    {:noreply, assign(socket, :replying_to, nil)}
  end

  @impl true
  def handle_event("cancel-comment-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :comment_images, ref)}
  end

  @impl true
  def handle_event("validate_comment", %{"comment" => _comment_params}, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("add_comment", %{"comment" => comment_params}, socket) do
    user = socket.assigns.current_user
    post = socket.assigns.viewing_post

    has_body = comment_params["body"] && String.trim(comment_params["body"]) != ""
    has_image = socket.assigns.uploads.comment_images.entries != []

    if !has_body && !has_image do
      {:noreply, put_flash(socket, :error, "Ajoutez un texte ou une image")}
    else
      comment_params =
        comment_params
        |> Map.put("user_id", user.id)
        |> Map.put("post_id", post.id)
        |> Map.update("body", "", fn body -> if body, do: body, else: "" end)

      case Blog.create_comment(comment_params) do
        {:ok, comment} ->
          save_comment_images(socket, comment.id)
          comment = Repo.preload(comment, [:user, :images, :replies, :reactions])

          updated_post = %{post | comments: post.comments ++ [comment]}

          posts =
            Enum.map(socket.assigns.posts, fn p ->
              if p.id == post.id do
                %{p | comments: p.comments ++ [comment]}
              else
                p
              end
            end)

          Notifications.notify_comment(post, comment, user)

          {:noreply,
           socket
           |> assign(:viewing_post, updated_post)
           |> assign(:posts, posts)
           |> assign(:comment_form, to_form(Blog.change_comment(%Comment{})))
           |> assign(:comment_form_id, System.unique_integer())}

        {:error, changeset} ->
          {:noreply, assign(socket, :comment_form, to_form(changeset))}
      end
    end
  end

  @impl true
  def handle_event("add_reply", %{"comment" => comment_params}, socket) do
    user = socket.assigns.current_user
    post = socket.assigns.viewing_post
    parent_comment = socket.assigns.replying_to

    has_body = comment_params["body"] && String.trim(comment_params["body"]) != ""
    has_image = socket.assigns.uploads.comment_images.entries != []

    if !has_body && !has_image do
      {:noreply, put_flash(socket, :error, "Ajoutez un texte ou une image")}
    else
      comment_params =
        comment_params
        |> Map.put("user_id", user.id)
        |> Map.put("post_id", post.id)
        |> Map.put("parent_id", parent_comment.id)
        |> Map.update("body", "", fn body -> if body, do: body, else: "" end)

      case Blog.create_reply(comment_params) do
        {:ok, reply} ->
          save_comment_images(socket, reply.id)
          reply = Repo.preload(reply, [:user, :images, :reactions])

          updated_comments =
            Enum.map(post.comments, fn comment ->
              if comment.id == parent_comment.id do
                existing_replies = Map.get(comment, :replies, [])
                %{comment | replies: existing_replies ++ [reply]}
              else
                comment
              end
            end)

          updated_post = %{post | comments: updated_comments}

          posts =
            Enum.map(socket.assigns.posts, fn p ->
              if p.id == post.id do
                %{p | comments: updated_comments}
              else
                p
              end
            end)

          Notifications.notify_comment(post, reply, user)
          Notifications.notify_reply(post, reply, parent_comment, user)

          {:noreply,
           socket
           |> assign(:viewing_post, updated_post)
           |> assign(:posts, posts)
           |> assign(:comment_form, to_form(Blog.change_comment(%Comment{})))
           |> assign(:comment_form_id, System.unique_integer())
           |> assign(:replying_to, nil)}

        {:error, changeset} ->
          {:noreply, assign(socket, :comment_form, to_form(changeset))}
      end
    end
  end

  @impl true
  def handle_event("delete_comment", %{"id" => comment_id}, socket) do
    user = socket.assigns.current_user
    post = socket.assigns.viewing_post
    comment = Blog.get_comment(comment_id)

    can_delete? = comment && (comment.user_id == user.id or post.user_id == user.id)

    if can_delete? do
      case Blog.delete_comment(comment) do
        {:ok, _} ->
          updated_comments = Enum.reject(post.comments, &(&1.id == comment.id))
          updated_post = %{post | comments: updated_comments}

          posts =
            Enum.map(socket.assigns.posts, fn p ->
              if p.id == post.id do
                %{p | comments: updated_comments}
              else
                p
              end
            end)

          {:noreply,
           socket
           |> assign(:viewing_post, updated_post)
           |> assign(:posts, posts)}

        {:error, _} ->
          {:noreply, put_flash(socket, :error, "Erreur lors de la suppression")}
      end
    else
      {:noreply, put_flash(socket, :error, "Non autorisé")}
    end
  end

  # ============== COMMENT REACTION EVENTS ==============

  @impl true
  def handle_event("toggle_comment_reaction", %{"comment-id" => comment_id, "type" => reaction_type}, socket) do
    user = socket.assigns.current_user
    comment_id = String.to_integer(comment_id)

    case Blog.toggle_comment_reaction(user.id, comment_id, reaction_type) do
      {:ok, _result} ->
        updated_posts = update_comment_reactions(socket.assigns.posts, comment_id)

        socket =
          if socket.assigns.viewing_post do
            updated_viewing_post = update_post_comment_reactions(socket.assigns.viewing_post, comment_id)
            assign(socket, :viewing_post, updated_viewing_post)
          else
            socket
          end

        {:noreply, assign(socket, :posts, updated_posts)}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Erreur lors de la réaction")}
    end
  end

  @impl true
  def handle_event("open_comment_reactions", %{"comment-id" => comment_id}, socket) do
    comment_id = String.to_integer(comment_id)
    user_id = socket.assigns.current_user.id

    comment = find_comment_in_posts(socket.assigns.posts, comment_id) ||
              (socket.assigns.viewing_post && find_comment_in_post(socket.assigns.viewing_post, comment_id))

    if comment do
      reactions = Blog.list_comment_reactions(comment_id)
      comment = %{comment | reactions: reactions}

      friendship_statuses =
        reactions
        |> Enum.map(fn r -> r.user_id end)
        |> Enum.uniq()
        |> Enum.reject(fn uid -> uid == user_id end)
        |> Enum.map(fn uid -> {uid, Social.friendship_status(user_id, uid)} end)
        |> Enum.into(%{})

      {:noreply,
       socket
       |> assign(:viewing_comment_reactions, comment)
       |> assign(:comment_reactions_filter, "all")
       |> assign(:comment_friendship_statuses, friendship_statuses)}
    else
      {:noreply, put_flash(socket, :error, "Commentaire non trouvé")}
    end
  end

  @impl true
  def handle_event("close_comment_reactions", _, socket) do
    {:noreply,
     socket
     |> assign(:viewing_comment_reactions, nil)
     |> assign(:comment_reactions_filter, "all")
     |> assign(:comment_friendship_statuses, %{})}
  end

  @impl true
  def handle_event("filter_comment_reactions", %{"filter" => filter}, socket) do
    {:noreply, assign(socket, :comment_reactions_filter, filter)}
  end

  @impl true
  def handle_event("send_friend_request_from_comment_reactions", %{"user-id" => friend_id}, socket) do
    user_id = socket.assigns.current_user.id
    friend_id = String.to_integer(friend_id)

    case Social.send_friend_request(user_id, friend_id) do
      {:ok, _} ->
        friendship_statuses = Map.put(socket.assigns.comment_friendship_statuses, friend_id, :request_sent)
        {:noreply,
         socket
         |> assign(:comment_friendship_statuses, friendship_statuses)
         |> put_flash(:info, "Demande d'ami envoyée")}

      {:error, :already_exists} ->
        {:noreply, put_flash(socket, :info, "Demande déjà envoyée ou vous êtes déjà amis")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Erreur lors de l'envoi de la demande")}
    end
  end

  @impl true
  def handle_event("accept_friend_from_comment_reactions", %{"user-id" => friend_id}, socket) do
    user_id = socket.assigns.current_user.id
    friend_id = String.to_integer(friend_id)

    pending_requests = Social.list_pending_requests(user_id)
    request = Enum.find(pending_requests, fn r -> r.user_id == friend_id end)

    if request do
      case Social.accept_friend_request(request.id, user_id) do
        {:ok, _} ->
          friendship_statuses = Map.put(socket.assigns.comment_friendship_statuses, friend_id, :friends)
          pending_count = socket.assigns.pending_requests_count - 1
          {:noreply,
           socket
           |> assign(:comment_friendship_statuses, friendship_statuses)
           |> assign(:pending_requests_count, pending_count)
           |> put_flash(:info, "Demande acceptée ! Vous êtes maintenant amis")}

        {:error, _} ->
          {:noreply, put_flash(socket, :error, "Erreur lors de l'acceptation")}
      end
    else
      {:noreply, put_flash(socket, :error, "Demande non trouvée")}
    end
  end

  # ============== IMAGE PREVIEW EVENTS ==============

  @impl true
  def handle_event("open_image_preview", %{"src" => src}, socket) do
    {:noreply, assign(socket, :preview_image, src)}
  end

  @impl true
  def handle_event("close_image_preview", _, socket) do
    {:noreply, assign(socket, :preview_image, nil)}
  end

  # ============== SHARE EVENTS ==============

  @impl true
  def handle_event("open_share_modal", %{"id" => id}, socket) do
    post_id = String.to_integer(id)

    post = Enum.find(socket.assigns.posts, fn p -> p.id == post_id end)

    post = post || Enum.find_value(socket.assigns.posts, fn p ->
      if p.shared_post && p.shared_post.id == post_id, do: p.shared_post, else: nil
    end)

    post = post || Blog.get_post_with_user(post_id)

    if post do
      {:noreply,
       socket
       |> assign(:sharing_post, post)
       |> assign(:share_form, to_form(%{"visibility" => "public", "title" => "", "body" => ""}))}
    else
      {:noreply, put_flash(socket, :error, "Post non trouvé")}
    end
  end

  @impl true
  def handle_event("close_share_modal", _, socket) do
    {:noreply,
     socket
     |> assign(:sharing_post, nil)
     |> assign(:share_form, to_form(%{"visibility" => "public"}))}
  end

  @impl true
  def handle_event("validate_share", %{"share" => share_params}, socket) do
    {:noreply, assign(socket, :share_form, to_form(share_params))}
  end

  @impl true
  def handle_event("share_post", %{"share" => share_params}, socket) do
    user = socket.assigns.current_user
    shared_post_id = String.to_integer(share_params["shared_post_id"])

    attrs = %{
      title: share_params["title"],
      body: share_params["body"],
      visibility: share_params["visibility"] || "public"
    }

    case Blog.share_post(user.id, shared_post_id, attrs) do
      {:ok, _new_post} ->
        {:noreply,
         socket
         |> assign(:sharing_post, nil)
         |> assign(:share_form, to_form(%{"visibility" => "public"}))
         |> put_flash(:info, "Publication partagée !")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Erreur lors du partage")}
    end
  end

  # Events des composants chat (message_bubble, etc.) sans phx-target
  # Ils remontent au parent LiveView, on les forwarde au ChatDrawer
  @drawer_events ~w(
    open_reaction_picker close_reaction_picker toggle_reaction
    reply_to_message cancel_reply scroll_to_message
    open_context_menu close_context_menu copy_message forward_message
    open_delete_modal close_delete_modal delete_message_for_me delete_message_for_all
    typing
  )

  @impl true
  def handle_event(event, params, socket) when event in @drawer_events do
    if socket.assigns.chat_drawer_open do
      send_update(MonAppWeb.ChatDrawer, id: "chat-drawer", forward_event: {event, params})
    end
    {:noreply, socket}
  end

  # ============== PUBSUB HANDLERS ==============

  # Message envoyé par le ChatDrawer LiveComponent pour fermer le drawer
  @impl true
  def handle_info(:close_chat_drawer, socket) do
    {:noreply, assign(socket, :chat_drawer_open, false)}
  end

  # Tous les events PubSub du chat sont forwardés au drawer qui gère tout

  @impl true
  def handle_info({:new_message, message}, socket) do
    user_id = socket.assigns.current_user.id
    unread_count = Chat.count_total_unread(user_id)

    # Forwarder au drawer si ouvert et concerné
    if drawer_active?(socket, message.conversation_id) do
      send_update(MonAppWeb.ChatDrawer, id: "chat-drawer", new_message: message)
    end

    # Toast si pas dans le drawer actif et pas de soi-même
    socket =
      if !drawer_active?(socket, message.conversation_id) && message.sender_id != user_id do
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
  def handle_info({:typing, sender_id, is_typing}, socket) do
    if drawer_open?(socket) do
      send_update(MonAppWeb.ChatDrawer, id: "chat-drawer", typing: {sender_id, is_typing})
    end
    {:noreply, socket}
  end

  @impl true
  def handle_info({:messages_seen, message_ids}, socket) do
    if drawer_open?(socket) do
      send_update(MonAppWeb.ChatDrawer, id: "chat-drawer", messages_seen: message_ids)
    end
    {:noreply, socket}
  end

  @impl true
  def handle_info({:reaction_added, message_id, reaction}, socket) do
    if drawer_open?(socket) do
      send_update(MonAppWeb.ChatDrawer, id: "chat-drawer", reaction_added: {message_id, reaction})
    end
    {:noreply, socket}
  end

  @impl true
  def handle_info({:reaction_removed, message_id, reaction}, socket) do
    if drawer_open?(socket) do
      send_update(MonAppWeb.ChatDrawer, id: "chat-drawer", reaction_removed: {message_id, reaction})
    end
    {:noreply, socket}
  end

  @impl true
  def handle_info({:message_deleted, %{id: message_id, deleted_for_all_at: deleted_at}}, socket) do
    if drawer_open?(socket) do
      send_update(MonAppWeb.ChatDrawer, id: "chat-drawer", message_deleted: {message_id, deleted_at})
    end
    {:noreply, socket}
  end

  @impl true
  def handle_info({:message_deleted, message_id}, socket) when is_integer(message_id) do
    if drawer_open?(socket) do
      send_update(MonAppWeb.ChatDrawer, id: "chat-drawer", message_deleted: {message_id, nil})
    end
    {:noreply, socket}
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
  def handle_info({:friend_request_received, _}, socket) do
    pending_count = length(Social.list_pending_requests(socket.assigns.current_user.id))
    {:noreply, assign(socket, :pending_requests_count, pending_count)}
  end

  @impl true
  def handle_info({:friend_request_accepted, _}, socket) do
    current_user = socket.assigns.current_user
    profile_user = socket.assigns.profile_user
    friendship_status = Social.friendship_status(current_user.id, profile_user.id)
    friendship = Social.get_friendship(current_user.id, profile_user.id)
    friend_count = Social.count_friends(profile_user.id)

    {:noreply,
     socket
     |> assign(:friendship_status, friendship_status)
     |> assign(:friendship, friendship)
     |> assign(:friend_count, friend_count)}
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

  # ============== PRIVATE HELPERS ==============

  defp drawer_open?(socket) do
    socket.assigns.chat_drawer_open && socket.assigns.chat_conversation
  end

  defp drawer_active?(socket, conversation_id) do
    drawer_open?(socket) && socket.assigns.chat_conversation.id == conversation_id
  end

  # Post helpers

  defp update_post_reactions(posts, post_id) do
    Enum.map(posts, fn post ->
      if post.id == post_id do
        reactions = Blog.list_reactions(post_id)
        %{post | reactions: reactions}
      else
        post
      end
    end)
  end

  defp update_comment_reactions(posts, comment_id) do
    reactions = Blog.list_comment_reactions(comment_id)

    Enum.map(posts, fn post ->
      updated_comments = update_comments_with_reaction(post.comments, comment_id, reactions)
      %{post | comments: updated_comments}
    end)
  end

  defp update_post_comment_reactions(post, comment_id) do
    reactions = Blog.list_comment_reactions(comment_id)
    updated_comments = update_comments_with_reaction(post.comments, comment_id, reactions)
    %{post | comments: updated_comments}
  end

  defp update_comments_with_reaction(comments, comment_id, reactions) do
    Enum.map(comments, fn comment ->
      comment =
        if comment.id == comment_id do
          %{comment | reactions: reactions}
        else
          comment
        end

      replies = Map.get(comment, :replies, [])
      updated_replies = Enum.map(replies, fn reply ->
        if reply.id == comment_id do
          %{reply | reactions: reactions}
        else
          reply
        end
      end)

      %{comment | replies: updated_replies}
    end)
  end

  defp find_comment_in_posts(posts, comment_id) do
    Enum.find_value(posts, fn post ->
      find_comment_in_post(post, comment_id)
    end)
  end

  defp find_comment_in_post(post, comment_id) do
    found = Enum.find(post.comments, fn c -> c.id == comment_id end)

    if found do
      found
    else
      Enum.find_value(post.comments, fn comment ->
        replies = Map.get(comment, :replies, [])
        Enum.find(replies, fn r -> r.id == comment_id end)
      end)
    end
  end

  defp save_comment_images(socket, comment_id) do
    consume_uploaded_entries(socket, :comment_images, fn %{path: path}, entry ->
      ext = Path.extname(entry.client_name)
      filename = "comment_#{comment_id}_#{System.unique_integer([:positive])}#{ext}"
      dest = Path.join(Blog.comment_uploads_dir(), filename)

      File.cp!(path, dest)
      MonApp.ImageCompressor.compress(dest)

      Blog.create_comment_image(%{
        filename: filename,
        original_filename: entry.client_name,
        content_type: entry.client_type,
        size: entry.client_size,
        comment_id: comment_id
      })

      {:ok, filename}
    end)
  end
end
