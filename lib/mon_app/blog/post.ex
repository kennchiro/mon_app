defmodule MonApp.Blog.Post do
  use Ecto.Schema
  import Ecto.Changeset

  alias MonApp.Accounts.User
  alias MonApp.Blog.PostImage
  alias MonApp.Blog.Comment
  alias MonApp.Blog.Reaction

  @visibility_options ["public", "friends", "private"]

  schema "posts" do
    field :title, :string
    field :body, :string
    field :published, :boolean, default: false
    field :visibility, :string, default: "public"  # public, friends, private

    belongs_to :user, User
    has_many :images, PostImage, on_delete: :delete_all
    has_many :comments, Comment, on_delete: :delete_all
    has_many :reactions, Reaction, on_delete: :delete_all

    timestamps()
  end

  def changeset(post, attrs) do
    post
    |> cast(attrs, [:title, :body, :published, :user_id, :visibility])
    |> validate_required([:title, :user_id])
    |> validate_length(:title, min: 3, max: 200)
    |> validate_inclusion(:visibility, @visibility_options)
    |> foreign_key_constraint(:user_id)
  end

  def visibility_options, do: @visibility_options

  def visibility_label("public"), do: "Public"
  def visibility_label("friends"), do: "Amis"
  def visibility_label("private"), do: "Moi uniquement"
  def visibility_label(_), do: "Public"
end
