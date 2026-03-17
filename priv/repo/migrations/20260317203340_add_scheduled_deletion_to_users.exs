defmodule MonApp.Repo.Migrations.AddScheduledDeletionToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :scheduled_deletion_at, :naive_datetime, default: nil
    end
  end
end
