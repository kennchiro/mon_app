defmodule MonApp.Blog.Post do
  use Ecto.Schema
  import Ecto.Changeset

  alias MonApp.Accounts.User

  schema "posts" do
    field :title, :string
    field :body, :string
    field :published, :boolean, default: false

    # Relation : un post appartient à un user
    belongs_to :user, User

    timestamps()
  end

  def changeset(post, attrs) do
    post
    |> cast(attrs, [:title, :body, :published, :user_id])
    |> validate_required([:title, :user_id])
    |> validate_length(:title, min: 3, max: 200)
    |> foreign_key_constraint(:user_id)
  end
end
