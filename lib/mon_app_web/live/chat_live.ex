defmodule MonAppWeb.ChatLive do
  use MonAppWeb, :live_view

  alias MonApp.Social

  import MonAppWeb.Navbar

  @impl true
  def mount(_params, _session, socket) do
    user_id = socket.assigns.current_user.id
    pending_count = length(Social.list_pending_requests(user_id))

    {:ok, assign(socket, :pending_requests_count, pending_count)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-base-200">
      <.navbar current_user={@current_user} current_path="/chat" pending_requests_count={@pending_requests_count} />

      <main class="max-w-6xl mx-auto p-6">
        <div class="card bg-base-100 shadow-xl">
          <div class="card-body items-center text-center py-20">
            <div class="text-6xl mb-4">💬</div>
            <h2 class="card-title text-2xl">Chat - Bientôt disponible</h2>
            <p class="text-base-content/70 max-w-md">
              Cette fonctionnalité est en cours de développement.
              Le chat en temps réel sera disponible prochainement !
            </p>
            <div class="card-actions mt-6">
              <a href={~p"/posts"} class="btn btn-primary">
                Retour aux posts
              </a>
            </div>
          </div>
        </div>
      </main>
    </div>
    """
  end
end
