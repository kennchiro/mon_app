defmodule MonApp.Repo.Migrations.CreateBlocksAndReports do
  use Ecto.Migration

  def change do
    create table(:user_blocks) do
      add :blocker_id, references(:users, on_delete: :delete_all), null: false
      add :blocked_id, references(:users, on_delete: :delete_all), null: false
      timestamps()
    end

    create unique_index(:user_blocks, [:blocker_id, :blocked_id])
    create index(:user_blocks, [:blocked_id])

    create table(:user_reports) do
      add :reporter_id, references(:users, on_delete: :delete_all), null: false
      add :reported_id, references(:users, on_delete: :delete_all), null: false
      add :reason, :string, null: false
      add :details, :text
      add :status, :string, default: "pending"
      timestamps()
    end

    create index(:user_reports, [:reported_id])
    create index(:user_reports, [:status])
  end
end
