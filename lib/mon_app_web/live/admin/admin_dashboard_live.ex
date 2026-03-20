defmodule MonAppWeb.AdminDashboardLive do
  use MonAppWeb, :live_view

  alias MonApp.Admin

  def mount(_params, _session, socket) do
    stats = Admin.dashboard_stats()
    pending_reports_count = stats.reports.pending

    {:ok,
     socket
     |> assign(:page_title, "Dashboard")
     |> assign(:current_path, "/admin")
     |> assign(:pending_reports_count, pending_reports_count)
     |> assign(:stats, stats)}
  end

  def render(assigns) do
    ~H"""
    <!-- Stats cards -->
    <div class="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-4 gap-6 mb-8">
      <.stat_card
        title="Utilisateurs total"
        value={@stats.users.total}
        sub="+#{@stats.users.new_today} aujourd'hui"
        icon="hero-users"
        color="blue"
      />
      <.stat_card
        title="Nouveaux cette semaine"
        value={@stats.users.new_week}
        sub="+#{@stats.users.new_month} ce mois"
        icon="hero-user-plus"
        color="green"
      />
      <.stat_card
        title="Posts total"
        value={@stats.posts.total}
        sub="+#{@stats.posts.new_today} aujourd'hui"
        icon="hero-document-text"
        color="purple"
      />
      <.stat_card
        title="Reports en attente"
        value={@stats.reports.pending}
        sub="#{@stats.reports.total} total"
        icon="hero-flag"
        color={if @stats.reports.pending > 0, do: "red", else: "gray"}
      />
    </div>

    <!-- Charts row -->
    <div class="grid grid-cols-1 xl:grid-cols-2 gap-6 mb-8">
      <!-- Inscriptions 30 jours -->
      <div class="bg-white rounded-xl border border-gray-200 p-6">
        <h3 class="text-sm font-semibold text-gray-900 mb-4">Inscriptions — 30 derniers jours</h3>
        <div class="h-48 flex items-end gap-1">
          <%= for point <- @stats.registrations_chart do %>
            <div class="flex-1 flex flex-col items-center gap-1">
              <div
                class="w-full bg-pink-500 rounded-t opacity-80 hover:opacity-100 transition-opacity"
                style={"height: #{max(point.count * 8, 2)}px"}
                title={"#{point.date}: #{point.count} inscriptions"}
              />
            </div>
          <% end %>
        </div>
        <div class="flex justify-between text-xs text-gray-400 mt-2">
          <span>il y a 30j</span>
          <span>aujourd'hui</span>
        </div>
      </div>

      <!-- Répartition posts -->
      <div class="bg-white rounded-xl border border-gray-200 p-6">
        <h3 class="text-sm font-semibold text-gray-900 mb-4">Activité posts</h3>
        <div class="space-y-4">
          <.progress_row
            label="Posts standards"
            value={@stats.posts.total - @stats.posts.date_posts}
            total={@stats.posts.total}
            color="bg-blue-500"
          />
          <.progress_row
            label="Posts de dates"
            value={@stats.posts.date_posts}
            total={@stats.posts.total}
            color="bg-pink-500"
          />
        </div>

        <div class="mt-6 pt-4 border-t border-gray-100 grid grid-cols-2 gap-4">
          <div>
            <p class="text-2xl font-bold text-gray-900">{@stats.posts.new_week}</p>
            <p class="text-xs text-gray-500">nouveaux cette semaine</p>
          </div>
          <div>
            <p class="text-2xl font-bold text-gray-900">{@stats.reports.resolved}</p>
            <p class="text-xs text-gray-500">reports résolus</p>
          </div>
        </div>
      </div>
    </div>

    <!-- Quick actions -->
    <div class="bg-white rounded-xl border border-gray-200 p-6">
      <h3 class="text-sm font-semibold text-gray-900 mb-4">Accès rapide</h3>
      <div class="flex flex-wrap gap-3">
        <.link
          :if={@stats.reports.pending > 0}
          href="/admin/reports"
          class="inline-flex items-center gap-2 px-4 py-2 bg-red-50 text-red-700 border border-red-200 rounded-lg text-sm font-medium hover:bg-red-100 transition-colors"
        >
          <.icon name="hero-flag" class="w-4 h-4" />
          Traiter {@stats.reports.pending} report(s) en attente
        </.link>
        <.link
          href="/admin/users"
          class="inline-flex items-center gap-2 px-4 py-2 bg-gray-50 text-gray-700 border border-gray-200 rounded-lg text-sm font-medium hover:bg-gray-100 transition-colors"
        >
          <.icon name="hero-users" class="w-4 h-4" />
          Gérer les utilisateurs
        </.link>
        <.link
          href="/admin/analytics"
          class="inline-flex items-center gap-2 px-4 py-2 bg-gray-50 text-gray-700 border border-gray-200 rounded-lg text-sm font-medium hover:bg-gray-100 transition-colors"
        >
          <.icon name="hero-chart-bar" class="w-4 h-4" />
          Voir les analytics
        </.link>
      </div>
    </div>
    """
  end

  # ============== COMPOSANTS ==============

  attr :title, :string, required: true
  attr :value, :integer, required: true
  attr :sub, :string, required: true
  attr :icon, :string, required: true
  attr :color, :string, default: "gray"

  defp stat_card(assigns) do
    color_classes = %{
      "blue" => "bg-blue-50 text-blue-600",
      "green" => "bg-green-50 text-green-600",
      "purple" => "bg-purple-50 text-purple-600",
      "red" => "bg-red-50 text-red-600",
      "gray" => "bg-gray-100 text-gray-500"
    }

    assigns = assign(assigns, :icon_class, Map.get(color_classes, assigns.color, color_classes["gray"]))

    ~H"""
    <div class="bg-white rounded-xl border border-gray-200 p-6">
      <div class="flex items-start justify-between">
        <div>
          <p class="text-sm text-gray-500 font-medium">{@title}</p>
          <p class="text-3xl font-bold text-gray-900 mt-1">{@value}</p>
          <p class="text-xs text-gray-400 mt-1">{@sub}</p>
        </div>
        <div class={["w-10 h-10 rounded-lg flex items-center justify-center", @icon_class]}>
          <.icon name={@icon} class="w-5 h-5" />
        </div>
      </div>
    </div>
    """
  end

  attr :label, :string, required: true
  attr :value, :integer, required: true
  attr :total, :integer, required: true
  attr :color, :string, default: "bg-gray-400"

  defp progress_row(assigns) do
    pct = if assigns.total > 0, do: round(assigns.value / assigns.total * 100), else: 0
    assigns = assign(assigns, :pct, pct)

    ~H"""
    <div>
      <div class="flex justify-between text-sm mb-1">
        <span class="text-gray-700">{@label}</span>
        <span class="text-gray-500">{@value} ({@pct}%)</span>
      </div>
      <div class="w-full bg-gray-100 rounded-full h-2">
        <div class={[@color, "h-2 rounded-full transition-all"]} style={"width: #{@pct}%"} />
      </div>
    </div>
    """
  end
end
