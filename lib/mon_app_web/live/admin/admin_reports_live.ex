defmodule MonAppWeb.AdminReportsLive do
  use MonAppWeb, :live_view

  alias MonApp.Social
  alias MonApp.Social.UserReport

  @per_page 25

  def mount(_params, _session, socket) do
    stats = %{
      by_status: Social.report_stats_by_status(),
      by_type: Social.report_stats_by_type()
    }

    {:ok,
     socket
     |> assign(:page_title, "Reports")
     |> assign(:current_path, "/admin/reports")
     |> assign(:pending_reports_count, Map.get(stats.by_status, "pending", 0))
     |> assign(:stats, stats)
     |> assign(:status_filter, "pending")
     |> assign(:type_filter, "")
     |> assign(:sort, "newest")
     |> assign(:page, 1)
     |> load_reports()}
  end

  def handle_event("filter_status", %{"status" => s}, socket) do
    {:noreply, socket |> assign(:status_filter, s) |> assign(:page, 1) |> load_reports()}
  end

  def handle_event("filter_type", %{"type" => t}, socket) do
    {:noreply, socket |> assign(:type_filter, t) |> assign(:page, 1) |> load_reports()}
  end

  def handle_event("sort", %{"by" => by}, socket) do
    {:noreply, socket |> assign(:sort, by) |> assign(:page, 1) |> load_reports()}
  end

  def handle_event("page", %{"n" => n}, socket) do
    {:noreply, socket |> assign(:page, String.to_integer(n)) |> load_reports()}
  end

  def render(assigns) do
    ~H"""
    <!-- Stats en haut -->
    <div class="grid grid-cols-2 sm:grid-cols-4 gap-4 mb-6">
      <.report_stat_card
        label="En attente"
        value={Map.get(@stats.by_status, "pending", 0)}
        color="yellow"
        active={@status_filter == "pending"}
        phx_click="filter_status"
        phx_value="pending"
      />
      <.report_stat_card
        label="Résolus"
        value={Map.get(@stats.by_status, "resolved", 0)}
        color="green"
        active={@status_filter == "resolved"}
        phx_click="filter_status"
        phx_value="resolved"
      />
      <.report_stat_card
        label="Rejetés"
        value={Map.get(@stats.by_status, "dismissed", 0)}
        color="gray"
        active={@status_filter == "dismissed"}
        phx_click="filter_status"
        phx_value="dismissed"
      />
      <.report_stat_card
        label="Total"
        value={@result.total}
        color="blue"
        active={@status_filter == ""}
        phx_click="filter_status"
        phx_value=""
      />
    </div>

    <!-- Filtres -->
    <div class="bg-white rounded-xl border border-gray-200 p-4 mb-6 flex flex-wrap items-center gap-3">
      <select phx-change="filter_type" name="type"
        class="py-2 pl-3 pr-8 text-sm border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-pink-500">
        <option value="" selected={@type_filter == ""}>Tous les types</option>
        <option value="user" selected={@type_filter == "user"}>👤 Utilisateur</option>
        <option value="post" selected={@type_filter == "post"}>📄 Post</option>
        <option value="date" selected={@type_filter == "date"}>💝 Date</option>
      </select>

      <select phx-change="sort" name="by"
        class="py-2 pl-3 pr-8 text-sm border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-pink-500">
        <option value="newest" selected={@sort == "newest"}>Plus récents</option>
        <option value="oldest" selected={@sort == "oldest"}>Plus anciens</option>
      </select>

      <span class="text-sm text-gray-500 ml-auto">
        {@result.total} report{if @result.total > 1, do: "s", else: ""}
      </span>
    </div>

    <!-- Liste des reports -->
    <div class="space-y-3 mb-6">
      <div :if={@result.reports == []} class="bg-white rounded-xl border border-gray-200 py-16 text-center">
        <.icon name="hero-flag" class="w-10 h-10 mx-auto text-gray-300 mb-3" />
        <p class="text-gray-400 font-medium">Aucun report dans cette catégorie</p>
        <p :if={@status_filter == "pending"} class="text-sm text-green-600 mt-1">Tout est traité !</p>
      </div>

      <div :for={report <- @result.reports}
        class="bg-white rounded-xl border border-gray-200 hover:border-pink-200 transition-colors">
        <div class="p-5">
          <div class="flex items-start gap-4">
            <!-- Icône type -->
            <div class={["w-10 h-10 rounded-lg flex items-center justify-center shrink-0 text-lg", type_icon_bg(report.report_type)]}>
              {type_emoji(report.report_type)}
            </div>

            <!-- Contenu -->
            <div class="flex-1 min-w-0">
              <div class="flex items-center gap-2 mb-1 flex-wrap">
                <span class={["text-xs px-2 py-0.5 rounded-full font-semibold", type_badge_class(report.report_type)]}>
                  {report.report_type}
                </span>
                <span class={["text-xs px-2 py-0.5 rounded-full font-medium", status_badge_class(report.status)]}>
                  {status_label(report.status)}
                </span>
                <span class="text-sm font-semibold text-gray-900">
                  {UserReport.reason_label(report.reason)}
                </span>
              </div>

              <div class="flex items-center gap-3 text-xs text-gray-500 flex-wrap">
                <span>
                  Signalé par
                  <.link navigate={"/admin/users/#{report.reporter.id}"} class="font-medium text-gray-700 hover:text-pink-600">
                    {report.reporter.name}
                  </.link>
                </span>
                <span>→</span>
                <span>
                  Contre
                  <.link navigate={"/admin/users/#{report.reported.id}"} class="font-medium text-gray-700 hover:text-pink-600">
                    {report.reported.name}
                  </.link>
                </span>
                <span :if={report.post}>
                  · sur le post
                  <.link navigate={"/admin/posts/#{report.post.id}"} class="font-medium text-gray-700 hover:text-pink-600">
                    "{truncate(report.post.title, 30)}"
                  </.link>
                </span>
                <span class="ml-auto">{format_date(report.inserted_at)}</span>
              </div>

              <p :if={report.details} class="mt-2 text-sm text-gray-600 bg-gray-50 rounded-lg px-3 py-2 line-clamp-2">
                "{report.details}"
              </p>

              <p :if={report.resolution_note} class="mt-2 text-xs text-gray-500 italic">
                Note : {report.resolution_note}
                <span :if={report.resolved_by}>
                  — par {report.resolved_by.name}
                </span>
              </p>
            </div>

            <!-- Actions -->
            <div class="flex items-center gap-2 shrink-0">
              <.link
                navigate={"/admin/reports/#{report.id}"}
                class="px-3 py-1.5 text-xs font-medium bg-pink-600 hover:bg-pink-700 text-white rounded-lg transition-colors">
                Traiter
              </.link>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Pagination -->
    <div :if={@result.total_pages > 1} class="flex items-center justify-between">
      <p class="text-sm text-gray-500">Page {@result.page} sur {@result.total_pages}</p>
      <div class="flex gap-1">
        <button :if={@result.page > 1} phx-click="page" phx-value-n={@result.page - 1}
          class="px-3 py-1.5 text-sm border border-gray-300 rounded-lg hover:bg-gray-50 transition-colors">
          ← Précédent
        </button>
        <%= for n <- page_range(@result.page, @result.total_pages) do %>
          <button phx-click="page" phx-value-n={n}
            class={["px-3 py-1.5 text-sm border rounded-lg transition-colors",
              if(n == @result.page, do: "bg-pink-600 text-white border-pink-600", else: "border-gray-300 hover:bg-gray-50")]}>
            {n}
          </button>
        <% end %>
        <button :if={@result.page < @result.total_pages} phx-click="page" phx-value-n={@result.page + 1}
          class="px-3 py-1.5 text-sm border border-gray-300 rounded-lg hover:bg-gray-50 transition-colors">
          Suivant →
        </button>
      </div>
    </div>
    """
  end

  # ── Composant stat card ───────────────────────────────
  attr :label, :string, required: true
  attr :value, :integer, required: true
  attr :color, :string, default: "gray"
  attr :active, :boolean, default: false
  attr :phx_click, :string, required: true
  attr :phx_value, :string, required: true

  defp report_stat_card(assigns) do
    base = "rounded-xl border p-4 cursor-pointer transition-all text-center"
    active_class = if assigns.active, do: "border-pink-400 bg-pink-50 shadow-sm", else: "border-gray-200 bg-white hover:border-gray-300"
    assigns = assign(assigns, :classes, "#{base} #{active_class}")

    ~H"""
    <button class={@classes} phx-click={@phx_click} phx-value-status={@phx_value}>
      <p class={["text-2xl font-bold", value_color(@color)]}>{@value}</p>
      <p class="text-xs text-gray-500 mt-0.5">{@label}</p>
    </button>
    """
  end

  # ── Helpers ───────────────────────────────────────────
  defp load_reports(socket) do
    opts = [
      status: socket.assigns.status_filter,
      report_type: socket.assigns.type_filter,
      sort: socket.assigns.sort
    ]
    result = Social.list_reports_admin(socket.assigns.page, @per_page, opts)
    assign(socket, :result, result)
  end

  defp format_date(nil), do: "—"
  defp format_date(dt), do: Calendar.strftime(dt, "%d/%m/%Y %H:%M")

  defp truncate(nil, _), do: "—"
  defp truncate(str, max) when byte_size(str) > max, do: String.slice(str, 0, max) <> "…"
  defp truncate(str, _), do: str

  defp type_emoji("user"), do: "👤"
  defp type_emoji("post"), do: "📄"
  defp type_emoji("date"), do: "💝"
  defp type_emoji(_), do: "⚠️"

  defp type_icon_bg("user"), do: "bg-orange-50"
  defp type_icon_bg("post"), do: "bg-blue-50"
  defp type_icon_bg("date"), do: "bg-pink-50"
  defp type_icon_bg(_), do: "bg-gray-100"

  defp type_badge_class("user"), do: "bg-orange-50 text-orange-700"
  defp type_badge_class("post"), do: "bg-blue-50 text-blue-700"
  defp type_badge_class("date"), do: "bg-pink-50 text-pink-700"
  defp type_badge_class(_), do: "bg-gray-100 text-gray-600"

  defp status_badge_class("pending"), do: "bg-yellow-50 text-yellow-700"
  defp status_badge_class("resolved"), do: "bg-green-50 text-green-700"
  defp status_badge_class("dismissed"), do: "bg-gray-100 text-gray-500"
  defp status_badge_class(_), do: "bg-gray-100 text-gray-500"

  defp status_label("pending"), do: "En attente"
  defp status_label("resolved"), do: "Résolu"
  defp status_label("dismissed"), do: "Rejeté"
  defp status_label(s), do: s

  defp value_color("yellow"), do: "text-yellow-600"
  defp value_color("green"), do: "text-green-600"
  defp value_color("blue"), do: "text-blue-600"
  defp value_color(_), do: "text-gray-700"

  defp page_range(current, total) do
    Enum.to_list(max(1, current - 2)..min(total, current + 2))
  end
end
