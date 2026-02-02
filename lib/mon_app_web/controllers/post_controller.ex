defmodule MonAppWeb.PostController do
  use MonAppWeb, :controller

  alias MonApp.Blog
  alias MonApp.Accounts

  # GET /api/posts
  def index(conn, _params) do
    posts = Blog.list_posts()
    render(conn, :index, posts: posts)
  end

  # GET /api/users/:user_id/posts
  def index_by_user(conn, %{"user_id" => user_id}) do
    posts = Blog.list_posts_by_user(user_id)
    render(conn, :index, posts: posts)
  end

  # GET /api/posts/:id
  def show(conn, %{"id" => id}) do
    case Blog.get_post_with_user(id) do
      nil ->
        conn
        |> put_status(:not_found)
        |> render(:error, message: "Post not found")

      post ->
        render(conn, :show, post: post)
    end
  end

  # POST /api/posts
  def create(conn, %{"post" => post_params}) do
    case Blog.create_post(post_params) do
      {:ok, post} ->
        conn
        |> put_status(:created)
        |> render(:show, post: post)

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(:error, changeset: changeset)
    end
  end

  # PUT /api/posts/:id
  def update(conn, %{"id" => id, "post" => post_params}) do
    case Blog.get_post(id) do
      nil ->
        conn
        |> put_status(:not_found)
        |> render(:error, message: "Post not found")

      post ->
        case Blog.update_post(post, post_params) do
          {:ok, updated_post} ->
            render(conn, :show, post: updated_post)

          {:error, changeset} ->
            conn
            |> put_status(:unprocessable_entity)
            |> render(:error, changeset: changeset)
        end
    end
  end

  # DELETE /api/posts/:id
  def delete(conn, %{"id" => id}) do
    case Blog.get_post(id) do
      nil ->
        conn
        |> put_status(:not_found)
        |> render(:error, message: "Post not found")

      post ->
        {:ok, _} = Blog.delete_post(post)
        send_resp(conn, :no_content, "")
    end
  end
end
