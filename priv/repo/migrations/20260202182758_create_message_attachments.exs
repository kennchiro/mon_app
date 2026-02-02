defmodule MonApp.Repo.Migrations.CreateMessageAttachments do
  use Ecto.Migration

  def change do
    create table(:message_attachments) do
      add :filename, :string, null: false
      add :original_filename, :string, null: false
      add :content_type, :string, null: false
      add :size, :integer, null: false
      add :message_id, references(:messages, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:message_attachments, [:message_id])
  end
end
