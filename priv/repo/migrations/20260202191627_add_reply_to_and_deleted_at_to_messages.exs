defmodule MonApp.Repo.Migrations.AddReplyToAndDeletedAtToMessages do
  use Ecto.Migration

  def change do
    alter table(:messages) do
      # Reply to message
      add :reply_to_id, references(:messages, on_delete: :nilify_all)

      # Soft delete: deleted for sender only
      add :deleted_for_sender_at, :utc_datetime

      # Soft delete: deleted for everyone
      add :deleted_for_all_at, :utc_datetime
    end

    create index(:messages, [:reply_to_id])
  end
end
