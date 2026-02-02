defmodule MonApp.Chat.Message do
  use Ecto.Schema
  import Ecto.Changeset

  alias MonApp.Accounts.User
  alias MonApp.Chat.Conversation
  alias MonApp.Chat.MessageAttachment

  @status_values ["sent", "delivered", "seen"]

  schema "messages" do
    field :body, :string
    field :status, :string, default: "sent"
    field :delivered_at, :utc_datetime
    field :seen_at, :utc_datetime

    belongs_to :conversation, Conversation
    belongs_to :sender, User
    has_many :attachments, MessageAttachment

    timestamps()
  end

  def changeset(message, attrs) do
    message
    |> cast(attrs, [:body, :conversation_id, :sender_id, :status, :delivered_at, :seen_at])
    |> validate_required([:conversation_id, :sender_id])
    |> validate_length(:body, max: 5000)
    |> validate_inclusion(:status, @status_values)
    |> foreign_key_constraint(:conversation_id)
    |> foreign_key_constraint(:sender_id)
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
end
