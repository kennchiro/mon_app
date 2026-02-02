defmodule MonAppWeb.LiveAuth do
  @moduledoc "Hooks pour l'authentification dans LiveView"

  import Phoenix.LiveView
  import Phoenix.Component

  alias MonApp.Accounts

  @doc "Charge le user courant dans les assigns"
  def on_mount(:fetch_current_user, _params, session, socket) do
    user =
      case session["user_id"] do
        nil -> nil
        user_id -> Accounts.get_user(user_id)
      end

    {:cont, assign(socket, :current_user, user)}
  end

  @doc "Requiert un user connecté, sinon redirige vers login"
  def on_mount(:require_authenticated_user, _params, session, socket) do
    case session["user_id"] do
      nil ->
        {:halt,
         socket
         |> put_flash(:error, "Vous devez être connecté")
         |> redirect(to: "/login")}

      user_id ->
        user = Accounts.get_user(user_id)

        if user do
          {:cont, assign(socket, :current_user, user)}
        else
          {:halt,
           socket
           |> put_flash(:error, "Session invalide")
           |> redirect(to: "/login")}
        end
    end
  end

  @doc "Redirige vers posts si déjà connecté"
  def on_mount(:redirect_if_authenticated, _params, session, socket) do
    case session["user_id"] do
      nil ->
        {:cont, assign(socket, :current_user, nil)}

      _user_id ->
        {:halt, redirect(socket, to: "/posts")}
    end
  end
end
