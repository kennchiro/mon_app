defmodule MonApp.Blog do
  @moduledoc """
  Le context Blog - gère les posts.
  """

  import Ecto.Query
  alias MonApp.Repo
  alias MonApp.Blog.Post
  alias MonApp.Blog.PostImage
  alias MonApp.Blog.Comment
  alias MonApp.Blog.CommentImage
  alias MonApp.Blog.Reaction
  alias MonApp.Blog.CommentReaction
  alias MonApp.Social

  @posts_per_page 20

  # ============== READ ==============

  @doc "Récupère tous les posts (ATTENTION: éviter en prod)"
  def list_posts do
    Post
    |> order_by(desc: :inserted_at)
    |> Repo.all()
  end

  @doc """
  Récupère les posts visibles pour un utilisateur donné.
  - Public : tout le monde voit
  - Friends : l'auteur + ses amis voient
  - Private : seul l'auteur voit
  """
  def list_posts_for_user(user_id) do
    # Récupérer les IDs des amis
    friend_ids = Social.list_friends(user_id) |> Enum.map(& &1.id)

    Post
    |> where([p],
      # Posts publics
      p.visibility == "public" or
      # Mes propres posts (toutes visibilités)
      p.user_id == ^user_id or
      # Posts "friends" de mes amis
      (p.visibility == "friends" and p.user_id in ^friend_ids)
    )
    |> order_by(desc: :inserted_at)
    |> Repo.all()
    |> Repo.preload([:user, :images, :reactions, :shares,
      shared_post: [:user, :images],
      comments: {comments_query(), [:user, :images, :reactions, replies: [:user, :images, :reactions]]}])
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

  @doc """
  Récupère les posts visibles pour un user avec pagination.
  """
  def list_posts_for_user_paginated(user_id, page \\ 1, per_page \\ @posts_per_page) do
    offset = (page - 1) * per_page
    friend_ids = Social.list_friends(user_id) |> Enum.map(& &1.id)

    posts =
      Post
      |> where([p],
        p.visibility == "public" or
        p.user_id == ^user_id or
        (p.visibility == "friends" and p.user_id in ^friend_ids)
      )
      |> order_by(desc: :inserted_at)
      |> limit(^(per_page + 1))
      |> offset(^offset)
      |> preload(:user)
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

  # ============== IMAGES ==============

  @doc "Crée une image pour un post"
  def create_post_image(attrs) do
    %PostImage{}
    |> PostImage.changeset(attrs)
    |> Repo.insert()
  end

  @doc "Supprime une image"
  def delete_post_image(%PostImage{} = image) do
    # Supprimer le fichier physique
    path = Path.join(["priv/static/uploads/posts", image.filename])
    File.rm(path)

    Repo.delete(image)
  end

  @doc "Récupère une image par ID"
  def get_post_image(id), do: Repo.get(PostImage, id)

  # ============== COMMENTS ==============

  @doc "Récupère un post avec ses commentaires et réponses"
  def get_post_with_comments(id) do
    post = Repo.get(Post, id)

    if post do
      Repo.preload(post, [:user, :images, :reactions, :shares,
        shared_post: [:user, :images],
        comments: {comments_query(), [:user, :images, :reactions, replies: [:user, :images, :reactions]]}])
    else
      nil
    end
  end

  @doc "Liste les commentaires d'un post"
  def list_comments(post_id) do
    Comment
    |> where(post_id: ^post_id)
    |> order_by(asc: :inserted_at)
    |> preload(:user)
    |> Repo.all()
  end

  @doc "Compte les commentaires d'un post"
  def count_comments(post_id) do
    Comment
    |> where(post_id: ^post_id)
    |> Repo.aggregate(:count)
  end

  @doc "Crée un commentaire"
  def create_comment(attrs) do
    %Comment{}
    |> Comment.changeset(attrs)
    |> Repo.insert()
  end

  @doc "Supprime un commentaire"
  def delete_comment(%Comment{} = comment) do
    Repo.delete(comment)
  end

  @doc "Récupère un commentaire par ID"
  def get_comment(id), do: Repo.get(Comment, id)

  @doc "Retourne un changeset pour les formulaires de commentaire"
  def change_comment(%Comment{} = comment, attrs \\ %{}) do
    Comment.changeset(comment, attrs)
  end

  # ============== HELPERS ==============

  @doc "Retourne un changeset pour les formulaires"
  def change_post(%Post{} = post, attrs \\ %{}) do
    Post.changeset(post, attrs)
  end

  @doc "Chemin du dossier uploads pour les posts"
  def uploads_dir, do: "priv/static/uploads/posts"

  @doc "Chemin du dossier uploads pour les commentaires"
  def comment_uploads_dir, do: "priv/static/uploads/comments"

  # Query pour récupérer seulement les commentaires de premier niveau (sans parent)
  defp comments_query do
    from c in Comment,
      where: is_nil(c.parent_id),
      order_by: [asc: c.inserted_at]
  end

  @doc "Crée une réponse à un commentaire"
  def create_reply(attrs) do
    %Comment{}
    |> Comment.changeset(attrs)
    |> Repo.insert()
  end

  @doc "Récupère les réponses d'un commentaire"
  def list_replies(comment_id) do
    Comment
    |> where(parent_id: ^comment_id)
    |> order_by(asc: :inserted_at)
    |> preload(:user)
    |> Repo.all()
  end

  # ============== REACTIONS ==============

  @doc "Ajoute ou modifie une réaction sur un post"
  def toggle_reaction(user_id, post_id, reaction_type) do
    case get_user_reaction(user_id, post_id) do
      nil ->
        # Pas de réaction existante, on en crée une
        create_reaction(%{user_id: user_id, post_id: post_id, type: reaction_type})

      %{type: ^reaction_type} = existing ->
        # Même réaction, on la supprime (toggle off)
        delete_reaction(existing)

      existing ->
        # Réaction différente, on la met à jour
        update_reaction(existing, %{type: reaction_type})
    end
  end

  @doc "Crée une réaction"
  def create_reaction(attrs) do
    %Reaction{}
    |> Reaction.changeset(attrs)
    |> Repo.insert()
  end

  @doc "Met à jour une réaction"
  def update_reaction(%Reaction{} = reaction, attrs) do
    reaction
    |> Reaction.changeset(attrs)
    |> Repo.update()
  end

  @doc "Supprime une réaction"
  def delete_reaction(%Reaction{} = reaction) do
    Repo.delete(reaction)
  end

  @doc "Récupère la réaction d'un utilisateur sur un post"
  def get_user_reaction(user_id, post_id) do
    Reaction
    |> where(user_id: ^user_id, post_id: ^post_id)
    |> Repo.one()
  end

  @doc "Liste les réactions d'un post"
  def list_reactions(post_id) do
    Reaction
    |> where(post_id: ^post_id)
    |> preload(:user)
    |> Repo.all()
  end

  @doc "Compte les réactions par type pour un post"
  def count_reactions_by_type(post_id) do
    Reaction
    |> where(post_id: ^post_id)
    |> group_by([r], r.type)
    |> select([r], {r.type, count(r.id)})
    |> Repo.all()
    |> Enum.into(%{})
  end

  @doc "Compte le total des réactions d'un post"
  def count_reactions(post_id) do
    Reaction
    |> where(post_id: ^post_id)
    |> Repo.aggregate(:count)
  end

  # ============== COMMENT REACTIONS ==============

  @doc "Ajoute ou modifie une réaction sur un commentaire"
  def toggle_comment_reaction(user_id, comment_id, reaction_type) do
    case get_user_comment_reaction(user_id, comment_id) do
      nil ->
        create_comment_reaction(%{user_id: user_id, comment_id: comment_id, type: reaction_type})

      %{type: ^reaction_type} = existing ->
        delete_comment_reaction(existing)

      existing ->
        update_comment_reaction(existing, %{type: reaction_type})
    end
  end

  @doc "Crée une réaction sur un commentaire"
  def create_comment_reaction(attrs) do
    %CommentReaction{}
    |> CommentReaction.changeset(attrs)
    |> Repo.insert()
  end

  @doc "Met à jour une réaction sur un commentaire"
  def update_comment_reaction(%CommentReaction{} = reaction, attrs) do
    reaction
    |> CommentReaction.changeset(attrs)
    |> Repo.update()
  end

  @doc "Supprime une réaction sur un commentaire"
  def delete_comment_reaction(%CommentReaction{} = reaction) do
    Repo.delete(reaction)
  end

  @doc "Récupère la réaction d'un utilisateur sur un commentaire"
  def get_user_comment_reaction(user_id, comment_id) do
    CommentReaction
    |> where(user_id: ^user_id, comment_id: ^comment_id)
    |> Repo.one()
  end

  @doc "Liste les réactions d'un commentaire"
  def list_comment_reactions(comment_id) do
    CommentReaction
    |> where(comment_id: ^comment_id)
    |> preload(:user)
    |> Repo.all()
  end

  # ============== COMMENT IMAGES ==============

  @doc "Crée une image pour un commentaire"
  def create_comment_image(attrs) do
    %CommentImage{}
    |> CommentImage.changeset(attrs)
    |> Repo.insert()
  end

  @doc "Supprime une image de commentaire"
  def delete_comment_image(%CommentImage{} = image) do
    # Supprimer le fichier physique
    path = Path.join([comment_uploads_dir(), image.filename])
    File.rm(path)

    Repo.delete(image)
  end

  @doc "Récupère une image de commentaire par ID"
  def get_comment_image(id), do: Repo.get(CommentImage, id)

  @doc "Liste les images d'un commentaire"
  def list_comment_images(comment_id) do
    CommentImage
    |> where(comment_id: ^comment_id)
    |> Repo.all()
  end

  # ============== SHARES ==============

  @doc "Partage un post"
  def share_post(user_id, shared_post_id, attrs \\ %{}) do
    attrs = Map.merge(attrs, %{
      user_id: user_id,
      shared_post_id: shared_post_id
    })

    %Post{}
    |> Post.changeset(attrs)
    |> Repo.insert()
  end

  @doc "Compte le nombre de partages d'un post"
  def count_shares(post_id) do
    Post
    |> where(shared_post_id: ^post_id)
    |> Repo.aggregate(:count)
  end

  @doc "Liste les partages d'un post"
  def list_shares(post_id) do
    Post
    |> where(shared_post_id: ^post_id)
    |> preload(:user)
    |> order_by(desc: :inserted_at)
    |> Repo.all()
  end

  @doc "Vérifie si un utilisateur a déjà partagé un post"
  def has_shared?(user_id, post_id) do
    Post
    |> where(user_id: ^user_id, shared_post_id: ^post_id)
    |> Repo.exists?()
  end
end
