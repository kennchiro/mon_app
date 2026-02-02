defmodule MonApp.Repo.Migrations.AddParentIdToComments do
  use Ecto.Migration

  def change do
    alter table(:comments) do
      add :parent_id, references(:comments, on_delete: :delete_all)
    end

    create index(:comments, [:parent_id])
  end
end
