defmodule MonApp.Repo.Migrations.CreatePostImages do
  use Ecto.Migration

  def change do
    create table(:post_images) do
      add :filename, :string, null: false
      add :original_filename, :string
      add :content_type, :string
      add :size, :integer
      add :post_id, references(:posts, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:post_images, [:post_id])
  end
end
