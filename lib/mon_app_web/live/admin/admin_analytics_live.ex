defmodule MonAppWeb.AdminAnalyticsLive do
  use MonAppWeb, :live_view

  alias MonApp.Admin
  alias MonApp.Social

  @ranges [{"7 jours", 7}, {"30 jours", 30}, {"90 jours", 90}]

  def mount(_params, _session, socket) do
    pending_reports_count =
      Social.report_stats_by_status() |> Map.get("pending", 0)

    {:ok,
     socket
     |> assign(:page_title, "Analytics")
     |> assign(:current_path, "/admin/analytics")
     |> assign(:pending_reports_count, pending_reports_count)
     |> assign(:range_days, 30)
     |> assign(:ranges, @ranges)
     |> load_analytics()}
  end

  def handle_event("set_range", %{"days" => days}, socket) do
    {:noreply,
     socket
     |> assign(:range_days, String.to_integer(days))
     |> load_analytics()}
  end

  def render(assigns) do
    ~H"""
    <!-- Range selector -->
    <div class="flex items-center gap-2 mb-6">
      <span class="text-sm text-gray-500 mr-2">Période :</span>
      <%= for {label, days} <- @ranges do %>
        <button
          phx-click="set_range"
          phx-value-days={days}
          class={[
            "px-4 py-1.5 text-sm font-medium rounded-lg border transition-colors",
            if(@range_days == days,
              do: "bg-pink-600 text-white border-pink-600",
              else: "bg-white text-gray-600 border-gray-300 hover:border-gray-400"
            )
          ]}
        >
          {label}
        </button>
      <% end %>
    </div>

    <!-- Stat cards row -->
    <div class="grid grid-cols-2 lg:grid-cols-4 gap-4 mb-6">
      <.analytics_card
        title="Nouveaux utilisateurs"
        value={@data.users.new_in_range}
        sub={"#{@data.users.total} au total"}
        trend={@data.users.growth_pct}
        icon="hero-user-plus"
        color="pink"
      />
      <.analytics_card
        title="Nouveaux posts"
        value={@data.posts.new_in_range}
        sub={"#{@data.posts.total} au total"}
        icon="hero-document-text"
        color="blue"
      />
      <.analytics_card
        title="Messages envoyés"
        value={@data.engagement.messages}
        sub="dans la période"
        icon="hero-chat-bubble-left-right"
        color="purple"
      />
      <.analytics_card
        title="Candidatures dates"
        value={@data.dates.applications}
        sub={"#{@data.dates.acceptance_rate}% acceptées"}
        icon="hero-heart"
        color="rose"
      />
    </div>

    <!-- Charts row -->
    <div class="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-6">
      <!-- Registrations line chart -->
      <div class="bg-white rounded-xl border border-gray-200 p-5">
        <h3 class="text-sm font-semibold text-gray-700 mb-4">Inscriptions par jour</h3>
        <.line_chart points={@data.chart.registrations} color="#ec4899" />
      </div>

      <!-- Posts bar chart -->
      <div class="bg-white rounded-xl border border-gray-200 p-5">
        <h3 class="text-sm font-semibold text-gray-700 mb-4">Posts créés par jour</h3>
        <.bar_chart points={@data.chart.posts} color="#3b82f6" />
      </div>
    </div>

    <!-- Bottom row -->
    <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
      <!-- User breakdown -->
      <div class="bg-white rounded-xl border border-gray-200 p-5">
        <h3 class="text-sm font-semibold text-gray-700 mb-4">Utilisateurs</h3>
        <div class="space-y-3">
          <.stat_row label="Total" value={@data.users.total} />
          <.stat_row label="Actifs dans la période" value={@data.users.active} />
          <.stat_row label="En attente de suppression" value={@data.users.pending_deletion} color="red" />
          <.stat_row label="Amitiés créées" value={@data.users.friends_created} />
        </div>
        <div class="mt-4 pt-4 border-t border-gray-100">
          <p class="text-xs text-gray-500 mb-2 font-medium">Par rôle</p>
          <%= for {role, count} <- Enum.sort(@data.users.by_role) do %>
            <div class="flex justify-between text-sm py-0.5">
              <span class="text-gray-600 capitalize">{role}</span>
              <span class="font-semibold text-gray-900">{count}</span>
            </div>
          <% end %>
        </div>
      </div>

      <!-- Posts breakdown -->
      <div class="bg-white rounded-xl border border-gray-200 p-5">
        <h3 class="text-sm font-semibold text-gray-700 mb-4">Contenu</h3>
        <div class="space-y-3">
          <.stat_row label="Posts standard" value={@data.posts.standard} />
          <.stat_row label="Posts date" value={@data.posts.date_posts} />
          <.stat_row label="Commentaires" value={@data.posts.comments_in_range} />
          <.stat_row label="Réactions" value={@data.posts.reactions_in_range} />
        </div>
        <div class="mt-4 pt-4 border-t border-gray-100">
          <p class="text-xs text-gray-500 mb-2 font-medium">Visibilité des posts</p>
          <%= for {vis, count} <- Enum.sort(@data.posts.by_visibility) do %>
            <div class="flex justify-between text-sm py-0.5">
              <span class="text-gray-600 capitalize">{vis || "—"}</span>
              <span class="font-semibold text-gray-900">{count}</span>
            </div>
          <% end %>
        </div>
      </div>

      <!-- Dates breakdown -->
      <div class="bg-white rounded-xl border border-gray-200 p-5">
        <h3 class="text-sm font-semibold text-gray-700 mb-4">Dates</h3>
        <div class="space-y-3">
          <.stat_row label="Total dates" value={@data.dates.total} />
          <.stat_row label="Candidatures" value={@data.dates.applications} />
          <.stat_row label="Acceptées" value={@data.dates.accepted} color="green" />
          <div class="flex justify-between text-sm">
            <span class="text-gray-600">Taux d'acceptation</span>
            <span class="font-bold text-pink-600">{@data.dates.acceptance_rate}%</span>
          </div>
        </div>
        <div :if={@data.dates.top_categories != []} class="mt-4 pt-4 border-t border-gray-100">
          <p class="text-xs text-gray-500 mb-2 font-medium">Top catégories</p>
          <%= for {cat, count} <- @data.dates.top_categories do %>
            <div class="flex justify-between text-sm py-0.5">
              <span class="text-gray-600 truncate">{cat}</span>
              <span class="font-semibold text-gray-900 ml-2">{count}</span>
            </div>
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  # ── Stat card component ──────────────────────────────────────────────────────

  attr :title, :string, required: true
  attr :value, :integer, required: true
  attr :sub, :string, default: nil
  attr :trend, :integer, default: nil
  attr :icon, :string, required: true
  attr :color, :string, default: "gray"

  defp analytics_card(assigns) do
    ~H"""
    <div class="bg-white rounded-xl border border-gray-200 p-5">
      <div class="flex items-start justify-between mb-3">
        <div class={["w-10 h-10 rounded-lg flex items-center justify-center", icon_bg(@color)]}>
          <.icon name={@icon} class={["w-5 h-5", icon_color(@color)]} />
        </div>
        <span :if={@trend} class={["text-xs font-semibold px-2 py-0.5 rounded-full", trend_class(@trend)]}>
          {if @trend > 0, do: "+", else: ""}{@trend}%
        </span>
      </div>
      <p class="text-2xl font-bold text-gray-900">{@value}</p>
      <p class="text-xs text-gray-500 mt-0.5">{@title}</p>
      <p :if={@sub} class="text-xs text-gray-400 mt-0.5">{@sub}</p>
    </div>
    """
  end

  defp icon_bg("pink"), do: "bg-pink-50"
  defp icon_bg("blue"), do: "bg-blue-50"
  defp icon_bg("purple"), do: "bg-purple-50"
  defp icon_bg("rose"), do: "bg-rose-50"
  defp icon_bg(_), do: "bg-gray-100"

  defp icon_color("pink"), do: "text-pink-600"
  defp icon_color("blue"), do: "text-blue-600"
  defp icon_color("purple"), do: "text-purple-600"
  defp icon_color("rose"), do: "text-rose-500"
  defp icon_color(_), do: "text-gray-600"

  defp trend_class(t) when t > 0, do: "bg-green-50 text-green-700"
  defp trend_class(t) when t < 0, do: "bg-red-50 text-red-700"
  defp trend_class(_), do: "bg-gray-100 text-gray-600"

  # ── Stat row ────────────────────────────────────────────────────────────────

  attr :label, :string, required: true
  attr :value, :integer, required: true
  attr :color, :string, default: "default"

  defp stat_row(assigns) do
    ~H"""
    <div class="flex justify-between text-sm">
      <span class="text-gray-600">{@label}</span>
      <span class={["font-semibold", stat_value_color(@color)]}>{@value}</span>
    </div>
    """
  end

  defp stat_value_color("red"), do: "text-red-600"
  defp stat_value_color("green"), do: "text-green-600"
  defp stat_value_color(_), do: "text-gray-900"

  # ── SVG Line Chart ───────────────────────────────────────────────────────────

  attr :points, :list, required: true
  attr :color, :string, default: "#ec4899"

  defp line_chart(assigns) do
    assigns = assign(assigns, :chart_data, build_line_chart(assigns.points))
    ~H"""
    <div class="w-full">
      <%= if @chart_data.empty do %>
        <div class="h-32 flex items-center justify-center text-gray-300 text-sm">Pas de données</div>
      <% else %>
        <svg viewBox={"0 0 #{@chart_data.width} #{@chart_data.height}"} class="w-full h-40" preserveAspectRatio="none">
          <!-- Grid lines -->
          <%= for y <- @chart_data.grid_ys do %>
            <line x1="0" y1={y} x2={@chart_data.width} y2={y} stroke="#f3f4f6" stroke-width="1" />
          <% end %>
          <!-- Area fill -->
          <path d={@chart_data.area_path} fill={@color} fill-opacity="0.08" />
          <!-- Line -->
          <path d={@chart_data.line_path} fill="none" stroke={@color} stroke-width="2" stroke-linecap="round" stroke-linejoin="round" />
          <!-- Dots for last point -->
          <circle cx={@chart_data.last_x} cy={@chart_data.last_y} r="3" fill={@color} />
        </svg>
        <!-- X axis labels (first and last date) -->
        <div class="flex justify-between mt-1 text-xs text-gray-400">
          <span>{@chart_data.first_label}</span>
          <span class="font-medium text-gray-600">{@chart_data.max_label}</span>
          <span>{@chart_data.last_label}</span>
        </div>
      <% end %>
    </div>
    """
  end

  defp build_line_chart([]) do
    %{empty: true}
  end

  defp build_line_chart(points) do
    width = 400
    height = 120
    padding_x = 0
    padding_top = 10
    padding_bottom = 20

    counts = Enum.map(points, & &1.count)
    max_val = Enum.max(counts, fn -> 1 end)
    max_val = if max_val == 0, do: 1.0, else: max_val * 1.0
    n = length(points)
    chart_h = (height - padding_top - padding_bottom) * 1.0

    coords =
      points
      |> Enum.with_index()
      |> Enum.map(fn {p, i} ->
        x = padding_x + i / max(n - 1, 1) * (width - 2 * padding_x) * 1.0
        y = padding_top + (1 - p.count * 1.0 / max_val) * chart_h
        {x, y, p}
      end)

    line_path =
      coords
      |> Enum.with_index()
      |> Enum.map(fn {{x, y, _}, idx} ->
        if idx == 0, do: "M #{Float.round(x, 1)} #{Float.round(y, 1)}", else: "L #{Float.round(x, 1)} #{Float.round(y, 1)}"
      end)
      |> Enum.join(" ")

    # area path: go down to bottom right, then bottom left, close
    {last_x, _last_y, _} = List.last(coords)
    {first_x, _first_y, _} = List.first(coords)
    bottom_y = (height - padding_bottom) * 1.0

    area_path =
      line_path <>
        " L #{Float.round(last_x, 1)} #{Float.round(bottom_y, 1)} L #{Float.round(first_x, 1)} #{Float.round(bottom_y, 1)} Z"

    {last_cx, last_cy, _} = List.last(coords)

    grid_ys = [padding_top * 1.0, padding_top + chart_h / 2, bottom_y]

    max_idx = Enum.find_index(counts, &(&1 == max_val)) || 0
    max_label = "max: #{max_val}"

    %{
      empty: false,
      width: width,
      height: height,
      line_path: line_path,
      area_path: area_path,
      last_x: Float.round(last_cx, 1),
      last_y: Float.round(last_cy, 1),
      grid_ys: grid_ys,
      first_label: points |> List.first() |> Map.get(:date) |> format_chart_date(),
      last_label: points |> List.last() |> Map.get(:date) |> format_chart_date(),
      max_label: max_label,
      _max_idx: max_idx
    }
  end

  # ── SVG Bar Chart ────────────────────────────────────────────────────────────

  attr :points, :list, required: true
  attr :color, :string, default: "#3b82f6"

  defp bar_chart(assigns) do
    assigns = assign(assigns, :chart_data, build_bar_chart(assigns.points, assigns.color))
    ~H"""
    <div class="w-full">
      <%= if @chart_data.empty do %>
        <div class="h-32 flex items-center justify-center text-gray-300 text-sm">Pas de données</div>
      <% else %>
        <svg viewBox={"0 0 #{@chart_data.width} #{@chart_data.height}"} class="w-full h-40" preserveAspectRatio="none">
          <!-- Grid lines -->
          <%= for y <- @chart_data.grid_ys do %>
            <line x1="0" y1={y} x2={@chart_data.width} y2={y} stroke="#f3f4f6" stroke-width="1" />
          <% end %>
          <!-- Bars -->
          <%= for bar <- @chart_data.bars do %>
            <rect x={bar.x} y={bar.y} width={bar.w} height={bar.h} fill={@color} rx="2" fill-opacity="0.85" />
          <% end %>
        </svg>
        <div class="flex justify-between mt-1 text-xs text-gray-400">
          <span>{@chart_data.first_label}</span>
          <span class="font-medium text-gray-600">{@chart_data.max_label}</span>
          <span>{@chart_data.last_label}</span>
        </div>
      <% end %>
    </div>
    """
  end

  defp build_bar_chart([], _color), do: %{empty: true}

  defp build_bar_chart(points, _color) do
    width = 400
    height = 120
    padding_top = 10
    padding_bottom = 20
    gap = 1

    counts = Enum.map(points, & &1.count)
    max_val = Enum.max(counts, fn -> 1 end)
    max_val = if max_val == 0, do: 1.0, else: max_val * 1.0
    n = length(points)
    bar_w = max((width - gap * (n - 1)) / n, 1.0)
    chart_h = (height - padding_top - padding_bottom) * 1.0

    bars =
      counts
      |> Enum.with_index()
      |> Enum.map(fn {count, i} ->
        bar_h = max(count * 1.0 / max_val * chart_h, 1.0)
        x = i * (bar_w + gap)
        y = padding_top + chart_h - bar_h
        %{x: Float.round(x, 1), y: Float.round(y, 1), w: Float.round(bar_w, 1), h: Float.round(bar_h, 1)}
      end)

    grid_ys = [padding_top * 1.0, padding_top + chart_h / 2, (height - padding_bottom) * 1.0]

    %{
      empty: false,
      width: width,
      height: height,
      bars: bars,
      grid_ys: grid_ys,
      first_label: points |> List.first() |> Map.get(:date) |> format_chart_date(),
      last_label: points |> List.last() |> Map.get(:date) |> format_chart_date(),
      max_label: "max: #{max_val}"
    }
  end

  # ── Helpers ─────────────────────────────────────────────────────────────────

  defp load_analytics(socket) do
    data = Admin.analytics_data(socket.assigns.range_days)
    assign(socket, :data, data)
  end

  defp format_chart_date(nil), do: ""
  defp format_chart_date(%Date{} = d), do: Calendar.strftime(d, "%d/%m")
  defp format_chart_date(_), do: ""
end
