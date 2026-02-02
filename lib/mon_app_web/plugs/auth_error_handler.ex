defmodule MonAppWeb.AuthErrorHandler do
  import Plug.Conn
  import Phoenix.Controller

  @behaviour Guardian.Plug.ErrorHandler

  @impl Guardian.Plug.ErrorHandler
  def auth_error(conn, {type, _reason}, _opts) do
    message =
      case type do
        :unauthenticated -> "Token manquant"
        :invalid_token -> "Token invalide"
        :token_expired -> "Token expiré"
        _ -> "Erreur d'authentification"
      end

    conn
    |> put_status(:unauthorized)
    |> put_view(json: MonAppWeb.AuthJSON)
    |> render(:error, message: message)
    |> halt()
  end
end
