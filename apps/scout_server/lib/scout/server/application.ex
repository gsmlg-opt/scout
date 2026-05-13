defmodule Scout.Server.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children =
      [
        {Phoenix.PubSub, name: Scout.PubSub},
        Scout.Server.AgentRegistry,
        Scout.Server.JobManager,
        maybe_rabbitmq_consumer(Scout.Server.ResultConsumer, queue: "results"),
        maybe_rabbitmq_consumer(Scout.Server.ResultConsumer, queue: "failed"),
        maybe_rabbitmq_consumer(Scout.Server.HeartbeatConsumer, queue: "heartbeat"),
        {DNSCluster, query: Application.get_env(:scout_server, :dns_cluster_query) || :ignore}
      ]
      |> Enum.reject(&is_nil/1)

    Supervisor.start_link(children, strategy: :one_for_one, name: Scout.Server.Supervisor)
  end

  defp maybe_rabbitmq_consumer(module, opts) do
    if Scout.RabbitMQ.enabled?() and Application.get_env(:scout_server, :consumers_enabled, true) do
      {module, opts}
    end
  end
end
