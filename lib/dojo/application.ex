defmodule Dojo.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      Dojo.Repo,
      # Start the Telemetry supervisor
      DojoWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: Dojo.PubSub},
      # Start the Endpoint (http/https)
      DojoWeb.Endpoint,
      # Start a worker by calling: Dojo.Worker.start_link(arg)
      # {Dojo.Worker, arg}
      # Start the Game dynamic supervisor
      GameSupervisor,
      {Registry, keys: :unique, name: GameRegistry}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Dojo.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    DojoWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
