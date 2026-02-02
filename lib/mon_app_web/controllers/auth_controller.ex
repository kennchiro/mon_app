defmodule MonAppWeb.AuthController do
  use MonAppWeb, :controller

  alias MonApp.Accounts
  alias MonApp.Guardian

  @doc "POST /auth/register"
  def register(conn, %{"user" => user_params}) do
    case Accounts.register_user(user_params) do
      {:ok, user} ->
        {:ok, token, _claims} = Guardian.encode_and_sign(user)

        conn
        |> put_status(:created)
        |> render(:auth, user: user, token: token)

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(:error, changeset: changeset)
    end
  end

  @doc "POST /auth/login"
  def login(conn, %{"email" => email, "password" => password}) do
    case Accounts.authenticate_user(email, password) do
      {:ok, user} ->
        {:ok, token, _claims} = Guardian.encode_and_sign(user)
        render(conn, :auth, user: user, token: token)

      {:error, _reason} ->
        conn
        |> put_status(:unauthorized)
        |> render(:error, message: "Email ou mot de passe invalide")
    end
  end

  @doc "GET /auth/me - Retourne le user connecté"
  def me(conn, _params) do
    user = Guardian.Plug.current_resource(conn)
    render(conn, :user, user: user)
  end
end
