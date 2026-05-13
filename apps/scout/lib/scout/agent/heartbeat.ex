defmodule Scout.Agent.Heartbeat do
  @moduledoc false

  use GenServer

  alias Scout.Server.{AgentRegistry, JobManager, RabbitMQ}
  alias Scout.Settings

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @impl true
  def init(state) do
    send(self(), :heartbeat)
    {:ok, state}
  end

  @impl true
  def handle_info(:heartbeat, state) do
    heartbeat = heartbeat()

    AgentRegistry.update_heartbeat(heartbeat)

    if RabbitMQ.enabled?() do
      _ = RabbitMQ.publish_heartbeat(heartbeat)
    end

    Process.send_after(self(), :heartbeat, interval_ms())
    {:noreply, state}
  end

  defp heartbeat do
    settings = Settings.get()
    agent = settings["agent"]

    %{
      agent_id: agent["id"],
      region: agent["region"],
      status: "healthy",
      running_jobs: running_jobs(),
      capacity: agent["capacity"],
      version: Application.spec(:scout, :vsn) |> to_string(),
      timestamp: DateTime.utc_now() |> DateTime.to_iso8601()
    }
  end

  defp running_jobs do
    if Process.whereis(JobManager) do
      JobManager.running_count()
    else
      0
    end
  end

  defp interval_ms do
    Settings.get()["agent"]["heartbeat_interval_ms"]
  end
end
