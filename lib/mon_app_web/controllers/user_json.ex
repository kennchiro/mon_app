defmodule MonAppWeb.UserJSON do
  alias MonApp.Accounts.User

  @doc "Render liste de users"
  def index(%{users: users}) do
    %{data: for(user <- users, do: data(user))}
  end

  @doc "Render un seul user"
  def show(%{user: user}) do
    %{data: data(user)}
  end

  @doc "Render erreur"
  def error(%{changeset: changeset}) do
    %{errors: format_errors(changeset)}
  end

  def error(%{message: message}) do
    %{error: message}
  end

  # Format un user en JSON
  defp data(%User{} = user) do
    %{
      id: user.id,
      name: user.name,
      email: user.email,
      age: user.age,
      inserted_at: user.inserted_at,
      updated_at: user.updated_at
    }
  end

  # Format les erreurs de changeset
  defp format_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end
end
