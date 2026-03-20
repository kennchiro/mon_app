defmodule MonAppWeb.EnsureAdmin do
  @moduledoc "Plug qui vérifie que le user courant est admin ou modérateur"

  import Plug.Conn
  import Phoenix.Controller

  alias MonApp.Accounts.User

  def init(opts), do: opts

  def call(conn, _opts) do
    case conn.assigns[:current_user] do
      %User{} = user when user.role in ["admin", "moderator"] ->
        conn

      _ ->
        conn
        |> put_flash(:error, "Accès non autorisé")
        |> redirect(to: "/login")
        |> halt()
    end
  end
end
