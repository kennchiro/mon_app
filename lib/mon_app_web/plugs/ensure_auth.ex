defmodule MonAppWeb.EnsureAuth do
  @moduledoc "Plug qui vérifie qu'un user est authentifié"

  import Plug.Conn
  import Phoenix.Controller

  def init(opts), do: opts

  def call(conn, _opts) do
    case MonApp.Guardian.Plug.current_resource(conn) do
      nil ->
        conn
        |> put_status(:unauthorized)
        |> put_view(json: MonAppWeb.AuthJSON)
        |> render(:error, message: "Token manquant ou invalide")
        |> halt()

      _user ->
        conn
    end
  end
end
