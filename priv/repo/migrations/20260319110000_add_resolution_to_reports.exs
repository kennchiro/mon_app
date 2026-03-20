defmodule MonApp.Repo.Migrations.AddResolutionToReports do
  use Ecto.Migration

  def change do
    alter table(:user_reports) do
      add :resolved_by_id, references(:users, on_delete: :nilify_all)
      add :resolved_at, :naive_datetime
      add :resolution_note, :string
    end

    create index(:user_reports, [:resolved_by_id])
  end
end
