defmodule MonAppWeb.AdminSessionController do
  use MonAppWeb, :controller

  alias MonApp.Accounts

  @doc "Crée la session admin après login LiveView"
  def create(conn, %{"user_id" => user_id}) do
    user = Accounts.get_user(user_id)

    if user && user.role in ["admin", "moderator"] do
      conn
      |> put_session(:user_id, user.id)
      |> redirect(to: ~p"/admin")
    else
      conn
      |> put_flash(:error, "Accès non autorisé")
      |> redirect(to: ~p"/admin/login")
    end
  end

  def create(conn, _params) do
    conn
    |> put_flash(:error, "Session invalide")
    |> redirect(to: ~p"/admin/login")
  end

  @doc "Déconnexion admin"
  def delete(conn, _params) do
    conn
    |> clear_session()
    |> put_flash(:info, "Déconnecté")
    |> redirect(to: ~p"/admin/login")
  end
end
