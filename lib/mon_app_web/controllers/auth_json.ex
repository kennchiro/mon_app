defmodule MonAppWeb.AuthJSON do
  def auth(%{user: user, token: token}) do
    %{
      data: %{
        user: %{
          id: user.id,
          name: user.name,
          email: user.email
        },
        token: token
      }
    }
  end

  def user(%{user: user}) do
    %{
      data: %{
        id: user.id,
        name: user.name,
        email: user.email
      }
    }
  end

  def error(%{changeset: changeset}) do
    %{errors: format_errors(changeset)}
  end

  def error(%{message: message}) do
    %{error: message}
  end

  defp format_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end
end
