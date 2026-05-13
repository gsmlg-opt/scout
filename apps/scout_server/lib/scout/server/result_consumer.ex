defmodule Scout.Server.ResultConsumer do
  @moduledoc """
  RabbitMQ consumer for fetch results emitted by Scout agents.
  """

  use GenServer

  alias AMQP.Basic
  alias Scout.Fetch.Result
  alias Scout.RabbitMQ
  alias Scout.Server.ResultHandler
  alias Scout.Settings

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: name(opts))
  end

  def child_spec(opts) do
    %{
      id: {__MODULE__, Keyword.fetch!(opts, :queue)},
      start: {__MODULE__, :start_link, [opts]},
      type: :worker
    }
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
    with {:ok, map} <- Jason.decode(payload) do
      map
      |> Result.from_map()
      |> ResultHandler.handle_result()
    end

    Basic.ack(state.channel, meta.delivery_tag)
    {:noreply, state}
  end

  def handle_info({:basic_consume_ok, _meta}, state), do: {:noreply, state}
  def handle_info({:basic_cancel, _meta}, state), do: {:stop, :normal, state}
  def handle_info({:basic_cancel_ok, _meta}, state), do: {:noreply, state}

  defp name(opts), do: :"#{__MODULE__}.#{Keyword.fetch!(opts, :queue)}"
end
