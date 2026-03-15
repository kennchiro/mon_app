defmodule MonApp.Blog.DateApplication do
  use Ecto.Schema
  import Ecto.Changeset

  alias MonApp.Accounts.User
  alias MonApp.Blog.Post

  @statuses ["pending", "accepted", "rejected"]

  schema "date_applications" do
    field :message, :string
    field :status, :string, default: "pending"

    belongs_to :user, User
    belongs_to :post, Post

    timestamps()
  end

  def changeset(application, attrs) do
    application
    |> cast(attrs, [:message, :status, :user_id, :post_id])
    |> validate_required([:user_id, :post_id])
    |> validate_inclusion(:status, @statuses)
    |> validate_length(:message, max: 500)
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:post_id)
    |> unique_constraint([:user_id, :post_id])
  end

  def statuses, do: @statuses
end
