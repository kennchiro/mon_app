defmodule MonApp.Repo.Migrations.AddSharedPostToPosts do
  use Ecto.Migration

  def change do
    alter table(:posts) do
      add :shared_post_id, references(:posts, on_delete: :nilify_all)
    end

    create index(:posts, [:shared_post_id])
  end
end
