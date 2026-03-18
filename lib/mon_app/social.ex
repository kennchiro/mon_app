defmodule MonApp.Social do
  @moduledoc """
  Context Social - gère les amis et relations.
  """

  import Ecto.Query
  alias MonApp.Repo
  alias MonApp.Social.Friendship
  alias MonApp.Social.UserBlock
  alias MonApp.Social.UserReport
  alias MonApp.Accounts.User

  # ============== LISTE DES AMIS ==============

  @doc "Récupère tous les amis acceptés d'un user"
  def list_friends(user_id) do
    # Single query: get friend IDs then batch load users
    friend_ids =
      from(f in Friendship,
        where: f.status == "accepted",
        where: f.user_id == ^user_id or f.friend_id == ^user_id,
        select: fragment("CASE WHEN ? = ? THEN ? ELSE ? END",
          f.user_id, ^user_id, f.friend_id, f.user_id)
      )
      |> Repo.all()

    from(u in User, where: u.id in ^friend_ids, order_by: u.name)
    |> Repo.all()
  end

  @doc "Récupère les demandes d'amis en attente (reçues)"
  def list_pending_requests(user_id) do
    from(f in Friendship,
      where: f.friend_id == ^user_id and f.status == "pending",
      preload: [:user]
    )
    |> Repo.all()
  end

  @doc "Récupère les demandes envoyées en attente"
  def list_sent_requests(user_id) do
    from(f in Friendship,
      where: f.user_id == ^user_id and f.status == "pending",
      preload: [:friend]
    )
    |> Repo.all()
  end

  # ============== LISTE DES NON-AMIS ==============

  @doc "Récupère tous les users qui ne sont pas amis avec user_id"
  def list_non_friends(user_id) do
    non_friends_query(user_id)
    |> Repo.all()
  end

  def list_non_friends_paginated(user_id, page, per_page \\ 20) do
    offset = (page - 1) * per_page

    users =
      non_friends_query(user_id)
      |> limit(^(per_page + 1))
      |> offset(^offset)
      |> Repo.all()

    has_more = length(users) > per_page
    {Enum.take(users, per_page), has_more}
  end

  def search_non_friends(user_id, query) when is_binary(query) and query != "" do
    search = "%#{query}%"

    non_friends_query(user_id)
    |> where([u], ilike(u.name, ^search) or ilike(u.email, ^search))
    |> limit(20)
    |> Repo.all()
  end

  def search_non_friends(_user_id, _query), do: []

  defp non_friends_query(user_id) do
    # IDs des amis (acceptés ou en attente)
    friend_ids =
      from(f in Friendship,
        where: f.user_id == ^user_id or f.friend_id == ^user_id,
        select: fragment("CASE WHEN ? = ? THEN ? ELSE ? END",
          f.user_id, ^user_id, f.friend_id, f.user_id)
      )
      |> Repo.all()

    # IDs des utilisateurs bloqués (dans les deux sens)
    blocked_ids = list_blocked_ids(user_id)

    # Tous les users sauf soi-même, amis et bloqués
    from(u in User,
      where: u.id != ^user_id,
      where: u.id not in ^friend_ids,
      where: u.id not in ^blocked_ids,
      order_by: u.name
    )
  end

  # ============== ACTIONS ==============

  @daily_request_limit 20

  @doc "Compte les demandes envoyées aujourd'hui par un utilisateur"
  def count_today_requests(user_id) do
    today = Date.utc_today()
    start_of_day = NaiveDateTime.new!(today, ~T[00:00:00])

    from(f in Friendship,
      where: f.user_id == ^user_id,
      where: f.inserted_at >= ^start_of_day
    )
    |> Repo.aggregate(:count)
  end

  @doc "Envoie une demande d'ami (max #{@daily_request_limit}/jour)"
  def send_friend_request(user_id, friend_id) do
    # Vérifier la limite journalière
    if count_today_requests(user_id) >= @daily_request_limit do
      {:error, :daily_limit_reached}
    else
      do_send_friend_request(user_id, friend_id)
    end
  end

  defp do_send_friend_request(user_id, friend_id) do
    # Vérifier si une demande existe déjà (dans les deux sens)
    existing =
      from(f in Friendship,
        where: (f.user_id == ^user_id and f.friend_id == ^friend_id) or
               (f.user_id == ^friend_id and f.friend_id == ^user_id)
      )
      |> Repo.one()

    case existing do
      nil ->
        result =
          %Friendship{}
          |> Friendship.changeset(%{user_id: user_id, friend_id: friend_id})
          |> Repo.insert()

        case result do
          {:ok, friendship} ->
            # Notifier le destinataire de la nouvelle demande
            broadcast_friend_event(friend_id, :friend_request_received)
            {:ok, friendship}

          error ->
            error
        end

      %{status: "pending", friend_id: ^user_id} ->
        # L'autre a déjà envoyé une demande, on accepte automatiquement
        accept_friend_request(existing.id, user_id)

      _ ->
        {:error, :already_exists}
    end
  end

  @doc "Accepte une demande d'ami"
  def accept_friend_request(friendship_id, user_id) do
    case Repo.get(Friendship, friendship_id) do
      nil ->
        {:error, :not_found}

      %{friend_id: ^user_id, user_id: requester_id, status: "pending"} = friendship ->
        result =
          friendship
          |> Friendship.changeset(%{status: "accepted"})
          |> Repo.update()

        case result do
          {:ok, updated} ->
            # Notifier les deux parties
            broadcast_friend_event(user_id, :friend_request_updated)
            broadcast_friend_event(requester_id, :friend_request_accepted)
            {:ok, updated}

          error ->
            error
        end

      _ ->
        {:error, :unauthorized}
    end
  end

  @doc "Refuse une demande d'ami"
  def reject_friend_request(friendship_id, user_id) do
    case Repo.get(Friendship, friendship_id) do
      nil ->
        {:error, :not_found}

      %{friend_id: ^user_id, status: "pending"} = friendship ->
        result = Repo.delete(friendship)

        case result do
          {:ok, _} ->
            # Mettre à jour le compteur local
            broadcast_friend_event(user_id, :friend_request_updated)
            result

          error ->
            error
        end

      _ ->
        {:error, :unauthorized}
    end
  end

  @doc "Supprime un ami"
  def remove_friend(user_id, friend_id) do
    from(f in Friendship,
      where: f.status == "accepted",
      where: (f.user_id == ^user_id and f.friend_id == ^friend_id) or
             (f.user_id == ^friend_id and f.friend_id == ^user_id)
    )
    |> Repo.one()
    |> case do
      nil -> {:error, :not_found}
      friendship -> Repo.delete(friendship)
    end
  end

  @doc "Annule une demande envoyée"
  def cancel_friend_request(user_id, friend_id) do
    from(f in Friendship,
      where: f.user_id == ^user_id and f.friend_id == ^friend_id and f.status == "pending"
    )
    |> Repo.one()
    |> case do
      nil -> {:error, :not_found}
      friendship -> Repo.delete(friendship)
    end
  end

  # ============== HELPERS ==============

  @doc "Récupère la relation d'amitié entre deux users"
  def get_friendship(user_id, other_id) do
    from(f in Friendship,
      where: (f.user_id == ^user_id and f.friend_id == ^other_id) or
             (f.user_id == ^other_id and f.friend_id == ^user_id)
    )
    |> Repo.one()
  end

  @doc "Vérifie le statut d'amitié entre deux users"
  def friendship_status(user_id, other_id) do
    from(f in Friendship,
      where: (f.user_id == ^user_id and f.friend_id == ^other_id) or
             (f.user_id == ^other_id and f.friend_id == ^user_id)
    )
    |> Repo.one()
    |> case do
      nil -> :none
      %{status: "accepted"} -> :friends
      %{status: "pending", user_id: ^user_id} -> :request_sent
      %{status: "pending", friend_id: ^user_id} -> :request_received
      _ -> :none
    end
  end

  @doc "Compte le nombre d'amis"
  def count_friends(user_id) do
    from(f in Friendship,
      where: f.status == "accepted",
      where: f.user_id == ^user_id or f.friend_id == ^user_id,
      select: count(f.id)
    )
    |> Repo.one()
  end

  @doc "Compte les demandes en attente"
  def count_pending_requests(user_id) do
    from(f in Friendship,
      where: f.friend_id == ^user_id and f.status == "pending",
      select: count(f.id)
    )
    |> Repo.one()
  end

  # ============== PUBSUB ==============

  defp broadcast_friend_event(user_id, event) do
    Phoenix.PubSub.broadcast(
      MonApp.PubSub,
      "user:#{user_id}",
      {event, user_id}
    )
  end

  # ============== BLOCKS ==============

  def block_user(blocker_id, blocked_id) do
    # Remove friendship if exists
    remove_friend(blocker_id, blocked_id)

    %UserBlock{}
    |> UserBlock.changeset(%{blocker_id: blocker_id, blocked_id: blocked_id})
    |> Repo.insert()
  end

  def unblock_user(blocker_id, blocked_id) do
    case Repo.get_by(UserBlock, blocker_id: blocker_id, blocked_id: blocked_id) do
      nil -> {:error, :not_found}
      block -> Repo.delete(block)
    end
  end

  def blocked?(blocker_id, blocked_id) do
    Repo.exists?(
      from(b in UserBlock,
        where: b.blocker_id == ^blocker_id and b.blocked_id == ^blocked_id
      )
    )
  end

  def blocked_by?(user_id, other_id) do
    blocked?(user_id, other_id) || blocked?(other_id, user_id)
  end

  def list_blocked_users(user_id) do
    from(b in UserBlock,
      where: b.blocker_id == ^user_id,
      join: u in User, on: u.id == b.blocked_id,
      select: u,
      order_by: [desc: b.inserted_at]
    )
    |> Repo.all()
  end

  def list_blocked_ids(user_id) do
    from(b in UserBlock,
      where: b.blocker_id == ^user_id or b.blocked_id == ^user_id,
      select: fragment("CASE WHEN ? = ? THEN ? ELSE ? END",
        b.blocker_id, ^user_id, b.blocked_id, b.blocker_id)
    )
    |> Repo.all()
  end

  # ============== REPORTS ==============

  def report_user(reporter_id, reported_id, reason, details \\ nil) do
    %UserReport{}
    |> UserReport.changeset(%{
      reporter_id: reporter_id,
      reported_id: reported_id,
      reason: reason,
      details: details,
      report_type: "user"
    })
    |> Repo.insert()
  end

  def report_post(reporter_id, post_id, reported_id, reason, report_type \\ "post") do
    %UserReport{}
    |> UserReport.changeset(%{
      reporter_id: reporter_id,
      reported_id: reported_id,
      post_id: post_id,
      reason: reason,
      report_type: report_type
    })
    |> Repo.insert()
  end
end
