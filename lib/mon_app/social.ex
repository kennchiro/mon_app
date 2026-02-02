defmodule MonApp.Social do
  @moduledoc """
  Context Social - gère les amis et relations.
  """

  import Ecto.Query
  alias MonApp.Repo
  alias MonApp.Social.Friendship
  alias MonApp.Accounts.User

  # ============== LISTE DES AMIS ==============

  @doc "Récupère tous les amis acceptés d'un user"
  def list_friends(user_id) do
    # Un ami peut être dans user_id OU friend_id (relation bidirectionnelle)
    query =
      from f in Friendship,
        where: f.status == "accepted",
        where: f.user_id == ^user_id or f.friend_id == ^user_id,
        preload: [:user, :friend]

    Repo.all(query)
    |> Enum.map(fn friendship ->
      if friendship.user_id == user_id do
        friendship.friend
      else
        friendship.user
      end
    end)
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
    # IDs des amis (acceptés ou en attente)
    friend_ids =
      from(f in Friendship,
        where: f.user_id == ^user_id or f.friend_id == ^user_id,
        select: fragment("CASE WHEN ? = ? THEN ? ELSE ? END",
          f.user_id, ^user_id, f.friend_id, f.user_id)
      )
      |> Repo.all()

    # Tous les users sauf soi-même et les amis
    from(u in User,
      where: u.id != ^user_id,
      where: u.id not in ^friend_ids,
      order_by: u.name
    )
    |> Repo.all()
  end

  # ============== ACTIONS ==============

  @doc "Envoie une demande d'ami"
  def send_friend_request(user_id, friend_id) do
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
end
