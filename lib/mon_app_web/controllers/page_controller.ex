defmodule MonAppWeb.PageController do
  use MonAppWeb, :controller

  def home(conn, _params) do
    if conn.assigns[:current_user] do
      redirect(conn, to: ~p"/posts")
    else
      redirect(conn, to: ~p"/welcome")
    end
  end

  def redirect_to_conversations(conn, _params) do
    redirect(conn, to: ~p"/conversations")
  end
end
