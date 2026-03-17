defmodule MonApp.Repo.Migrations.AddProfileVisibilitySettings do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :show_dates_on_profile, :boolean, default: true
      add :show_posts_on_profile, :boolean, default: true
    end
  end
end
