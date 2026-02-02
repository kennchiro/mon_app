defmodule MonApp.Blog.Comment do
  use Ecto.Schema
  import Ecto.Changeset

  alias MonApp.Accounts.User
  alias MonApp.Blog.Post
  alias MonApp.Blog.CommentReaction
  alias MonApp.Blog.CommentImage

  schema "comments" do
    field :body, :string

    belongs_to :user, User
    belongs_to :post, Post
    belongs_to :parent, __MODULE__
    has_many :replies, __MODULE__, foreign_key: :parent_id, on_delete: :delete_all
    has_many :reactions, CommentReaction, on_delete: :delete_all
    has_many :images, CommentImage, on_delete: :delete_all

    timestamps()
  end

  def changeset(comment, attrs) do
    comment
    |> cast(attrs, [:body, :user_id, :post_id, :parent_id])
    |> validate_required([:user_id, :post_id])
    |> validate_length(:body, max: 2000)
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:post_id)
    |> foreign_key_constraint(:parent_id)
  end
end
