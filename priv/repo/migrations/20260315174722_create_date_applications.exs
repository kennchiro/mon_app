defmodule MonApp.Repo.Migrations.CreateDateApplications do
  use Ecto.Migration

  def change do
    create table(:date_applications) do
      add :message, :text
      add :status, :string, default: "pending"
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :post_id, references(:posts, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:date_applications, [:user_id])
    create index(:date_applications, [:post_id])
    create unique_index(:date_applications, [:user_id, :post_id])
  end
end
