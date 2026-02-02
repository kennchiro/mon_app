defmodule MonAppWeb.PageController do
  use MonAppWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
