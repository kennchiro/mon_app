defmodule MonAppWeb.AdminReportShowLive do
  use MonAppWeb, :live_view

  alias MonApp.Social
  alias MonApp.Social.UserReport
  alias MonApp.Accounts
  alias MonApp.Blog
  alias MonApp.Admin

  def mount(%{"id" => id}, _session, socket) do
    report = Social.get_report_admin(id)

    if is_nil(report) do
      {:ok, socket |> put_flash(:error, "Report introuvable") |> redirect(to: "/admin/reports")}
    else
      reported_stats = Accounts.get_user_stats(report.reported_id)
      reported_reports = Accounts.list_reports_against_user(report.reported_id)
      pending_count = Map.get(Social.report_stats_by_status(), "pending", 0)

      {:ok,
       socket
       |> assign(:page_title, "Report ##{report.id}")
       |> assign(:current_path, "/admin/reports")
       |> assign(:pending_reports_count, pending_count)
       |> assign(:report, report)
       |> assign(:reported_stats, reported_stats)
       |> assign(:reported_reports, reported_reports)
       |> assign(:note, "")
       |> assign(:show_delete_user_modal, false)
       |> assign(:show_delete_post_modal, false)}
    end
  end

  # ── Note ──────────────────────────────────────────────
  def handle_event("update_note", %{"note" => note}, socket) do
    {:noreply, assign(socket, :note, note)}
  end

  # ── Résoudre ──────────────────────────────────────────
  def handle_event("resolve", _, socket) do
    note = if socket.assigns.note != "", do: socket.assigns.note, else: nil

    case Social.resolve_report(socket.assigns.report, socket.assigns.current_admin.id, note) do
      {:ok, _} ->
        Admin.log_action(socket.assigns.current_admin.id, "resolve_report",
          target_type: "report", target_id: socket.assigns.report.id
        )
        report = Social.get_report_admin(socket.assigns.report.id)
        {:noreply, socket |> assign(:report, report) |> put_flash(:info, "Report résolu")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Erreur")}
    end
  end

  # ── Rejeter ───────────────────────────────────────────
  def handle_event("dismiss", _, socket) do
    note = if socket.assigns.note != "", do: socket.assigns.note, else: nil

    case Social.dismiss_report(socket.assigns.report, socket.assigns.current_admin.id, note) do
      {:ok, _} ->
        Admin.log_action(socket.assigns.current_admin.id, "dismiss_report",
          target_type: "report", target_id: socket.assigns.report.id
        )
        report = Social.get_report_admin(socket.assigns.report.id)
        {:noreply, socket |> assign(:report, report) |> put_flash(:info, "Report rejeté")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Erreur")}
    end
  end

  # ── Rouvrir ───────────────────────────────────────────
  def handle_event("reopen", _, socket) do
    case Social.reopen_report(socket.assigns.report) do
      {:ok, _} ->
        report = Social.get_report_admin(socket.assigns.report.id)
        {:noreply, socket |> assign(:report, report) |> assign(:note, "") |> put_flash(:info, "Report réouvert")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Erreur")}
    end
  end

  # ── Supprimer le contenu reporté ──────────────────────
  def handle_event("confirm_delete_post", _, socket) do
    {:noreply, assign(socket, :show_delete_post_modal, true)}
  end

  def handle_event("cancel_delete_post", _, socket) do
    {:noreply, assign(socket, :show_delete_post_modal, false)}
  end

  def handle_event("delete_reported_post", _, socket) do
    post = Blog.get_post(socket.assigns.report.post_id)

    if post do
      Blog.admin_delete_post(post)
      Admin.log_action(socket.assigns.current_admin.id, "delete_post_from_report",
        target_type: "post", target_id: post.id
      )
      Social.resolve_report(socket.assigns.report, socket.assigns.current_admin.id, "Post supprimé suite au report")
      report = Social.get_report_admin(socket.assigns.report.id)

      {:noreply,
       socket
       |> assign(:report, report)
       |> assign(:show_delete_post_modal, false)
       |> put_flash(:info, "Post supprimé et report résolu")}
    else
      {:noreply, socket |> assign(:show_delete_post_modal, false) |> put_flash(:error, "Post introuvable")}
    end
  end

  def handle_event("confirm_delete_user", _, socket) do
    {:noreply, assign(socket, :show_delete_user_modal, true)}
  end

  def handle_event("cancel_delete_user", _, socket) do
    {:noreply, assign(socket, :show_delete_user_modal, false)}
  end

  def handle_event("delete_reported_user", _, socket) do
    user = Accounts.get_user(socket.assigns.report.reported_id)

    if user do
      Accounts.admin_delete_user(user)
      Admin.log_action(socket.assigns.current_admin.id, "delete_user_from_report",
        target_type: "user", target_id: user.id, metadata: %{name: user.name}
      )
      {:noreply,
       socket
       |> assign(:show_delete_user_modal, false)
       |> put_flash(:info, "Utilisateur supprimé")
       |> redirect(to: "/admin/reports")}
    else
      {:noreply, socket |> assign(:show_delete_user_modal, false) |> put_flash(:error, "Utilisateur introuvable")}
    end
  end

  def render(assigns) do
    ~H"""
    <!-- Breadcrumb -->
    <div class="flex items-center gap-2 text-sm text-gray-500 mb-6">
      <.link navigate="/admin/reports" class="hover:text-pink-600 transition-colors">Reports</.link>
      <.icon name="hero-chevron-right" class="w-4 h-4" />
      <span class="text-gray-900 font-medium">Report #{@report.id}</span>
    </div>

    <div class="grid grid-cols-1 xl:grid-cols-3 gap-6">
      <!-- Colonne principale -->
      <div class="xl:col-span-2 space-y-6">

        <!-- Détail du report -->
        <div class="bg-white rounded-xl border border-gray-200 p-6">
          <div class="flex items-start gap-4 mb-6">
            <div class={["w-12 h-12 rounded-xl flex items-center justify-center text-2xl shrink-0", type_icon_bg(@report.report_type)]}>
              {type_emoji(@report.report_type)}
            </div>
            <div class="flex-1">
              <div class="flex items-center gap-2 mb-1 flex-wrap">
                <span class={["text-xs px-2 py-0.5 rounded-full font-semibold", type_badge_class(@report.report_type)]}>
                  {String.capitalize(@report.report_type)}
                </span>
                <span class={["text-xs px-2 py-0.5 rounded-full font-medium", status_badge_class(@report.status)]}>
                  {status_label(@report.status)}
                </span>
              </div>
              <h2 class="text-lg font-bold text-gray-900">
                {UserReport.reason_label(@report.reason)}
              </h2>
              <p class="text-sm text-gray-400 mt-0.5">{format_datetime(@report.inserted_at)}</p>
            </div>
          </div>

          <!-- Détails du report -->
          <div :if={@report.details} class="bg-amber-50 border border-amber-200 rounded-lg p-4 mb-6">
            <p class="text-xs font-semibold text-amber-700 mb-1">Détails fournis par le signaleur</p>
            <p class="text-sm text-amber-900 leading-relaxed">"{@report.details}"</p>
          </div>

          <!-- Parties concernées -->
          <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <!-- Signaleur -->
            <div class="border border-gray-200 rounded-lg p-4">
              <p class="text-xs text-gray-400 font-medium mb-2">Signaleur</p>
              <div class="flex items-center gap-3">
                <div class="w-9 h-9 rounded-full bg-blue-100 flex items-center justify-center text-blue-600 font-semibold shrink-0">
                  {String.first(@report.reporter.name) |> String.upcase()}
                </div>
                <div class="min-w-0">
                  <.link navigate={"/admin/users/#{@report.reporter.id}"}
                    class="text-sm font-medium text-gray-900 hover:text-pink-600 transition-colors">
                    {@report.reporter.name}
                  </.link>
                  <p class="text-xs text-gray-400 truncate">{@report.reporter.email}</p>
                </div>
              </div>
            </div>

            <!-- Signalé -->
            <div class="border border-red-100 bg-red-50/30 rounded-lg p-4">
              <p class="text-xs text-red-500 font-medium mb-2">Utilisateur signalé</p>
              <div class="flex items-center gap-3">
                <div class="w-9 h-9 rounded-full bg-red-100 flex items-center justify-center text-red-600 font-semibold shrink-0">
                  {String.first(@report.reported.name) |> String.upcase()}
                </div>
                <div class="min-w-0">
                  <.link navigate={"/admin/users/#{@report.reported.id}"}
                    class="text-sm font-medium text-gray-900 hover:text-pink-600 transition-colors">
                    {@report.reported.name}
                  </.link>
                  <p class="text-xs text-gray-400 truncate">{@report.reported.email}</p>
                </div>
              </div>
              <div class="mt-3 flex gap-3 text-xs text-gray-600">
                <span><span class="font-medium">{@reported_stats.posts}</span> posts</span>
                <span><span class="font-medium text-red-600">{@reported_stats.reports_received}</span> reports reçus</span>
              </div>
            </div>
          </div>

          <!-- Post signalé si applicable -->
          <div :if={@report.post} class="mt-4 border border-gray-200 rounded-lg p-4">
            <p class="text-xs text-gray-400 font-medium mb-2">Contenu signalé</p>
            <div class="flex items-start justify-between gap-3">
              <div class="flex-1 min-w-0">
                <.link navigate={"/admin/posts/#{@report.post.id}"}
                  class="text-sm font-medium text-gray-900 hover:text-pink-600 transition-colors">
                  {post_title(@report.post)}
                </.link>
                <p :if={@report.post.body} class="text-xs text-gray-500 mt-1 line-clamp-2">{@report.post.body}</p>
              </div>
              <button
                phx-click="confirm_delete_post"
                class="shrink-0 px-3 py-1.5 text-xs text-red-700 bg-red-50 border border-red-200 rounded-lg hover:bg-red-100 transition-colors font-medium">
                Supprimer le post
              </button>
            </div>
          </div>

          <!-- Résolution existante -->
          <div :if={@report.status != "pending"} class="mt-4 bg-gray-50 rounded-lg p-4 border border-gray-200">
            <p class="text-xs text-gray-400 font-medium mb-1">Résolution</p>
            <p class="text-sm text-gray-700">
              <span class="font-medium">{if @report.resolved_by, do: @report.resolved_by.name, else: "Admin"}</span>
              · {format_datetime(@report.resolved_at)}
            </p>
            <p :if={@report.resolution_note} class="text-sm text-gray-600 italic mt-1">"{@report.resolution_note}"</p>
          </div>
        </div>

        <!-- Historique des autres reports contre cet utilisateur -->
        <div :if={length(@reported_reports) > 1} class="bg-white rounded-xl border border-gray-200 overflow-hidden">
          <div class="px-6 py-4 border-b border-gray-100 flex items-center justify-between">
            <h3 class="font-semibold text-gray-900">Autres reports contre {@report.reported.name}</h3>
            <span class={[
              "text-xs px-2 py-0.5 rounded-full font-medium",
              if(length(@reported_reports) > 3, do: "bg-red-50 text-red-600", else: "bg-gray-100 text-gray-500")
            ]}>
              {length(@reported_reports)} au total
            </span>
          </div>
          <div class="divide-y divide-gray-100">
            <div :for={r <- Enum.take(@reported_reports, 5)} class="px-6 py-3 flex items-center justify-between">
              <div class="flex items-center gap-3">
                <span class={["text-xs px-2 py-0.5 rounded-full font-medium", type_badge_class(r.report_type)]}>
                  {r.report_type}
                </span>
                <span class="text-sm text-gray-700">{UserReport.reason_label(r.reason)}</span>
              </div>
              <div class="flex items-center gap-2">
                <span class={["text-xs px-2 py-0.5 rounded-full", status_badge_class(r.status)]}>
                  {status_label(r.status)}
                </span>
                <.link navigate={"/admin/reports/#{r.id}"} class="text-xs text-pink-600 hover:underline">
                  Voir
                </.link>
              </div>
            </div>
          </div>
        </div>

      </div>

      <!-- Sidebar actions -->
      <div class="space-y-6">

        <!-- Note de résolution -->
        <div class="bg-white rounded-xl border border-gray-200 p-6">
          <h3 class="font-semibold text-gray-900 mb-3">Note (optionnelle)</h3>
          <textarea
            phx-keyup="update_note"
            phx-debounce="300"
            name="note"
            rows="3"
            placeholder="Raison de la décision…"
            class="w-full px-3 py-2 text-sm border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-pink-500 resize-none"
          >{@note}</textarea>
        </div>

        <!-- Actions de modération -->
        <div class="bg-white rounded-xl border border-gray-200 p-6">
          <h3 class="font-semibold text-gray-900 mb-4">Décision</h3>
          <div class="space-y-2">

            <button :if={@report.status == "pending"}
              phx-click="resolve"
              class="w-full flex items-center gap-2 px-4 py-2.5 text-sm bg-green-600 hover:bg-green-700 text-white rounded-lg transition-colors font-medium">
              <.icon name="hero-check-circle" class="w-4 h-4" />
              Résoudre le report
            </button>

            <button :if={@report.status == "pending"}
              phx-click="dismiss"
              class="w-full flex items-center gap-2 px-4 py-2.5 text-sm text-gray-700 bg-gray-50 hover:bg-gray-100 border border-gray-200 rounded-lg transition-colors font-medium">
              <.icon name="hero-x-circle" class="w-4 h-4" />
              Rejeter (non fondé)
            </button>

            <button :if={@report.status != "pending"}
              phx-click="reopen"
              class="w-full flex items-center gap-2 px-4 py-2.5 text-sm text-yellow-700 bg-yellow-50 hover:bg-yellow-100 border border-yellow-200 rounded-lg transition-colors font-medium">
              <.icon name="hero-arrow-uturn-left" class="w-4 h-4" />
              Rouvrir le report
            </button>

          </div>
        </div>

        <!-- Actions sur le contenu -->
        <div class="bg-white rounded-xl border border-red-200 p-6">
          <h3 class="font-semibold text-red-700 mb-4">Actions sur le contenu</h3>
          <div class="space-y-2">

            <.link
              navigate={"/admin/users/#{@report.reported.id}"}
              class="w-full flex items-center gap-2 px-4 py-2.5 text-sm text-gray-700 bg-gray-50 hover:bg-gray-100 border border-gray-200 rounded-lg transition-colors font-medium">
              <.icon name="hero-user" class="w-4 h-4" />
              Voir la fiche utilisateur
            </.link>

            <button :if={@report.post}
              phx-click="confirm_delete_post"
              class="w-full flex items-center gap-2 px-4 py-2.5 text-sm text-orange-700 bg-orange-50 hover:bg-orange-100 border border-orange-200 rounded-lg transition-colors font-medium">
              <.icon name="hero-document-minus" class="w-4 h-4" />
              Supprimer le post signalé
            </button>

            <button
              phx-click="confirm_delete_user"
              class="w-full flex items-center gap-2 px-4 py-2.5 text-sm text-red-700 bg-red-50 hover:bg-red-100 border border-red-200 rounded-lg transition-colors font-medium">
              <.icon name="hero-trash" class="w-4 h-4" />
              Supprimer le compte
            </button>

          </div>
        </div>

      </div>
    </div>

    <!-- Modal suppr post -->
    <div :if={@show_delete_post_modal} class="fixed inset-0 z-50 flex items-center justify-center px-4">
      <div class="absolute inset-0 bg-black/40 backdrop-blur-sm" phx-click="cancel_delete_post" />
      <div class="bg-white rounded-2xl shadow-2xl p-6 max-w-sm w-full relative z-10">
        <h3 class="text-lg font-semibold text-gray-900 text-center mb-2">Supprimer le post signalé ?</h3>
        <p class="text-sm text-gray-500 text-center mb-6">Le report sera automatiquement marqué comme résolu.</p>
        <div class="flex gap-3">
          <button phx-click="cancel_delete_post" class="flex-1 py-2 text-sm border border-gray-300 rounded-lg hover:bg-gray-50 font-medium">Annuler</button>
          <button phx-click="delete_reported_post" class="flex-1 py-2 text-sm bg-red-600 hover:bg-red-700 text-white rounded-lg font-medium">Supprimer</button>
        </div>
      </div>
    </div>

    <!-- Modal suppr user -->
    <div :if={@show_delete_user_modal} class="fixed inset-0 z-50 flex items-center justify-center px-4">
      <div class="absolute inset-0 bg-black/40 backdrop-blur-sm" phx-click="cancel_delete_user" />
      <div class="bg-white rounded-2xl shadow-2xl p-6 max-w-sm w-full relative z-10">
        <div class="w-12 h-12 bg-red-100 rounded-full flex items-center justify-center mx-auto mb-4">
          <.icon name="hero-trash" class="w-6 h-6 text-red-600" />
        </div>
        <h3 class="text-lg font-semibold text-gray-900 text-center mb-2">Supprimer {@report.reported.name} ?</h3>
        <p class="text-sm text-gray-500 text-center mb-6">Action irréversible. Tout le contenu de cet utilisateur sera supprimé.</p>
        <div class="flex gap-3">
          <button phx-click="cancel_delete_user" class="flex-1 py-2 text-sm border border-gray-300 rounded-lg hover:bg-gray-50 font-medium">Annuler</button>
          <button phx-click="delete_reported_user" class="flex-1 py-2 text-sm bg-red-600 hover:bg-red-700 text-white rounded-lg font-medium">Supprimer</button>
        </div>
      </div>
    </div>
    """
  end

  # ── Helpers ───────────────────────────────────────────
  defp format_datetime(nil), do: "—"
  defp format_datetime(dt), do: Calendar.strftime(dt, "%d/%m/%Y à %H:%M")

  defp post_title(%{post_type: "date", date_title: t}) when not is_nil(t), do: t
  defp post_title(%{title: t}) when not is_nil(t), do: t
  defp post_title(_), do: "(sans titre)"

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
end
