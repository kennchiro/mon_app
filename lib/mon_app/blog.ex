defmodule MonApp.Blog do
  @moduledoc """
  Le context Blog - gère les posts.
  """

  import Ecto.Query
  alias MonApp.Repo
  alias MonApp.Blog.Post

  @posts_per_page 20

  # ============== READ ==============

  @doc "Récupère tous les posts (ATTENTION: éviter en prod)"
  def list_posts do
    Post
    |> order_by(desc: :inserted_at)
    |> Repo.all()
  end

  @doc """
  Récupère les posts avec pagination.
  Retourne {posts, has_more?}
  """
  def list_posts_paginated(page \\ 1, per_page \\ @posts_per_page) do
    offset = (page - 1) * per_page

    posts =
      Post
      |> order_by(desc: :inserted_at)
      |> limit(^(per_page + 1))  # +1 pour savoir s'il y a plus
      |> offset(^offset)
      |> preload(:user)  # Preload dans la query = 1 seule requête
      |> Repo.all()

    has_more? = length(posts) > per_page
    posts = Enum.take(posts, per_page)

    {posts, has_more?}
  end

  @doc "Récupère tous les posts d'un user"
  def list_posts_by_user(user_id) do
    Post
    |> where(user_id: ^user_id)
    |> order_by(desc: :inserted_at)
    |> Repo.all()
  end

  @doc "Récupère un post par ID"
  def get_post(id), do: Repo.get(Post, id)

  @doc "Récupère un post par ID avec le user préchargé"
  def get_post_with_user(id) do
    Post
    |> Repo.get(id)
    |> Repo.preload(:user)
  end

  # ============== CREATE ==============

  @doc "Crée un post pour un user"
  def create_post(attrs \\ %{}) do
    %Post{}
    |> Post.changeset(attrs)
    |> Repo.insert()
  end

  # ============== UPDATE ==============

  @doc "Met à jour un post"
  def update_post(%Post{} = post, attrs) do
    post
    |> Post.changeset(attrs)
    |> Repo.update()
  end

  # ============== DELETE ==============

  @doc "Supprime un post"
  def delete_post(%Post{} = post) do
    Repo.delete(post)
  end

  # ============== HELPERS ==============

  @doc "Retourne un changeset pour les formulaires"
  def change_post(%Post{} = post, attrs \\ %{}) do
    Post.changeset(post, attrs)
  end
end
