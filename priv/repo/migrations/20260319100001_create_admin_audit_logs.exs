defmodule MonApp.Repo.Migrations.CreateAdminAuditLogs do
  use Ecto.Migration

  def change do
    create table(:admin_audit_logs) do
      add :admin_id, references(:users, on_delete: :nilify_all)
      add :action, :string, null: false
      add :target_type, :string
      add :target_id, :integer
      add :metadata, :map, default: %{}
      add :ip_address, :string

      timestamps(updated_at: false)
    end

    create index(:admin_audit_logs, [:admin_id])
    create index(:admin_audit_logs, [:action])
    create index(:admin_audit_logs, [:target_type, :target_id])
    create index(:admin_audit_logs, [:inserted_at])
  end
end
