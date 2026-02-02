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

  # ============== HELPERS ==============

  @doc "Retourne un changeset vide pour les formulaires"
  def change_user(%User{} = user, attrs \\ %{}) do
    User.changeset(user, attrs)
  end
end
