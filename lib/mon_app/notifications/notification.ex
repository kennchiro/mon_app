defmodule MonApp.Notifications.Notification do
  use Ecto.Schema
  import Ecto.Changeset

  alias MonApp.Accounts.User
  alias MonApp.Blog.Post
  alias MonApp.Blog.Comment

  schema "notifications" do
    field :type, :string
    field :message, :string
    field :read, :boolean, default: false

    belongs_to :user, User
    belongs_to :actor, User
    belongs_to :post, Post
    belongs_to :comment, Comment

    timestamps()
  end

  def changeset(notification, attrs) do
    notification
    |> cast(attrs, [:type, :message, :read, :user_id, :actor_id, :post_id, :comment_id])
    |> validate_required([:type, :message, :user_id, :actor_id])
    |> validate_inclusion(:type, ["comment", "reply", "reaction", "friend_request"])
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:actor_id)
    |> foreign_key_constraint(:post_id)
    |> foreign_key_constraint(:comment_id)
  end
end
