defmodule MonApp.Chat.MessageAttachment do
  use Ecto.Schema
  import Ecto.Changeset

  alias MonApp.Chat.Message

  schema "message_attachments" do
    field :filename, :string
    field :original_filename, :string
    field :content_type, :string
    field :size, :integer

    belongs_to :message, Message

    timestamps()
  end

  def changeset(attachment, attrs) do
    attachment
    |> cast(attrs, [:filename, :original_filename, :content_type, :size, :message_id])
    |> validate_required([:filename, :original_filename, :content_type, :size, :message_id])
    |> validate_number(:size, greater_than: 0, less_than_or_equal_to: 10_000_000)
    |> foreign_key_constraint(:message_id)
  end

  @doc "Retourne l'URL de l'image"
  def url(%__MODULE__{filename: filename}) do
    "/uploads/chat/#{filename}"
  end

  @doc "Vérifie si l'attachement est une image"
  def image?(%__MODULE__{content_type: content_type}) do
    String.starts_with?(content_type, "image/")
  end
end
