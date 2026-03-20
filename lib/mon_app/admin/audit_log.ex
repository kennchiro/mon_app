defmodule MonApp.Admin.AuditLog do
  use Ecto.Schema
  import Ecto.Changeset

  alias MonApp.Accounts.User

  schema "admin_audit_logs" do
    belongs_to :admin, User
    field :action, :string
    field :target_type, :string
    field :target_id, :integer
    field :metadata, :map, default: %{}
    field :ip_address, :string

    timestamps(updated_at: false)
  end

  def changeset(log, attrs) do
    log
    |> cast(attrs, [:admin_id, :action, :target_type, :target_id, :metadata, :ip_address])
    |> validate_required([:action])
  end
end
