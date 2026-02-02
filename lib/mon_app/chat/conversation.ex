defmodule MonApp.Chat.Conversation do
  use Ecto.Schema
  import Ecto.Changeset

  alias MonApp.Accounts.User
  alias MonApp.Chat.Message

  schema "conversations" do
    belongs_to :user1, User
    belongs_to :user2, User
    has_many :messages, Message

    field :last_message_at, :utc_datetime

    timestamps()
  end

  def changeset(conversation, attrs) do
    conversation
    |> cast(attrs, [:user1_id, :user2_id, :last_message_at])
    |> validate_required([:user1_id, :user2_id])
    |> validate_different_users()
    |> normalize_user_order()
    |> foreign_key_constraint(:user1_id)
    |> foreign_key_constraint(:user2_id)
    |> unique_constraint([:user1_id, :user2_id], name: :conversations_unique_pair)
  end

  # S'assure que user1_id != user2_id
  defp validate_different_users(changeset) do
    user1_id = get_field(changeset, :user1_id)
    user2_id = get_field(changeset, :user2_id)

    if user1_id && user2_id && user1_id == user2_id do
      add_error(changeset, :user2_id, "ne peut pas être le même que user1")
    else
      changeset
    end
  end

  # Normalise l'ordre des users (user1_id < user2_id) pour l'index unique
  defp normalize_user_order(changeset) do
    user1_id = get_field(changeset, :user1_id)
    user2_id = get_field(changeset, :user2_id)

    if user1_id && user2_id && user1_id > user2_id do
      changeset
      |> put_change(:user1_id, user2_id)
      |> put_change(:user2_id, user1_id)
    else
      changeset
    end
  end

  @doc "Retourne l'autre utilisateur dans la conversation"
  def other_user(%__MODULE__{} = conversation, current_user_id) do
    cond do
      conversation.user1_id == current_user_id -> conversation.user2
      conversation.user2_id == current_user_id -> conversation.user1
      true -> nil
    end
  end

  @doc "Retourne l'ID de l'autre utilisateur"
  def other_user_id(%__MODULE__{} = conversation, current_user_id) do
    cond do
      conversation.user1_id == current_user_id -> conversation.user2_id
      conversation.user2_id == current_user_id -> conversation.user1_id
      true -> nil
    end
  end
end
