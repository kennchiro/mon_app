defmodule MonApp.Social.Friendship do
  use Ecto.Schema
  import Ecto.Changeset

  alias MonApp.Accounts.User

  schema "friendships" do
    field :status, :string, default: "pending"  # pending, accepted, rejected

    belongs_to :user, User       # Celui qui envoie la demande
    belongs_to :friend, User     # Celui qui reçoit la demande

    timestamps()
  end

  def changeset(friendship, attrs) do
    friendship
    |> cast(attrs, [:user_id, :friend_id, :status])
    |> validate_required([:user_id, :friend_id])
    |> validate_inclusion(:status, ["pending", "accepted", "rejected"])
    |> unique_constraint([:user_id, :friend_id], name: :friendships_unique)
    |> validate_not_self_friend()
  end

  defp validate_not_self_friend(changeset) do
    user_id = get_field(changeset, :user_id)
    friend_id = get_field(changeset, :friend_id)

    if user_id && friend_id && user_id == friend_id do
      add_error(changeset, :friend_id, "ne peut pas être soi-même")
    else
      changeset
    end
  end
end
