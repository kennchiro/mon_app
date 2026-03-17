defmodule MonApp.Repo.Migrations.AddPostIdToReports do
  use Ecto.Migration

  def change do
    alter table(:user_reports) do
      add :post_id, references(:posts, on_delete: :delete_all)
      add :report_type, :string, default: "user"
    end

    create index(:user_reports, [:post_id])
  end
end
