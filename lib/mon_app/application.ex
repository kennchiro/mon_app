defmodule MonApp.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      MonAppWeb.Telemetry,
      MonApp.Repo,
      {DNSCluster, query: Application.get_env(:mon_app, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: MonApp.PubSub},
      # Presence pour le tracking des utilisateurs en ligne
      MonAppWeb.Presence,
      # Start to serve requests, typically the last entry
      MonAppWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: MonApp.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    MonAppWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
