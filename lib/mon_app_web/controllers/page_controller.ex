defmodule MonAppWeb.PageController do
  use MonAppWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end

  def redirect_to_conversations(conn, _params) do
    redirect(conn, to: ~p"/conversations")
  end
end
