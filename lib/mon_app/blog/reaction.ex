defmodule MonApp.Blog.Reaction do
  use Ecto.Schema
  import Ecto.Changeset

  alias MonApp.Accounts.User
  alias MonApp.Blog.Post

  @reaction_types ["like", "love", "haha", "wow", "sad", "angry"]

  schema "reactions" do
    field :type, :string

    belongs_to :user, User
    belongs_to :post, Post

    timestamps()
  end

  def changeset(reaction, attrs) do
    reaction
    |> cast(attrs, [:type, :user_id, :post_id])
    |> validate_required([:type, :user_id, :post_id])
    |> validate_inclusion(:type, @reaction_types)
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:post_id)
    |> unique_constraint([:user_id, :post_id], message: "Vous avez déjà réagi à ce post")
  end

  def reaction_types, do: @reaction_types

  # Emojis pour chaque type de réaction
  def emoji("like"), do: "👍"
  def emoji("love"), do: "❤️"
  def emoji("haha"), do: "😂"
  def emoji("wow"), do: "😮"
  def emoji("sad"), do: "😢"
  def emoji("angry"), do: "😠"
  def emoji(_), do: "👍"

  # Labels pour chaque type
  def label("like"), do: "J'aime"
  def label("love"), do: "J'adore"
  def label("haha"), do: "Haha"
  def label("wow"), do: "Wouah"
  def label("sad"), do: "Triste"
  def label("angry"), do: "Grrr"
  def label(_), do: "J'aime"
end
