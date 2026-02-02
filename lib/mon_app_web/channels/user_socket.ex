defmodule MonAppWeb.UserSocket do
  use Phoenix.Socket

  alias MonApp.Accounts

  # Channels
  channel "chat:*", MonAppWeb.ChatChannel
  channel "user:*", MonAppWeb.UserChannel

  @impl true
  def connect(%{"token" => token}, socket, _connect_info) do
    case Phoenix.Token.verify(MonAppWeb.Endpoint, "user socket", token, max_age: 86400) do
      {:ok, user_id} ->
        user = Accounts.get_user(user_id)
        if user do
          {:ok, assign(socket, :current_user, user)}
        else
          :error
        end

      {:error, _reason} ->
        :error
    end
  end

  def connect(_params, _socket, _connect_info), do: :error

  @impl true
  def id(socket), do: "user_socket:#{socket.assigns.current_user.id}"
end
