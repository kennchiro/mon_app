defmodule MonApp.Guardian do
  use Guardian, otp_app: :mon_app

  alias MonApp.Accounts

  @doc "Encode l'ID du user dans le token"
  def subject_for_token(user, _claims) do
    {:ok, to_string(user.id)}
  end

  @doc "Récupère le user depuis le token"
  def resource_from_claims(%{"sub" => id}) do
    case Accounts.get_user(id) do
      nil -> {:error, :user_not_found}
      user -> {:ok, user}
    end
  end
end
