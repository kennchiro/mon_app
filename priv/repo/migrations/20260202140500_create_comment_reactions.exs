defmodule MonApp.Repo.Migrations.CreateCommentReactions do
  use Ecto.Migration

  def change do
    create table(:comment_reactions) do
      add :type, :string, null: false  # like, love, haha, wow, sad, angry
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :comment_id, references(:comments, on_delete: :delete_all), null: false

      timestamps()
    end

    # Un utilisateur ne peut avoir qu'une seule réaction par commentaire
    create unique_index(:comment_reactions, [:user_id, :comment_id])
    create index(:comment_reactions, [:comment_id])
    create index(:comment_reactions, [:type])
  end
end
