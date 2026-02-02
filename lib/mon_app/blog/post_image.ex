defmodule MonApp.Blog.PostImage do
  use Ecto.Schema
  import Ecto.Changeset

  alias MonApp.Blog.Post

  schema "post_images" do
    field :filename, :string
    field :original_filename, :string
    field :content_type, :string
    field :size, :integer

    belongs_to :post, Post

    timestamps()
  end

  def changeset(image, attrs) do
    image
    |> cast(attrs, [:filename, :original_filename, :content_type, :size, :post_id])
    |> validate_required([:filename, :post_id])
    |> foreign_key_constraint(:post_id)
  end

  def url(%__MODULE__{filename: filename}) do
    "/uploads/posts/#{filename}"
  end
end
