defmodule Bleep.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      BleepWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: Bleep.PubSub},
      # Start Finch
      {Finch, name: Bleep.Finch},
      # Start the Endpoint (http/https)
      BleepWeb.Endpoint
      # Start a worker by calling: Bleep.Worker.start_link(arg)
      # {Bleep.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Bleep.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    BleepWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
