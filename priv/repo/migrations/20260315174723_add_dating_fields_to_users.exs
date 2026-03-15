defmodule MonApp.Repo.Migrations.AddDatingFieldsToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :gender, :string
      add :bio, :text
      add :birthdate, :date
      add :looking_for, :string, default: "any"
      add :interests, {:array, :string}, default: []
      add :location, :string
    end
  end
end
