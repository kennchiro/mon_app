defmodule MonApp.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  alias MonApp.Blog.Post

  schema "users" do
    field :name, :string
    field :email, :string
    field :age, :integer
    field :password_hash, :string
    field :avatar, :string

    # Dating fields
    field :gender, :string
    field :bio, :string
    field :birthdate, :date
    field :looking_for, :string, default: "any"
    field :interests, {:array, :string}, default: []
    field :location, :string

    # Champ virtuel (pas en DB)
    field :password, :string, virtual: true

    # Relation : un user a plusieurs posts
    has_many :posts, Post

    timestamps()
  end

  @genders ["male", "female", "non_binary", "other"]
  @looking_for_options ["any", "male", "female", "non_binary", "friends"]

  @doc "Changeset pour modifier un user (sans password)"
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:name, :email, :age])
    |> validate_required([:name, :email])
    |> validate_format(:email, ~r/@/)
    |> validate_number(:age, greater_than: 0)
    |> unique_constraint(:email)
  end

  @doc "Changeset pour le profil dating"
  def dating_changeset(user, attrs) do
    user
    |> cast(attrs, [:bio, :gender, :birthdate, :looking_for, :interests, :location])
    |> validate_inclusion(:gender, @genders)
    |> validate_inclusion(:looking_for, @looking_for_options)
    |> validate_length(:bio, max: 500)
    |> validate_length(:location, max: 100)
  end

  def genders, do: @genders
  def looking_for_options, do: @looking_for_options

  def gender_label("male"), do: "Homme"
  def gender_label("female"), do: "Femme"
  def gender_label("non_binary"), do: "Non-binaire"
  def gender_label("other"), do: "Autre"
  def gender_label(_), do: nil

  def looking_for_label("any"), do: "Tout le monde"
  def looking_for_label("male"), do: "Hommes"
  def looking_for_label("female"), do: "Femmes"
  def looking_for_label("non_binary"), do: "Non-binaires"
  def looking_for_label("friends"), do: "Amis uniquement"
  def looking_for_label(_), do: "Tout le monde"

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

  @doc "Changeset pour mettre à jour l'avatar"
  def avatar_changeset(user, attrs) do
    user
    |> cast(attrs, [:avatar])
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
