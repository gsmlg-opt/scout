defmodule Scout.Agent.AMQPConsumer do
  @moduledoc """
  RabbitMQ consumer for Scout Agent mode.
  """

  use GenServer

  alias AMQP.Basic
  alias Scout.Agent
  alias Scout.Fetch.{Job, Result}
  alias Scout.RabbitMQ
  alias Scout.Settings

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    with {:ok, connection, channel} <- RabbitMQ.open_channel(),
         queue <- Settings.get()["rabbitmq"]["queues"]["jobs"],
         {:ok, _consumer_tag} <- Basic.consume(channel, queue, nil, no_ack: false) do
      {:ok, %{connection: connection, channel: channel}}
    else
      {:error, reason} -> {:stop, reason}
    end
  end

  @impl true
  def handle_info({:basic_deliver, payload, meta}, state) do
    result =
      with {:ok, map} <- Jason.decode(payload),
           {:ok, job} <- Job.from_map(map) do
        Agent.fetch(job)
      else
        error ->
          %Result{
            job_id: nil,
            ok: false,
            url: nil,
            error: %{type: "invalid_job", message: inspect(error), retryable: false}
          }
      end

    _ = RabbitMQ.publish_result(result)
    Basic.ack(state.channel, meta.delivery_tag)
    {:noreply, state}
  end

  def handle_info({:basic_consume_ok, _meta}, state), do: {:noreply, state}
  def handle_info({:basic_cancel, _meta}, state), do: {:stop, :normal, state}
  def handle_info({:basic_cancel_ok, _meta}, state), do: {:noreply, state}
end
