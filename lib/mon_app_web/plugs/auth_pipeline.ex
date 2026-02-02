defmodule MonAppWeb.AuthPipeline do
  use Guardian.Plug.Pipeline,
    otp_app: :mon_app,
    module: MonApp.Guardian,
    error_handler: MonAppWeb.AuthErrorHandler

  # Vérifie le token dans le header Authorization
  plug Guardian.Plug.VerifyHeader, scheme: "Bearer"

  # Charge le user si le token est valide
  plug Guardian.Plug.LoadResource, allow_blank: true
end
