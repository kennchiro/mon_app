defmodule MonApp.Accounts do
  @moduledoc """
  Le context Accounts - gère tout ce qui concerne les utilisateurs.
  """

  import Ecto.Query
  alias MonApp.Repo
  alias MonApp.Accounts.User

  # ============== READ ==============

  @doc "Récupère tous les users"
  def list_users do
    Repo.all(User)
  end

  @doc "Récupère un user par son ID"
  def get_user(id) do
    Repo.get(User, id)
  end

  @doc "Récupère un user par son ID, lève une erreur si non trouvé"
  def get_user!(id) do
    Repo.get!(User, id)
  end

  @doc "Récupère un user par son email"
  def get_user_by_email(email) do
    Repo.get_by(User, email: email)
  end

  # ============== CREATE ==============

  @doc "Crée un nouveau user"
  def create_user(attrs \\ %{}) do
    %User{}
    |> User.changeset(attrs)
    |> Repo.insert()
  end

  # ============== UPDATE ==============

  @doc "Met à jour un user"
  def update_user(%User{} = user, attrs) do
    user
    |> User.changeset(attrs)
    |> Repo.update()
  end

  # ============== DELETE ==============

  @doc "Supprime un user"
  def delete_user(%User{} = user) do
    Repo.delete(user)
  end

  # ============== AUTH ==============

  @doc "Inscription d'un nouveau user"
  def register_user(attrs \\ %{}) do
    %User{}
    |> User.registration_changeset(attrs)
    |> Repo.insert()
  end

  @doc "Authentifie un user par email/password"
  def authenticate_user(email, password) do
    user = get_user_by_email(email)

    cond do
      user && Bcrypt.verify_pass(password, user.password_hash) ->
        {:ok, user}

      user ->
        {:error, :invalid_password}

      true ->
        # Évite les timing attacks
        Bcrypt.no_user_verify()
        {:error, :user_not_found}
    end
  end

  # ============== AVATAR ==============

  @uploads_dir "priv/static/uploads/avatars"

  @doc "Retourne le répertoire des uploads avatars"
  def avatars_dir, do: @uploads_dir

  @doc "Met à jour l'avatar d'un user"
  def update_avatar(%User{} = user, avatar_filename) do
    # Supprimer l'ancien avatar si existant
    if user.avatar do
      old_path = Path.join(@uploads_dir, user.avatar)
      File.rm(old_path)
    end

    user
    |> User.avatar_changeset(%{avatar: avatar_filename})
    |> Repo.update()
  end

  @doc "Supprime l'avatar d'un user"
  def delete_avatar(%User{} = user) do
    if user.avatar do
      path = Path.join(@uploads_dir, user.avatar)
      File.rm(path)
    end

    user
    |> User.avatar_changeset(%{avatar: nil})
    |> Repo.update()
  end

  # ============== PROFILE ==============

  @doc "Met à jour le profil d'un user"
  def update_profile(%User{} = user, attrs) do
    user
    |> User.profile_changeset(attrs)
    |> Repo.update()
  end

  @doc "Retourne un changeset profil pour les formulaires"
  def change_profile(%User{} = user, attrs \\ %{}) do
    User.profile_changeset(user, attrs)
  end

  # ============== ACCOUNT DELETION ==============

  @deletion_delay_days 30

  @doc "Planifie la suppression du compte dans 30 jours"
  def schedule_deletion(%User{} = user) do
    deletion_date = NaiveDateTime.utc_now() |> NaiveDateTime.add(@deletion_delay_days * 24 * 3600)

    user
    |> User.deletion_changeset(%{scheduled_deletion_at: deletion_date})
    |> Repo.update()
  end

  @doc "Annule la suppression planifiée"
  def cancel_deletion(%User{} = user) do
    user
    |> User.deletion_changeset(%{scheduled_deletion_at: nil})
    |> Repo.update()
  end

  @doc "Vérifie si un compte est en cours de suppression"
  def deletion_scheduled?(%User{scheduled_deletion_at: nil}), do: false
  def deletion_scheduled?(%User{}), do: true

  @doc "Jours restants avant suppression"
  def days_until_deletion(%User{scheduled_deletion_at: nil}), do: nil
  def days_until_deletion(%User{scheduled_deletion_at: date}) do
    diff = NaiveDateTime.diff(date, NaiveDateTime.utc_now(), :second)
    max(0, div(diff, 86400))
  end

  # ============== ADMIN ==============

  @doc "Liste les users avec pagination et filtres"
  def list_users_paginated(page \\ 1, per_page \\ 50, opts \\ []) do
    search = Keyword.get(opts, :search)
    role = Keyword.get(opts, :role)
    sort = Keyword.get(opts, :sort, "newest")

    order =
      case sort do
        "oldest" -> [asc: :inserted_at]
        "name" -> [asc: :name]
        _ -> [desc: :inserted_at]
      end

    query = from u in User, order_by: ^order

    query =
      if search && search != "" do
        term = "%#{search}%"
        from u in query, where: ilike(u.name, ^term) or ilike(u.email, ^term)
      else
        query
      end

    query =
      if role && role != "" do
        from u in query, where: u.role == ^role
      else
        query
      end

    total = Repo.aggregate(query, :count, :id)
    offset = (page - 1) * per_page
    users = Repo.all(from q in query, limit: ^per_page, offset: ^offset)

    %{users: users, total: total, page: page, per_page: per_page, total_pages: ceil(total / per_page)}
  end

  @doc "Change le mot de passe d'un admin"
  def admin_change_password(%User{} = user, new_password) do
    import Ecto.Changeset

    user
    |> cast(%{password: new_password}, [:password])
    |> validate_length(:password, min: 6, max: 100, message: "6 caractères minimum")
    |> then(fn cs ->
      case get_change(cs, :password) do
        nil -> cs
        pwd -> put_change(cs, :password_hash, Bcrypt.hash_pwd_salt(pwd))
      end
    end)
    |> Repo.update()
  end

  @doc "Liste les users avec un rôle admin ou moderator"
  def list_admins do
    from(u in User,
      where: u.role in ["admin", "moderator"],
      order_by: [asc: u.role, asc: u.name]
    )
    |> Repo.all()
  end

  @doc "Change le rôle d'un user"
  def update_user_role(%User{} = user, role) do
    user
    |> User.role_changeset(%{role: role})
    |> Repo.update()
  end

  @doc "Supprime immédiatement un user (admin)"
  def admin_delete_user(%User{} = user) do
    Repo.delete(user)
  end

  @doc "Compte total des users"
  def count_users, do: Repo.aggregate(User, :count, :id)

  @doc "Compte les nouveaux users depuis une date"
  def count_new_users_since(datetime) do
    from(u in User, where: u.inserted_at >= ^datetime)
    |> Repo.aggregate(:count, :id)
  end

  @doc "Compte les users par rôle"
  def count_users_by_role do
    from(u in User, group_by: u.role, select: {u.role, count(u.id)})
    |> Repo.all()
    |> Map.new()
  end

  @doc "Stats agrégées d'un user pour l'admin"
  def get_user_stats(user_id) do
    alias MonApp.Blog.Post
    alias MonApp.Social.Friendship
    alias MonApp.Social.UserReport

    posts_count =
      from(p in Post, where: p.user_id == ^user_id)
      |> Repo.aggregate(:count, :id)

    friends_count =
      from(f in Friendship,
        where: f.status == "accepted",
        where: f.user_id == ^user_id or f.friend_id == ^user_id
      )
      |> Repo.aggregate(:count, :id)

    reports_received =
      from(r in UserReport, where: r.reported_id == ^user_id)
      |> Repo.aggregate(:count, :id)

    reports_sent =
      from(r in UserReport, where: r.reporter_id == ^user_id)
      |> Repo.aggregate(:count, :id)

    %{
      posts: posts_count,
      friends: friends_count,
      reports_received: reports_received,
      reports_sent: reports_sent
    }
  end

  @doc "Reports reçus par un user (pour la fiche admin)"
  def list_reports_against_user(user_id) do
    alias MonApp.Social.UserReport

    from(r in UserReport,
      where: r.reported_id == ^user_id,
      preload: [:reporter, :post],
      order_by: [desc: r.inserted_at]
    )
    |> Repo.all()
  end

  # ============== HELPERS ==============

  @doc "Retourne un changeset vide pour les formulaires"
  def change_user(%User{} = user, attrs \\ %{}) do
    User.changeset(user, attrs)
  end
end
