defmodule MonApp.Repo.Migrations.CreateReactions do
  use Ecto.Migration

  def change do
    create table(:reactions) do
      add :type, :string, null: false  # like, love, haha, wow, sad, angry
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :post_id, references(:posts, on_delete: :delete_all), null: false

      timestamps()
    end

    # Un utilisateur ne peut avoir qu'une seule réaction par post
    create unique_index(:reactions, [:user_id, :post_id])
    create index(:reactions, [:post_id])
    create index(:reactions, [:type])
  end
end
