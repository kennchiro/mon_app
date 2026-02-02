defmodule MonAppWeb.UserController do
  use MonAppWeb, :controller

  alias MonApp.Accounts
  alias MonApp.Accounts.User

  # GET /api/users
  def index(conn, _params) do
    users = Accounts.list_users()
    render(conn, :index, users: users)
  end

  # GET /api/users/:id
  def show(conn, %{"id" => id}) do
    case Accounts.get_user(id) do
      nil ->
        conn
        |> put_status(:not_found)
        |> render(:error, message: "User not found")

      user ->
        render(conn, :show, user: user)
    end
  end

  # POST /api/users
  def create(conn, %{"user" => user_params}) do
    case Accounts.create_user(user_params) do
      {:ok, user} ->
        conn
        |> put_status(:created)
        |> render(:show, user: user)

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(:error, changeset: changeset)
    end
  end

  # PUT /api/users/:id
  def update(conn, %{"id" => id, "user" => user_params}) do
    case Accounts.get_user(id) do
      nil ->
        conn
        |> put_status(:not_found)
        |> render(:error, message: "User not found")

      user ->
        case Accounts.update_user(user, user_params) do
          {:ok, updated_user} ->
            render(conn, :show, user: updated_user)

          {:error, changeset} ->
            conn
            |> put_status(:unprocessable_entity)
            |> render(:error, changeset: changeset)
        end
    end
  end

  # DELETE /api/users/:id
  def delete(conn, %{"id" => id}) do
    case Accounts.get_user(id) do
      nil ->
        conn
        |> put_status(:not_found)
        |> render(:error, message: "User not found")

      user ->
        {:ok, _} = Accounts.delete_user(user)
        send_resp(conn, :no_content, "")
    end
  end
end
