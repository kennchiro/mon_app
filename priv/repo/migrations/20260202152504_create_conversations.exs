defmodule MonApp.Repo.Migrations.CreateConversations do
  use Ecto.Migration

  def change do
    create table(:conversations) do
      add :user1_id, references(:users, on_delete: :delete_all), null: false
      add :user2_id, references(:users, on_delete: :delete_all), null: false
      add :last_message_at, :utc_datetime

      timestamps()
    end

    # Index pour retrouver rapidement les conversations d'un user
    create index(:conversations, [:user1_id])
    create index(:conversations, [:user2_id])

    # Index unique pour éviter les doublons de conversation
    # On s'assure que user1_id < user2_id lors de la création
    create unique_index(:conversations, [:user1_id, :user2_id],
      name: :conversations_unique_pair)

    # Index pour trier par dernier message
    create index(:conversations, [:last_message_at])
  end
end
