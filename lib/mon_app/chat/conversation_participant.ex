defmodule MonApp.Chat.ConversationParticipant do
  use Ecto.Schema
  import Ecto.Changeset

  alias MonApp.Accounts.User
  alias MonApp.Chat.Conversation

  schema "conversation_participants" do
    belongs_to :conversation, Conversation
    belongs_to :user, User

    field :joined_at, :utc_datetime
    field :last_read_at, :utc_datetime

    timestamps()
  end

  def changeset(participant, attrs) do
    participant
    |> cast(attrs, [:conversation_id, :user_id, :joined_at, :last_read_at])
    |> validate_required([:conversation_id, :user_id])
    |> put_joined_at()
    |> foreign_key_constraint(:conversation_id)
    |> foreign_key_constraint(:user_id)
    |> unique_constraint([:conversation_id, :user_id])
  end

  defp put_joined_at(changeset) do
    if get_field(changeset, :joined_at) do
      changeset
    else
      put_change(changeset, :joined_at, DateTime.utc_now() |> DateTime.truncate(:second))
    end
  end
end
