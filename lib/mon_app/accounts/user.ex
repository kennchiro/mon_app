defmodule MonApp.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  alias MonApp.Blog.Post

  schema "users" do
    field :name, :string
    field :email, :string
    field :age, :integer
    field :password_hash, :string

    # Champ virtuel (pas en DB)
    field :password, :string, virtual: true

    # Relation : un user a plusieurs posts
    has_many :posts, Post

    timestamps()
  end

  @doc "Changeset pour modifier un user (sans password)"
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:name, :email, :age])
    |> validate_required([:name, :email])
    |> validate_format(:email, ~r/@/)
    |> validate_number(:age, greater_than: 0)
    |> unique_constraint(:email)
  end

  @doc "Changeset pour inscription (avec password)"
  def registration_changeset(user, attrs) do
    user
    |> cast(attrs, [:name, :email, :password])
    |> validate_required([:name, :email, :password])
    |> validate_format(:email, ~r/@/)
    |> validate_length(:password, min: 6, max: 100)
    |> unique_constraint(:email)
    |> hash_password()
  end

  # Hash le password avant insertion
  defp hash_password(changeset) do
    case get_change(changeset, :password) do
      nil ->
        changeset

      password ->
        put_change(changeset, :password_hash, Bcrypt.hash_pwd_salt(password))
    end
  end
end
