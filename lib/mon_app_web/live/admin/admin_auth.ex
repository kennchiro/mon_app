defmodule MonAppWeb.AdminAuth do
  @moduledoc "Hooks LiveView pour l'authentification admin"

  import Phoenix.LiveView
  import Phoenix.Component

  alias MonApp.Accounts

  @doc "Requiert un user admin/modérateur, sinon redirige vers /login"
  def on_mount(:require_admin, _params, session, socket) do
    case session["user_id"] do
      nil ->
        {:halt,
         socket
         |> put_flash(:error, "Accès non autorisé")
         |> redirect(to: "/login")}

      user_id ->
        user = Accounts.get_user(user_id)

        if user && user.role in ["admin", "moderator"] do
          {:cont, assign(socket, :current_admin, user)}
        else
          {:halt,
           socket
           |> put_flash(:error, "Accès non autorisé")
           |> redirect(to: "/login")}
        end
    end
  end

  @doc "Redirige vers /admin si déjà connecté en tant qu'admin"
  def on_mount(:redirect_if_admin, _params, session, socket) do
    case session["user_id"] do
      nil ->
        {:cont, assign(socket, :current_admin, nil)}

      user_id ->
        user = Accounts.get_user(user_id)

        if user && user.role in ["admin", "moderator"] do
          {:halt, redirect(socket, to: "/admin")}
        else
          {:cont, assign(socket, :current_admin, nil)}
        end
    end
  end
end
