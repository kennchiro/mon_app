defmodule MonApp.Repo.Migrations.AddVisibilityToPosts do
  use Ecto.Migration

  def change do
    alter table(:posts) do
      add :visibility, :string, default: "public"  # public, friends, private
    end

    create index(:posts, [:visibility])
  end
end
