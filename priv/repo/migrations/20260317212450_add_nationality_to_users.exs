defmodule MonApp.Repo.Migrations.AddNationalityToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :nationality, :string
    end
  end
end
