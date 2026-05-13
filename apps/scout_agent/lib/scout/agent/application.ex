defmodule Scout.Agent.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children =
      [
        Scout.Agent.LightpandaPool,
        Scout.Agent.Heartbeat,
        maybe_rabbitmq_consumer()
      ]
      |> Enum.reject(&is_nil/1)

    Supervisor.start_link(children, strategy: :one_for_one, name: Scout.Agent.Supervisor)
  end

  defp maybe_rabbitmq_consumer do
    if Scout.RabbitMQ.enabled?() and Application.get_env(:scout_agent, :consumer_enabled, true) do
      Scout.Agent.AMQPConsumer
    end
  end
end
