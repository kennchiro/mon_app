defmodule MonAppWeb.FetchCurrentUser do
  @moduledoc "Plug qui charge le user depuis la session"

  import Plug.Conn

  alias MonApp.Accounts

  def init(opts), do: opts

  def call(conn, _opts) do
    user_id = get_session(conn, :user_id)

    if user_id do
      user = Accounts.get_user(user_id)
      assign(conn, :current_user, user)
    else
      assign(conn, :current_user, nil)
    end
  end
end
