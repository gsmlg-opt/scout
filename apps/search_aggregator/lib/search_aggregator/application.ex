defmodule SearchAggregator.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Task.Supervisor, name: SearchAggregator.TaskSupervisor},
      SearchAggregator.Settings,
      {DNSCluster, query: Application.get_env(:search_aggregator, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: SearchAggregator.PubSub}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: SearchAggregator.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
