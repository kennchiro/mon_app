defmodule MonApp.Chat.Message do
  use Ecto.Schema
  import Ecto.Changeset

  alias MonApp.Accounts.User
  alias MonApp.Chat.Conversation
  alias MonApp.Chat.MessageAttachment
  alias MonApp.Chat.MessageReaction

  @status_values ["sent", "delivered", "seen"]

  schema "messages" do
    field :body, :string
    field :status, :string, default: "sent"
    field :delivered_at, :utc_datetime
    field :seen_at, :utc_datetime
    field :deleted_for_sender_at, :utc_datetime
    field :deleted_for_all_at, :utc_datetime

    belongs_to :conversation, Conversation
    belongs_to :sender, User
    belongs_to :reply_to, __MODULE__
    has_many :attachments, MessageAttachment
    has_many :reactions, MessageReaction

    timestamps()
  end

  def changeset(message, attrs) do
    message
    |> cast(attrs, [:body, :conversation_id, :sender_id, :status, :delivered_at, :seen_at, :reply_to_id])
    |> validate_required([:conversation_id, :sender_id])
    |> validate_length(:body, max: 5000)
    |> validate_inclusion(:status, @status_values)
    |> foreign_key_constraint(:conversation_id)
    |> foreign_key_constraint(:sender_id)
    |> foreign_key_constraint(:reply_to_id)
  end

  @doc "Vérifie si le message a des attachements"
  def has_attachments?(%__MODULE__{attachments: attachments}) when is_list(attachments) do
    length(attachments) > 0
  end
  def has_attachments?(_), do: false

  def status_changeset(message, attrs) do
    message
    |> cast(attrs, [:status, :delivered_at, :seen_at])
    |> validate_inclusion(:status, @status_values)
  end

  @doc "Vérifie si le message est envoyé par l'utilisateur donné"
  def sent_by?(%__MODULE__{} = message, user_id) do
    message.sender_id == user_id
  end

  @doc "Retourne l'icône de statut pour l'affichage"
  def status_icon("sent"), do: "✓"
  def status_icon("delivered"), do: "✓✓"
  def status_icon("seen"), do: "✓✓"
  def status_icon(_), do: ""

  @doc "Retourne la classe CSS pour le statut"
  def status_class("seen"), do: "text-info"
  def status_class(_), do: "text-base-content/50"

  def status_values, do: @status_values

  @doc "Vérifie si le message est visible pour un utilisateur donné"
  def visible_for?(%__MODULE__{} = message, user_id) do
    cond do
      # Supprimé pour moi (par l'expéditeur) - le cacher de sa vue
      message.deleted_for_sender_at != nil and message.sender_id == user_id -> false
      # Messages supprimés pour tous restent visibles (affichés comme "supprimé")
      # pour permettre à l'utilisateur de les supprimer de sa vue personnelle
      true -> true
    end
  end

  @doc "Vérifie si le message est supprimé pour tous"
  def deleted_for_all?(%__MODULE__{deleted_for_all_at: nil}), do: false
  def deleted_for_all?(%__MODULE__{}), do: true

  def delete_changeset(message, :for_me) do
    message
    |> cast(%{deleted_for_sender_at: DateTime.utc_now() |> DateTime.truncate(:second)}, [:deleted_for_sender_at])
  end

  def delete_changeset(message, :for_all) do
    message
    |> cast(%{deleted_for_all_at: DateTime.utc_now() |> DateTime.truncate(:second)}, [:deleted_for_all_at])
  end
end
