defmodule MonApp.Repo.Migrations.AddGroupChatSupport do
  use Ecto.Migration

  def change do
    # Ajouter les champs pour les groupes à la table conversations
    alter table(:conversations) do
      add :is_group, :boolean, default: false, null: false
      add :name, :string  # Nom du groupe (nullable pour les chats 1-à-1)
      add :admin_id, references(:users, on_delete: :nilify_all)  # Créateur/admin du groupe
    end

    # Rendre user1_id et user2_id nullable pour les groupes
    execute "ALTER TABLE conversations ALTER COLUMN user1_id DROP NOT NULL",
            "ALTER TABLE conversations ALTER COLUMN user1_id SET NOT NULL"
    execute "ALTER TABLE conversations ALTER COLUMN user2_id DROP NOT NULL",
            "ALTER TABLE conversations ALTER COLUMN user2_id SET NOT NULL"

    # Créer la table des participants aux conversations de groupe
    create table(:conversation_participants) do
      add :conversation_id, references(:conversations, on_delete: :delete_all), null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :joined_at, :utc_datetime, null: false, default: fragment("NOW()")
      add :last_read_at, :utc_datetime  # Pour tracker les messages non lus par participant

      timestamps()
    end

    # Index pour retrouver les participants d'une conversation
    create index(:conversation_participants, [:conversation_id])
    # Index pour retrouver les conversations d'un utilisateur
    create index(:conversation_participants, [:user_id])
    # Index unique pour éviter les doublons
    create unique_index(:conversation_participants, [:conversation_id, :user_id])

    # Index pour les groupes
    create index(:conversations, [:is_group])
  end
end
