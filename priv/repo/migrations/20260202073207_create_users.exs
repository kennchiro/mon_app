defmodule MonApp.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :name, :string, null: false
      add :email, :string, null: false
      add :age, :integer

      timestamps()  # Ajoute inserted_at et updated_at
    end

    create unique_index(:users, [:email])  # Email unique
  end
end
