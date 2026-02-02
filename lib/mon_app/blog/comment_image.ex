defmodule MonApp.Blog.CommentImage do
  use Ecto.Schema
  import Ecto.Changeset

  alias MonApp.Blog.Comment

  schema "comment_images" do
    field :filename, :string
    field :original_filename, :string
    field :content_type, :string
    field :size, :integer

    belongs_to :comment, Comment

    timestamps()
  end

  def changeset(image, attrs) do
    image
    |> cast(attrs, [:filename, :original_filename, :content_type, :size, :comment_id])
    |> validate_required([:filename, :comment_id])
    |> foreign_key_constraint(:comment_id)
  end
end
