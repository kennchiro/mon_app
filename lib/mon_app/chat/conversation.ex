defmodule MonApp.Chat.Conversation do
  use Ecto.Schema
  import Ecto.Changeset

  alias MonApp.Accounts.User
  alias MonApp.Chat.Message
  alias MonApp.Chat.ConversationParticipant

  schema "conversations" do
    # Champs pour les chats 1-à-1 (legacy, gardés pour compatibilité)
    belongs_to :user1, User
    belongs_to :user2, User

    # Champs pour les groupes
    field :is_group, :boolean, default: false
    field :name, :string
    belongs_to :admin, User

    # Relations
    has_many :messages, Message
    has_many :participants, ConversationParticipant
    has_many :participant_users, through: [:participants, :user]

    field :last_message_at, :utc_datetime

    timestamps()
  end

  @doc "Changeset pour les conversations 1-à-1"
  def changeset(conversation, attrs) do
    conversation
    |> cast(attrs, [:user1_id, :user2_id, :last_message_at, :is_group, :name, :admin_id])
    |> validate_required([:user1_id, :user2_id])
    |> put_change(:is_group, false)
    |> validate_different_users()
    |> normalize_user_order()
    |> foreign_key_constraint(:user1_id)
    |> foreign_key_constraint(:user2_id)
    |> unique_constraint([:user1_id, :user2_id], name: :conversations_unique_pair)
  end

  @doc "Changeset pour les conversations de groupe"
  def group_changeset(conversation, attrs) do
    conversation
    |> cast(attrs, [:name, :admin_id, :last_message_at, :is_group])
    |> put_change(:is_group, true)
    |> validate_required([:name, :admin_id])
    |> validate_length(:name, min: 1, max: 100)
    |> foreign_key_constraint(:admin_id)
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

  @doc "Retourne l'autre utilisateur dans la conversation 1-à-1"
  def other_user(%__MODULE__{is_group: false} = conversation, current_user_id) do
    cond do
      conversation.user1_id == current_user_id -> conversation.user2
      conversation.user2_id == current_user_id -> conversation.user1
      true -> nil
    end
  end
  def other_user(%__MODULE__{is_group: true}, _current_user_id), do: nil

  @doc "Retourne l'ID de l'autre utilisateur"
  def other_user_id(%__MODULE__{is_group: false} = conversation, current_user_id) do
    cond do
      conversation.user1_id == current_user_id -> conversation.user2_id
      conversation.user2_id == current_user_id -> conversation.user1_id
      true -> nil
    end
  end
  def other_user_id(%__MODULE__{is_group: true}, _current_user_id), do: nil

  @doc "Vérifie si c'est une conversation de groupe"
  def group?(%__MODULE__{is_group: is_group}), do: is_group

  @doc "Retourne le nom d'affichage de la conversation"
  def display_name(%__MODULE__{is_group: true, name: name}, _current_user_id), do: name
  def display_name(%__MODULE__{is_group: false} = conv, current_user_id) do
    case other_user(conv, current_user_id) do
      nil -> "Conversation"
      user -> user.name
    end
  end
end
