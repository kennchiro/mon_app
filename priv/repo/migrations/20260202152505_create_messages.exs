defmodule MonApp.Repo.Migrations.CreateMessages do
  use Ecto.Migration

  def change do
    # Table des messages
    create table(:messages) do
      add :body, :text, null: false
      add :conversation_id, references(:conversations, on_delete: :delete_all), null: false
      add :sender_id, references(:users, on_delete: :delete_all), null: false

      # Statut du message côté destinataire
      # sent = envoyé (en DB)
      # delivered = livré (destinataire connecté)
      # seen = vu (destinataire a ouvert la conversation)
      add :status, :string, default: "sent", null: false
      add :delivered_at, :utc_datetime
      add :seen_at, :utc_datetime

      timestamps()
    end

    # Index pour récupérer les messages d'une conversation
    create index(:messages, [:conversation_id])

    # Index pour trier par date
    create index(:messages, [:inserted_at])

    # Index pour les messages non lus
    create index(:messages, [:conversation_id, :sender_id, :status])
  end
end
