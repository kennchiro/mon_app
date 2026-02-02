defmodule MonAppWeb.PostJSON do
  alias MonApp.Blog.Post

  def index(%{posts: posts}) do
    %{data: for(post <- posts, do: data(post))}
  end

  def show(%{post: post}) do
    %{data: data(post)}
  end

  def error(%{changeset: changeset}) do
    %{errors: format_errors(changeset)}
  end

  def error(%{message: message}) do
    %{error: message}
  end

  # Format un post en JSON
  defp data(%Post{} = post) do
    %{
      id: post.id,
      title: post.title,
      body: post.body,
      published: post.published,
      user_id: post.user_id,
      user: user_data(post),
      inserted_at: post.inserted_at,
      updated_at: post.updated_at
    }
  end

  # Inclut les données du user si préchargé
  defp user_data(%{user: %Ecto.Association.NotLoaded{}}), do: nil
  defp user_data(%{user: nil}), do: nil
  defp user_data(%{user: user}) do
    %{
      id: user.id,
      name: user.name,
      email: user.email
    }
  end

  defp format_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end
end
