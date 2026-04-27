defmodule SearchAggregatorWeb.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      SearchAggregatorWeb.Telemetry,
      SearchAggregatorWeb.Endpoint
    ]

    opts = [strategy: :one_for_one, name: SearchAggregatorWeb.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl true
  def config_change(changed, _new, removed) do
    SearchAggregatorWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
