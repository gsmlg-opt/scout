defmodule Scout.Server.HeartbeatConsumer do
  @moduledoc """
  RabbitMQ consumer for Scout agent heartbeat payloads.
  """

  use GenServer

  alias AMQP.Basic
  alias Scout.RabbitMQ
  alias Scout.Server.AgentRegistry
  alias Scout.Settings

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(opts) do
    with {:ok, connection, channel} <- RabbitMQ.open_channel(),
         queue <- Settings.get()["rabbitmq"]["queues"][Keyword.fetch!(opts, :queue)],
         {:ok, _consumer_tag} <- Basic.consume(channel, queue, nil, no_ack: false) do
      {:ok, %{connection: connection, channel: channel}}
    else
      {:error, reason} -> {:stop, reason}
    end
  end

  @impl true
  def handle_info({:basic_deliver, payload, meta}, state) do
    with {:ok, heartbeat} <- Jason.decode(payload) do
      AgentRegistry.update_heartbeat(heartbeat)
    end

    Basic.ack(state.channel, meta.delivery_tag)
    {:noreply, state}
  end

  def handle_info({:basic_consume_ok, _meta}, state), do: {:noreply, state}
  def handle_info({:basic_cancel, _meta}, state), do: {:stop, :normal, state}
  def handle_info({:basic_cancel_ok, _meta}, state), do: {:noreply, state}
end
