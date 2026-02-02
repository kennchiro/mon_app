defmodule MonAppWeb.ProfileLive do
  use MonAppWeb, :live_view

  alias MonApp.Social

  import MonAppWeb.Navbar

  # ============== LIFECYCLE ==============

  @impl true
  def mount(_params, _session, socket) do
    user_id = socket.assigns.current_user.id
    pending_count = length(Social.list_pending_requests(user_id))

    {:ok, assign(socket, :pending_requests_count, pending_count)}
  end

  # ============== RENDER ==============

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-base-200">
      <.navbar current_user={@current_user} current_path="/profile" pending_requests_count={@pending_requests_count} />

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
end
