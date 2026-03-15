defmodule MonApp.Repo.Migrations.CreateNotifications do
  use Ecto.Migration

  def change do
    create table(:notifications) do
      add :type, :string, null: false
      add :message, :string, null: false
      add :read, :boolean, default: false, null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :actor_id, references(:users, on_delete: :delete_all), null: false
      add :post_id, references(:posts, on_delete: :delete_all)
      add :comment_id, references(:comments, on_delete: :delete_all)

      timestamps()
    end

    create index(:notifications, [:user_id, :read])
    create index(:notifications, [:user_id, :inserted_at])
  end
end
