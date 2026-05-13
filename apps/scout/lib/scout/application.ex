defmodule Scout.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children =
      [
        {Task.Supervisor, name: Scout.TaskSupervisor},
        Scout.Settings,
        {Phoenix.PubSub, name: Scout.PubSub},
        Scout.Server.AgentRegistry,
        Scout.Server.JobManager,
        Scout.Agent.Heartbeat,
        {DNSCluster, query: Application.get_env(:scout, :dns_cluster_query) || :ignore},
        maybe_agent_consumer()
      ]
      |> Enum.reject(&is_nil/1)

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Scout.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp maybe_agent_consumer do
    if Application.get_env(:scout, :agent_enabled, false) do
      Scout.Agent.AMQPConsumer
    end
  end
end
