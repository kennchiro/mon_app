defmodule MonApp.Repo.Migrations.CreateCommentImages do
  use Ecto.Migration

  def change do
    create table(:comment_images) do
      add :filename, :string, null: false
      add :original_filename, :string
      add :content_type, :string
      add :size, :integer
      add :comment_id, references(:comments, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:comment_images, [:comment_id])
  end
end
