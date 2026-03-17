defmodule MonApp.Social.UserBlock do
  use Ecto.Schema
  import Ecto.Changeset

  alias MonApp.Accounts.User

  schema "user_blocks" do
    belongs_to :blocker, User
    belongs_to :blocked, User
    timestamps()
  end

  def changeset(block, attrs) do
    block
    |> cast(attrs, [:blocker_id, :blocked_id])
    |> validate_required([:blocker_id, :blocked_id])
    |> unique_constraint([:blocker_id, :blocked_id], message: "déjà bloqué")
  end
end
