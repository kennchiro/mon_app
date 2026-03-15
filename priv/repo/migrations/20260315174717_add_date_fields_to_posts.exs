defmodule MonApp.Repo.Migrations.AddDateFieldsToPosts do
  use Ecto.Migration

  def change do
    alter table(:posts) do
      add :post_type, :string, default: "standard"
      add :date_title, :string
      add :date_category, :string
      add :date_location, :string
      add :date_datetime, :utc_datetime
      add :date_budget, :string
      add :date_spots, :integer, default: 1
      add :date_gender_pref, :string, default: "any"
      add :date_age_min, :integer
      add :date_age_max, :integer
      add :date_status, :string, default: "open"
    end

    create index(:posts, [:post_type])
    create index(:posts, [:date_status])
    create index(:posts, [:date_category])
  end
end
