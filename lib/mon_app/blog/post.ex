defmodule MonApp.Blog.Post do
  use Ecto.Schema
  import Ecto.Changeset

  alias MonApp.Accounts.User
  alias MonApp.Blog.PostImage
  alias MonApp.Blog.Comment
  alias MonApp.Blog.Reaction

  @visibility_options ["public", "friends", "private"]

  schema "posts" do
    field :title, :string
    field :body, :string
    field :published, :boolean, default: false
    field :visibility, :string, default: "public"  # public, friends, private

    belongs_to :user, User
    belongs_to :shared_post, __MODULE__
    has_many :shares, __MODULE__, foreign_key: :shared_post_id
    has_many :images, PostImage, on_delete: :delete_all
    has_many :comments, Comment, on_delete: :delete_all
    has_many :reactions, Reaction, on_delete: :delete_all

    timestamps()
  end

  def changeset(post, attrs) do
    post
    |> cast(attrs, [:title, :body, :published, :user_id, :visibility, :shared_post_id])
    |> validate_required([:user_id])
    |> validate_length(:title, max: 200)
    |> validate_inclusion(:visibility, @visibility_options)
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:shared_post_id)
    |> validate_has_content_or_share()
  end

  # Valide qu'un post a soit un titre, soit un shared_post_id
  defp validate_has_content_or_share(changeset) do
    title = get_field(changeset, :title)
    body = get_field(changeset, :body)
    shared_post_id = get_field(changeset, :shared_post_id)

    has_content = (title && String.trim(title) != "") || (body && String.trim(body) != "")

    if !has_content && !shared_post_id do
      add_error(changeset, :title, "Un titre ou un contenu est requis")
    else
      changeset
    end
  end

  def visibility_options, do: @visibility_options

  def visibility_label("public"), do: "Public"
  def visibility_label("friends"), do: "Amis"
  def visibility_label("private"), do: "Moi uniquement"
  def visibility_label(_), do: "Public"
end
