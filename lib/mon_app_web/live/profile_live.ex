defmodule MonAppWeb.ProfileLive do
  use MonAppWeb, :live_view

  alias MonApp.Social
  alias MonApp.Chat
  alias MonAppWeb.Presence

  import MonAppWeb.Navbar

  # ============== LIFECYCLE ==============

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_user
    user_id = user.id

    if connected?(socket) do
      # Tracker la présence de l'utilisateur
      {:ok, _} = Presence.track(self(), "users:online", to_string(user_id), %{
        user_id: user_id,
        name: user.name,
        online_at: System.system_time(:second)
      })

      # S'abonner aux notifications de nouveaux messages
      Phoenix.PubSub.subscribe(MonApp.PubSub, "user:#{user_id}")
    end

    pending_count = length(Social.list_pending_requests(user_id))
    unread_messages_count = Chat.count_total_unread(user_id)

    {:ok,
     socket
     |> assign(:pending_requests_count, pending_count)
     |> assign(:unread_messages_count, unread_messages_count)}
  end

  # ============== RENDER ==============

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-base-200">
      <.navbar current_user={@current_user} current_path="/profile" pending_requests_count={@pending_requests_count} unread_messages_count={@unread_messages_count} />

      <main class="max-w-4xl mx-auto p-6">
        <div class="card bg-base-100 shadow-sm">
          <div class="card-body">
            <!-- Header profil -->
            <div class="flex items-center gap-6">
              <div class="w-24 h-24 rounded-full bg-primary grid place-items-center">
                <span class="text-primary-content text-4xl font-bold leading-none">
                  {String.first(@current_user.name)}
                </span>
              </div>
              <div>
                <h1 class="text-2xl font-bold">{@current_user.name}</h1>
                <p class="text-base-content/60">{@current_user.email}</p>
                <p class="text-sm text-base-content/40 mt-1">
                  Membre depuis {Calendar.strftime(@current_user.inserted_at, "%B %Y")}
                </p>
              </div>
            </div>

            <div class="divider"></div>

            <!-- Informations -->
            <div class="grid gap-4">
              <div>
                <label class="text-sm text-base-content/60">Nom</label>
                <p class="font-medium">{@current_user.name}</p>
              </div>
              <div>
                <label class="text-sm text-base-content/60">Email</label>
                <p class="font-medium">{@current_user.email}</p>
              </div>
              <div :if={@current_user.age}>
                <label class="text-sm text-base-content/60">Âge</label>
                <p class="font-medium">{@current_user.age} ans</p>
              </div>
            </div>

            <div class="divider"></div>

            <!-- Actions -->
            <div class="text-center text-base-content/50">
              <p class="text-sm">La modification du profil sera disponible prochainement.</p>
            </div>
          </div>
        </div>
      </main>
    </div>
    """
  end

  # ============== PUBSUB HANDLERS ==============

  @impl true
  def handle_info({:new_message, _message}, socket) do
    # Incrémenter le compteur de messages non lus
    user_id = socket.assigns.current_user.id
    unread_count = Chat.count_total_unread(user_id)
    {:noreply, assign(socket, :unread_messages_count, unread_count)}
  end

  @impl true
  def handle_info(_msg, socket) do
    {:noreply, socket}
  end
end
