defmodule MonApp.Blog.CommentReaction do
  use Ecto.Schema
  import Ecto.Changeset

  alias MonApp.Accounts.User
  alias MonApp.Blog.Comment

  @reaction_types ["like", "love", "haha", "wow", "sad", "angry"]

  schema "comment_reactions" do
    field :type, :string

    belongs_to :user, User
    belongs_to :comment, Comment

    timestamps()
  end

  def changeset(reaction, attrs) do
    reaction
    |> cast(attrs, [:type, :user_id, :comment_id])
    |> validate_required([:type, :user_id, :comment_id])
    |> validate_inclusion(:type, @reaction_types)
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:comment_id)
    |> unique_constraint([:user_id, :comment_id], message: "Vous avez déjà réagi à ce commentaire")
  end

  def reaction_types, do: @reaction_types
end
