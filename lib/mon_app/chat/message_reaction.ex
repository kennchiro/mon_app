defmodule MonApp.Chat.MessageReaction do
  use Ecto.Schema
  import Ecto.Changeset

  alias MonApp.Chat.Message
  alias MonApp.Accounts.User

  # Emojis de réaction disponibles (style Messenger)
  @available_emojis ["👍", "❤️", "😂", "😮", "😢", "😠"]

  schema "message_reactions" do
    field :emoji, :string

    belongs_to :message, Message
    belongs_to :user, User

    timestamps()
  end

  def changeset(reaction, attrs) do
    reaction
    |> cast(attrs, [:emoji, :message_id, :user_id])
    |> validate_required([:emoji, :message_id, :user_id])
    |> validate_inclusion(:emoji, @available_emojis)
    |> foreign_key_constraint(:message_id)
    |> foreign_key_constraint(:user_id)
    |> unique_constraint([:message_id, :user_id, :emoji])
  end

  def available_emojis, do: @available_emojis
end
