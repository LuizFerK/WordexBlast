defmodule WordexBlast.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      WordexBlastWeb.Telemetry,
      # Start the Ecto repository
      WordexBlast.Repo,
      # Start the PubSub system
      {Phoenix.PubSub, name: WordexBlast.PubSub},
      # Start Presence
      WordexBlastWeb.Presence,
      # Rooms
      WordexBlast.Rooms,
      # Start Finch
      {Finch, name: WordexBlast.Finch},
      # Start the Endpoint (http/https)
      WordexBlastWeb.Endpoint
      # Start a worker by calling: WordexBlast.Worker.start_link(arg)
      # {WordexBlast.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: WordexBlast.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    WordexBlastWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
