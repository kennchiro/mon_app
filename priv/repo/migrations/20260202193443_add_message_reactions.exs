defmodule MonApp.Repo.Migrations.AddMessageReactions do
  use Ecto.Migration

  def change do
    create table(:message_reactions) do
      add :emoji, :string, null: false
      add :message_id, references(:messages, on_delete: :delete_all), null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false

      timestamps()
    end

    # Un utilisateur ne peut réagir qu'une fois avec le même emoji sur un message
    create unique_index(:message_reactions, [:message_id, :user_id, :emoji])
    create index(:message_reactions, [:message_id])
    create index(:message_reactions, [:user_id])
  end
end
