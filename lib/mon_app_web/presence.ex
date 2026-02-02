defmodule MonAppWeb.Presence do
  @moduledoc """
  Phoenix Presence pour tracker les utilisateurs en ligne.
  """

  use Phoenix.Presence,
    otp_app: :mon_app,
    pubsub_server: MonApp.PubSub

  @doc """
  Récupère la liste des utilisateurs en ligne.
  """
  def list_online_users do
    "users:online"
    |> list()
    |> Map.keys()
    |> Enum.map(&String.to_integer/1)
  end

  @doc """
  Vérifie si un utilisateur est en ligne.
  """
  def user_online?(user_id) do
    user_id
    |> to_string()
    |> then(&Map.has_key?(list("users:online"), &1))
  end

  @doc """
  Récupère les métadonnées d'un utilisateur connecté.
  """
  def get_user_presence(user_id) do
    case Map.get(list("users:online"), to_string(user_id)) do
      nil -> nil
      %{metas: [meta | _]} -> meta
    end
  end
end
