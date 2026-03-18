defmodule MonApp.Repo.Migrations.AddPerformanceIndexes do
  use Ecto.Migration

  def change do
    # Posts: tri par date + type (requête la plus fréquente)
    create_if_not_exists index(:posts, [:post_type, :inserted_at])
    create_if_not_exists index(:posts, [:user_id, :post_type])
    create_if_not_exists index(:posts, [:date_datetime])

    # Friendships: requête status + user (très fréquent)
    create_if_not_exists index(:friendships, [:status, :user_id])
    create_if_not_exists index(:friendships, [:status, :friend_id])
    create_if_not_exists index(:friendships, [:user_id, :inserted_at])

    # Messages: tri par conversation + date
    create_if_not_exists index(:messages, [:conversation_id, :inserted_at])
    create_if_not_exists index(:messages, [:sender_id])

    # Notifications: requête user + read (badge count)
    create_if_not_exists index(:notifications, [:user_id, :read])
    create_if_not_exists index(:notifications, [:actor_id])
  end
end
