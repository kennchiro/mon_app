# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     MonApp.Repo.insert!(%MonApp.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something went wrong.

alias MonApp.Repo
alias MonApp.Accounts.User

# ============== ADMIN SEED ==============
# Crée le premier compte admin si aucun n'existe

admin_email = System.get_env("ADMIN_EMAIL", "admin@dateapp.com")
admin_password = System.get_env("ADMIN_PASSWORD", "admin123456")

case Repo.get_by(User, email: admin_email) do
  nil ->
    %User{}
    |> User.registration_changeset(%{
      name: "admin",
      email: admin_email,
      password: admin_password
    })
    |> Ecto.Changeset.put_change(:role, "admin")
    |> Repo.insert!()

    IO.puts("✅ Compte admin créé : #{admin_email}")

  user ->
    if user.role != "admin" do
      user
      |> User.role_changeset(%{role: "admin"})
      |> Repo.update!()
      IO.puts("✅ Compte #{admin_email} promu admin")
    else
      IO.puts("ℹ️  Compte admin déjà existant : #{admin_email}")
    end
end
