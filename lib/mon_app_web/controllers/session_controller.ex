defmodule MonAppWeb.SessionController do
  use MonAppWeb, :controller

  alias MonApp.Accounts

  def create(conn, %{"email" => email, "password" => password}) do
    case Accounts.authenticate_user(email, password) do
      {:ok, user} ->
        conn
        |> put_session(:user_id, user.id)
        |> put_flash(:info, "Bienvenue #{user.name} !")
        |> redirect(to: ~p"/posts")

      {:error, _reason} ->
        conn
        |> put_flash(:error, "Email ou mot de passe invalide")
        |> redirect(to: ~p"/login")
    end
  end

  def delete(conn, _params) do
    conn
    |> clear_session()
    |> put_flash(:info, "Déconnecté avec succès")
    |> redirect(to: ~p"/login")
  end
end
