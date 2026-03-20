defmodule MonApp.Admin do
  @moduledoc "Contexte Admin : audit logs et statistiques globales"

  import Ecto.Query
  alias MonApp.Repo
  alias MonApp.Admin.AuditLog
  alias MonApp.Accounts.User

  # ============== AUDIT LOGS ==============

  @doc "Enregistre une action admin"
  def log_action(admin_id, action, opts \\ []) do
    %AuditLog{}
    |> AuditLog.changeset(%{
      admin_id: admin_id,
      action: action,
      target_type: Keyword.get(opts, :target_type),
      target_id: Keyword.get(opts, :target_id),
      metadata: Keyword.get(opts, :metadata, %{}),
      ip_address: Keyword.get(opts, :ip_address)
    })
    |> Repo.insert()
  end

  @doc "Récupère les derniers logs d'audit"
  def list_audit_logs(limit \\ 50) do
    from(l in AuditLog,
      preload: [:admin],
      order_by: [desc: l.inserted_at],
      limit: ^limit
    )
    |> Repo.all()
  end

  @doc "Récupère les logs d'un admin"
  def list_audit_logs_for_admin(admin_id, limit \\ 50) do
    from(l in AuditLog,
      where: l.admin_id == ^admin_id,
      order_by: [desc: l.inserted_at],
      limit: ^limit
    )
    |> Repo.all()
  end

  # ============== STATS GLOBALES ==============

  @doc "Retourne les métriques globales pour le dashboard"
  def dashboard_stats do
    now = NaiveDateTime.utc_now()
    today_start = %{now | hour: 0, minute: 0, second: 0, microsecond: {0, 0}}
    week_start = NaiveDateTime.add(today_start, -7 * 86400)
    month_start = NaiveDateTime.add(today_start, -30 * 86400)

    %{
      users: %{
        total: user_count(),
        new_today: count_since(User, today_start),
        new_week: count_since(User, week_start),
        new_month: count_since(User, month_start)
      },
      posts: post_stats(today_start, week_start),
      reports: report_stats(),
      registrations_chart: registrations_last_30_days()
    }
  end

  # ============== ANALYTICS ==============

  @doc "Données complètes pour la page Analytics"
  def analytics_data(range_days \\ 30) do
    now = NaiveDateTime.utc_now()
    since = NaiveDateTime.add(now, -range_days * 86400)

    %{
      users: users_analytics(since, range_days),
      posts: posts_analytics(since, range_days),
      engagement: engagement_analytics(since),
      dates: dates_analytics(),
      chart: %{
        registrations: daily_counts(User, since, range_days),
        posts: daily_post_counts(since, range_days)
      }
    }
  end

  defp users_analytics(since, range_days) do
    alias MonApp.Blog.Post
    alias MonApp.Social.Friendship

    total = Repo.aggregate(User, :count, :id)
    new_in_range = from(u in User, where: u.inserted_at >= ^since) |> Repo.aggregate(:count, :id)
    pending_deletion = from(u in User, where: not is_nil(u.scheduled_deletion_at)) |> Repo.aggregate(:count, :id)

    # Actifs = users ayant créé un post dans la période
    active = from(p in Post,
      where: p.inserted_at >= ^since,
      select: count(p.user_id, :distinct)
    ) |> Repo.one()

    # Croissance vs période précédente
    prev_since = NaiveDateTime.add(since, -range_days * 86400)
    prev_count = from(u in User, where: u.inserted_at >= ^prev_since and u.inserted_at < ^since) |> Repo.aggregate(:count, :id)
    growth_pct = if prev_count > 0, do: round((new_in_range - prev_count) / prev_count * 100), else: 0

    by_role = from(u in User, group_by: u.role, select: {u.role, count(u.id)}) |> Repo.all() |> Map.new()
    friends_created = from(f in Friendship, where: f.inserted_at >= ^since and f.status == "accepted") |> Repo.aggregate(:count, :id)

    %{total: total, new_in_range: new_in_range, active: active || 0,
      pending_deletion: pending_deletion, growth_pct: growth_pct,
      by_role: by_role, friends_created: friends_created}
  end

  defp posts_analytics(since, _range_days) do
    alias MonApp.Blog.Post
    alias MonApp.Blog.Comment
    alias MonApp.Blog.Reaction

    total = Repo.aggregate(Post, :count, :id)
    new_in_range = from(p in Post, where: p.inserted_at >= ^since) |> Repo.aggregate(:count, :id)
    standard = from(p in Post, where: p.post_type == "standard") |> Repo.aggregate(:count, :id)
    date_posts = from(p in Post, where: p.post_type == "date") |> Repo.aggregate(:count, :id)
    comments_in_range = from(c in Comment, where: c.inserted_at >= ^since) |> Repo.aggregate(:count, :id)
    reactions_in_range = from(r in Reaction, where: r.inserted_at >= ^since) |> Repo.aggregate(:count, :id)

    by_visibility = from(p in Post,
      group_by: p.visibility,
      select: {p.visibility, count(p.id)}
    ) |> Repo.all() |> Map.new()

    %{total: total, new_in_range: new_in_range, standard: standard,
      date_posts: date_posts, comments_in_range: comments_in_range,
      reactions_in_range: reactions_in_range, by_visibility: by_visibility}
  end

  defp engagement_analytics(since) do
    alias MonApp.Chat.Message
    alias MonApp.Blog.Comment

    messages = from(m in Message, where: m.inserted_at >= ^since and is_nil(m.deleted_for_all_at)) |> Repo.aggregate(:count, :id)
    comments = from(c in Comment, where: c.inserted_at >= ^since) |> Repo.aggregate(:count, :id)

    %{messages: messages, comments: comments}
  end

  defp dates_analytics do
    alias MonApp.Blog.Post
    alias MonApp.Blog.DateApplication

    total_dates = from(p in Post, where: p.post_type == "date") |> Repo.aggregate(:count, :id)
    total_applications = Repo.aggregate(DateApplication, :count, :id)
    accepted = from(a in DateApplication, where: a.status == "accepted") |> Repo.aggregate(:count, :id)
    acceptance_rate = if total_applications > 0, do: round(accepted / total_applications * 100), else: 0

    by_status = from(p in Post,
      where: p.post_type == "date",
      group_by: p.date_status,
      select: {p.date_status, count(p.id)}
    ) |> Repo.all() |> Map.new()

    by_category = from(p in Post,
      where: p.post_type == "date" and not is_nil(p.date_category),
      group_by: p.date_category,
      select: {p.date_category, count(p.id)},
      order_by: [desc: count(p.id)],
      limit: 5
    ) |> Repo.all()

    %{total: total_dates, applications: total_applications, accepted: accepted,
      acceptance_rate: acceptance_rate, by_status: by_status, top_categories: by_category}
  end

  defp daily_counts(schema, since, range_days) do
    raw = from(s in schema,
      where: s.inserted_at >= ^since,
      group_by: fragment("DATE(inserted_at)"),
      select: {fragment("DATE(inserted_at)"), count(s.id)},
      order_by: fragment("DATE(inserted_at)")
    )
    |> Repo.all()
    |> Map.new()

    fill_daily_series(raw, since, range_days)
  end

  defp daily_post_counts(since, range_days) do
    alias MonApp.Blog.Post

    raw = from(p in Post,
      where: p.inserted_at >= ^since,
      group_by: fragment("DATE(inserted_at)"),
      select: {fragment("DATE(inserted_at)"), count(p.id)},
      order_by: fragment("DATE(inserted_at)")
    )
    |> Repo.all()
    |> Map.new()

    fill_daily_series(raw, since, range_days)
  end

  defp fill_daily_series(raw_map, since, range_days) do
    start_date = NaiveDateTime.to_date(since)
    today = Date.utc_today()

    Enum.map(0..(range_days - 1), fn offset ->
      date = Date.add(start_date, offset)
      if Date.compare(date, today) != :gt do
        count = Map.get(raw_map, date, 0)
        %{date: date, count: count}
      end
    end)
    |> Enum.reject(&is_nil/1)
  end

  # ============== PRIVATE ==============

  defp user_count, do: Repo.aggregate(User, :count, :id)

  defp count_since(schema, datetime) do
    from(s in schema, where: s.inserted_at >= ^datetime)
    |> Repo.aggregate(:count, :id)
  end

  defp post_stats(today_start, week_start) do
    alias MonApp.Blog.Post

    %{
      total: Repo.aggregate(Post, :count, :id),
      new_today: count_since(Post, today_start),
      new_week: count_since(Post, week_start),
      date_posts: from(p in Post, where: p.post_type == "date") |> Repo.aggregate(:count, :id)
    }
  end

  defp report_stats do
    alias MonApp.Social.UserReport

    %{
      total: Repo.aggregate(UserReport, :count, :id),
      pending: from(r in UserReport, where: r.status == "pending") |> Repo.aggregate(:count, :id),
      resolved: from(r in UserReport, where: r.status == "resolved") |> Repo.aggregate(:count, :id)
    }
  end

  defp registrations_last_30_days do
    thirty_days_ago = NaiveDateTime.add(NaiveDateTime.utc_now(), -30 * 86400)

    from(u in User,
      where: u.inserted_at >= ^thirty_days_ago,
      group_by: fragment("DATE(inserted_at)"),
      select: {fragment("DATE(inserted_at)"), count(u.id)},
      order_by: fragment("DATE(inserted_at)")
    )
    |> Repo.all()
    |> Enum.map(fn {date, count} -> %{date: date, count: count} end)
  end
end
