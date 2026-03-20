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
  alias MonApp.Blog.DateApplication
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
    |> Repo.preload([:user, :images, :reactions, :shares, date_applications: :user,
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
  @doc "Marque les dates passées comme complétées (max 1x par heure via ETS cache)"
  def expire_past_dates do
    last_run = :persistent_term.get(:last_expire_dates, 0)
    now_unix = System.system_time(:second)

    if now_unix - last_run > 300 do
      :persistent_term.put(:last_expire_dates, now_unix)
      now = NaiveDateTime.utc_now()

      Post
      |> where([p], p.post_type == "date")
      |> where([p], not is_nil(p.date_datetime))
      |> where([p], p.date_datetime < ^now)
      |> where([p], p.date_status == "open")
      |> Repo.update_all(set: [date_status: "completed"])
    else
      {0, nil}
    end
  end

  def list_posts_for_user_paginated(user_id, page \\ 1, per_page \\ @posts_per_page, opts \\ []) do
    offset = (page - 1) * per_page
    friend_ids = Social.list_friends(user_id) |> Enum.map(& &1.id)
    blocked_ids = Social.list_blocked_ids(user_id)
    post_type_filter = Keyword.get(opts, :post_type, "all")

    # Auto-expire past dates (throttled: 1x/5min)
    expire_past_dates()

    query =
      Post
      |> where([p],
        p.visibility == "public" or
        p.user_id == ^user_id or
        (p.visibility == "friends" and p.user_id in ^friend_ids)
      )
      |> where([p], p.user_id not in ^blocked_ids)

    query =
      case post_type_filter do
        "date" -> where(query, [p], p.post_type == "date")
        "standard" -> where(query, [p], p.post_type == "standard")
        _ -> query
      end

    # Exclure les posts date terminés depuis plus de 24h
    cutoff = NaiveDateTime.add(NaiveDateTime.utc_now(), -24 * 3600)

    query =
      from p in query,
        where:
          p.post_type != "date" or
          is_nil(p.date_datetime) or
          p.date_datetime >= ^cutoff

    posts =
      query
      |> order_by(desc: :inserted_at)
      |> limit(^(per_page + 1))
      |> offset(^offset)
      |> Repo.all()
      |> Repo.preload([:user, :images, :reactions, :shares, date_applications: :user,
        shared_post: [:user, :images],
        comments: {comments_query(), [:user, :images, :reactions, replies: [:user, :images, :reactions]]}])

    has_more? = length(posts) > per_page
    posts = Enum.take(posts, per_page)

    {posts, has_more?}
  end

  @doc "Récupère les posts d'un user visibles par un viewer"
  def list_user_posts_for_viewer(profile_user_id, viewer_user_id) do
    is_friend = profile_user_id == viewer_user_id or
      Social.friendship_status(viewer_user_id, profile_user_id) == :friends

    Post
    |> where([p], p.user_id == ^profile_user_id)
    |> where([p],
      p.visibility == "public" or
      p.user_id == ^viewer_user_id or
      (^is_friend and p.visibility == "friends")
    )
    |> order_by(desc: :inserted_at)
    |> Repo.all()
    |> Repo.preload([:user, :images, :reactions, :shares, date_applications: :user,
      shared_post: [:user, :images],
      comments: {comments_query(), [:user, :images, :reactions, replies: [:user, :images, :reactions]]}])
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

  # ============== ADMIN ==============

  @doc "Liste les posts pour l'admin avec pagination et filtres"
  def list_posts_admin(page \\ 1, per_page \\ 25, opts \\ []) do
    search = Keyword.get(opts, :search)
    post_type = Keyword.get(opts, :post_type)
    visibility = Keyword.get(opts, :visibility)
    sort = Keyword.get(opts, :sort, "newest")

    order =
      case sort do
        "oldest" -> [asc: :inserted_at]
        "title" -> [asc: :title]
        _ -> [desc: :inserted_at]
      end

    query =
      from p in Post,
        preload: [:user],
        order_by: ^order

    query =
      if search && search != "" do
        term = "%#{search}%"
        from p in query, where: ilike(p.title, ^term) or ilike(p.body, ^term)
      else
        query
      end

    query =
      if post_type && post_type != "" do
        from p in query, where: p.post_type == ^post_type
      else
        query
      end

    query =
      if visibility && visibility != "" do
        from p in query, where: p.visibility == ^visibility
      else
        query
      end

    total = Repo.aggregate(query, :count, :id)
    offset = (page - 1) * per_page
    posts = Repo.all(from q in query, limit: ^per_page, offset: ^offset)

    %{posts: posts, total: total, page: page, per_page: per_page, total_pages: ceil(total / per_page)}
  end

  @doc "Récupère un post avec tout preloadé pour la fiche admin"
  def get_post_admin(id) do
    post = Repo.get(Post, id)

    if post do
      Repo.preload(post, [
        :user,
        :images,
        :shares,
        reactions: [],
        date_applications: [:user],
        comments: {comments_query(), [:user, replies: [:user]]}
      ])
    end
  end

  @doc "Compte les posts par type"
  def count_posts_by_type do
    from(p in Post, group_by: p.post_type, select: {p.post_type, count(p.id)})
    |> Repo.all()
    |> Map.new()
  end

  @doc "Supprime un post + ses images physiques"
  def admin_delete_post(%Post{} = post) do
    post_with_images = Repo.preload(post, :images)
    Enum.each(post_with_images.images, fn img ->
      path = Path.join(["priv/static/uploads/posts", img.filename])
      File.rm(path)
    end)
    Repo.delete(post)
  end

  @doc "Change la visibilité d'un post"
  def update_post_visibility(%Post{} = post, visibility) do
    post
    |> Ecto.Changeset.change(%{visibility: visibility})
    |> Repo.update()
  end

  @doc "Change le statut d'une date"
  def update_date_status(%Post{} = post, status) do
    post
    |> Ecto.Changeset.change(%{date_status: status})
    |> Repo.update()
  end

  @doc "Supprime un commentaire"
  def admin_delete_comment(%Comment{} = comment) do
    Repo.delete(comment)
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
      Repo.preload(post, [:user, :images, :reactions, :shares, date_applications: :user,
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

  # ============== DATE POSTS ==============

  @doc "Crée un post de type date"
  def create_date_post(attrs) do
    %Post{}
    |> Post.date_changeset(attrs)
    |> Repo.insert()
  end

  @doc "Change un date post (pour les formulaires)"
  def change_date_post(%Post{} = post, attrs \\ %{}) do
    Post.date_changeset(post, attrs)
  end

  @doc "Met à jour un date post"
  def update_date_post(%Post{} = post, attrs) do
    post
    |> Post.date_changeset(attrs)
    |> Repo.update()
  end

  @doc "Met à jour le statut d'un date post"
  def update_date_status(%Post{} = post, status) do
    post
    |> Post.date_changeset(%{date_status: status})
    |> Repo.update()
  end

  @doc "Liste les posts date avec pagination"
  def list_date_posts_for_user(user_id, page \\ 1, per_page \\ @posts_per_page) do
    offset = (page - 1) * per_page
    friend_ids = Social.list_friends(user_id) |> Enum.map(& &1.id)

    posts =
      Post
      |> where([p], p.post_type == "date")
      |> where([p],
        p.visibility == "public" or
        p.user_id == ^user_id or
        (p.visibility == "friends" and p.user_id in ^friend_ids)
      )
      |> order_by(desc: :inserted_at)
      |> limit(^(per_page + 1))
      |> offset(^offset)
      |> Repo.all()
      |> Repo.preload([:user, :images, :reactions, :shares, :date_applications,
        shared_post: [:user, :images],
        comments: {comments_query(), [:user, :images, :reactions, replies: [:user, :images, :reactions]]}])

    has_more? = length(posts) > per_page
    posts = Enum.take(posts, per_page)

    {posts, has_more?}
  end

  @doc "Liste mes date posts (ceux que j'ai créés)"
  @doc "Compte les dates par catégorie pour un utilisateur"
  def count_user_dates_by_category(user_id) do
    Post
    |> where([p], p.post_type == "date" and p.user_id == ^user_id)
    |> group_by([p], p.date_category)
    |> select([p], {p.date_category, count(p.id)})
    |> Repo.all()
    |> Map.new()
  end

  @doc "Compte le total de dates d'un utilisateur"
  def count_user_dates(user_id) do
    Post
    |> where([p], p.post_type == "date" and p.user_id == ^user_id)
    |> Repo.aggregate(:count)
  end

  @doc "Compte le total de publications standard d'un utilisateur"
  def count_user_posts(user_id) do
    Post
    |> where([p], p.post_type == "standard" and p.user_id == ^user_id)
    |> Repo.aggregate(:count)
  end

  @doc "Liste les posts standard d'un user avec pagination"
  def list_user_standard_posts_paginated(user_id, page, per_page \\ 10) do
    offset = (page - 1) * per_page

    posts =
      Post
      |> where([p], p.post_type == "standard" and p.user_id == ^user_id)
      |> order_by(desc: :inserted_at)
      |> limit(^(per_page + 1))
      |> offset(^offset)
      |> Repo.all()
      |> Repo.preload([:user, :images, :reactions, :shares,
        shared_post: [:user, :images],
        comments: {comments_query(), [:user, :images, :reactions, replies: [:user, :images, :reactions]]}])

    has_more = length(posts) > per_page
    {Enum.take(posts, per_page), has_more}
  end

  @doc "Liste les date posts d'un user avec pagination"
  def list_user_date_posts_paginated(user_id, page, per_page \\ 10) do
    offset = (page - 1) * per_page

    posts =
      Post
      |> where([p], p.post_type == "date" and p.user_id == ^user_id)
      |> order_by(desc: :inserted_at)
      |> limit(^(per_page + 1))
      |> offset(^offset)
      |> Repo.all()
      |> Repo.preload([:user, :images, :reactions, :shares, [date_applications: :user],
        shared_post: [:user, :images],
        comments: {comments_query(), [:user, :images, :reactions, replies: [:user, :images, :reactions]]}])

    has_more = length(posts) > per_page
    {Enum.take(posts, per_page), has_more}
  end

  def list_my_date_posts(user_id) do
    Post
    |> where([p], p.post_type == "date" and p.user_id == ^user_id)
    |> order_by(desc: :inserted_at)
    |> Repo.all()
    |> Repo.preload([:user, :images, :reactions, :shares, [date_applications: :user],
      shared_post: [:user, :images],
      comments: {comments_query(), [:user, :images, :reactions, replies: [:user, :images, :reactions]]}])
  end

  @doc "Liste les dates auxquels j'ai postulé"
  def list_my_date_applications(user_id) do
    applications =
      DateApplication
      |> where(user_id: ^user_id)
      |> order_by(desc: :inserted_at)
      |> preload(:user)
      |> Repo.all()

    post_ids = Enum.map(applications, & &1.post_id)

    posts =
      Post
      |> where([p], p.id in ^post_ids)
      |> Repo.all()
      |> Repo.preload([:user, :images, :reactions, :shares, [date_applications: :user],
        shared_post: [:user, :images],
        comments: {comments_query(), [:user, :images, :reactions, replies: [:user, :images, :reactions]]}])
      |> Map.new(fn p -> {p.id, p} end)

    Enum.map(applications, fn app ->
      %{app | post: Map.get(posts, app.post_id)}
    end)
  end

  # ============== DATE APPLICATIONS ==============

  @doc "Postuler à un date"
  def apply_to_date(user_id, post_id, message \\ nil) do
    post = Repo.get(Post, post_id)

    if post && post.user_id == user_id do
      {:error, :cannot_apply_to_own_post}
    else
      %DateApplication{}
      |> DateApplication.changeset(%{user_id: user_id, post_id: post_id, message: message})
      |> Repo.insert()
    end
  end

  @doc "Accepter une candidature + auto-ami + auto-full + auto-chat"
  def accept_date_application(application_id) do
    case Repo.get(DateApplication, application_id) |> Repo.preload(:post) do
      nil ->
        {:error, :not_found}

      application ->
        result =
          application
          |> DateApplication.changeset(%{status: "accepted"})
          |> Repo.update()

        case result do
          {:ok, updated_app} ->
            post = application.post

            # Auto-friend : créer amitié directement acceptée
            ensure_friends(post.user_id, application.user_id)

            # Vérifier si le date est complet
            accepted_count = count_accepted_applications(post.id)
            if accepted_count >= post.date_spots do
              update_date_status(post, "full")
            end

            # Auto-chat : créer ou récupérer la conversation et envoyer un message
            send_date_accepted_message(post, application.user_id)

            # Notifier le candidat
            Phoenix.PubSub.broadcast(
              MonApp.PubSub,
              "user:#{application.user_id}",
              {:date_application_accepted, updated_app}
            )

            {:ok, updated_app}

          error ->
            error
        end
    end
  end

  defp ensure_friends(user_id, other_id) do
    alias MonApp.Social.Friendship

    existing = Social.get_friendship(user_id, other_id)

    case existing do
      nil ->
        # Créer directement une amitié acceptée
        %Friendship{}
        |> Friendship.changeset(%{user_id: user_id, friend_id: other_id, status: "accepted"})
        |> Repo.insert()

      %{status: "pending"} ->
        # Accepter la demande existante
        existing
        |> Friendship.changeset(%{status: "accepted"})
        |> Repo.update()

      %{status: "accepted"} ->
        # Déjà amis
        {:ok, existing}
    end
  end

  defp send_date_accepted_message(post, applicant_id) do
    alias MonApp.Chat

    if post.date_spots > 1 do
      # Group chat pour les dates multi-places
      send_date_group_message(post, applicant_id)
    else
      # Chat 1-à-1 pour les dates single-place
      send_date_direct_message(post, applicant_id)
    end
  end

  defp send_date_direct_message(post, applicant_id) do
    alias MonApp.Chat

    case Chat.force_get_or_create_conversation(post.user_id, applicant_id) do
      {:ok, conversation} ->
        category = Post.date_category_emoji(post.date_category)
        datetime = if post.date_datetime, do: Calendar.strftime(post.date_datetime, " le %d/%m à %Hh%M"), else: ""
        location = if post.date_location && post.date_location != "", do: " à #{post.date_location}", else: ""

        message = "#{category} Date accepté ! « #{post.date_title} »#{location}#{datetime}. On se retrouve bientôt ! 💘"

        Chat.create_message(%{
          conversation_id: conversation.id,
          sender_id: post.user_id,
          body: message
        })

        Phoenix.PubSub.broadcast(
          MonApp.PubSub,
          "conversation:#{conversation.id}",
          {:new_message, %{conversation_id: conversation.id}}
        )

        Phoenix.PubSub.broadcast(
          MonApp.PubSub,
          "user:#{applicant_id}",
          {:new_message, %{conversation_id: conversation.id}}
        )

      {:error, _} ->
        :ok
    end
  end

  defp send_date_group_message(post, applicant_id) do
    alias MonApp.Chat

    group_name = "#{Post.date_category_emoji(post.date_category)} #{post.date_title}"

    case Chat.get_or_create_date_group_conversation(post.user_id, group_name) do
      {:ok, conversation} ->
        # Ajouter le nouveau participant au groupe
        Chat.add_date_participant(conversation.id, applicant_id)

        # Charger le nom du candidat
        applicant = MonApp.Accounts.get_user(applicant_id)
        applicant_name = if applicant, do: applicant.name, else: "Quelqu'un"

        category = Post.date_category_emoji(post.date_category)
        datetime = if post.date_datetime, do: Calendar.strftime(post.date_datetime, " le %d/%m à %Hh%M"), else: ""
        location = if post.date_location && post.date_location != "", do: " à #{post.date_location}", else: ""

        message = "#{category} #{applicant_name} rejoint le date « #{post.date_title} »#{location}#{datetime} ! Bienvenue ! 💘"

        Chat.create_message(%{
          conversation_id: conversation.id,
          sender_id: post.user_id,
          body: message
        })

        # Notifier tous les participants du groupe
        Phoenix.PubSub.broadcast(
          MonApp.PubSub,
          "conversation:#{conversation.id}",
          {:new_message, %{conversation_id: conversation.id}}
        )

        Phoenix.PubSub.broadcast(
          MonApp.PubSub,
          "user:#{applicant_id}",
          {:new_message, %{conversation_id: conversation.id}}
        )

      {:error, _} ->
        :ok
    end
  end

  @doc "Refuser une candidature"
  def reject_date_application(application_id) do
    case Repo.get(DateApplication, application_id) do
      nil ->
        {:error, :not_found}

      application ->
        application
        |> DateApplication.changeset(%{status: "rejected"})
        |> Repo.update()
    end
  end

  @doc "Liste les candidatures d'un date post"
  def list_date_applications(post_id) do
    DateApplication
    |> where(post_id: ^post_id)
    |> order_by(asc: :inserted_at)
    |> preload(:user)
    |> Repo.all()
  end

  @doc "Candidatures en attente d'un date post"
  def list_pending_date_applications(post_id) do
    DateApplication
    |> where(post_id: ^post_id, status: "pending")
    |> order_by(asc: :inserted_at)
    |> preload(:user)
    |> Repo.all()
  end

  @doc "Candidatures acceptées d'un date post"
  def list_accepted_date_applications(post_id) do
    DateApplication
    |> where(post_id: ^post_id, status: "accepted")
    |> preload(:user)
    |> Repo.all()
  end

  @doc "Compte les candidatures acceptées"
  def count_accepted_applications(post_id) do
    DateApplication
    |> where(post_id: ^post_id, status: "accepted")
    |> Repo.aggregate(:count)
  end

  @doc "Vérifie si un user a déjà postulé"
  def has_applied?(user_id, post_id) do
    DateApplication
    |> where(user_id: ^user_id, post_id: ^post_id)
    |> Repo.exists?()
  end

  @doc "Récupère la candidature d'un user sur un date"
  def get_user_application(user_id, post_id) do
    DateApplication
    |> where(user_id: ^user_id, post_id: ^post_id)
    |> Repo.one()
  end

  @doc "Annuler sa candidature"
  def cancel_date_application(user_id, post_id) do
    case get_user_application(user_id, post_id) do
      nil -> {:error, :not_found}
      %{status: "pending"} = app -> Repo.delete(app)
      _ -> {:error, :cannot_cancel}
    end
  end
end
