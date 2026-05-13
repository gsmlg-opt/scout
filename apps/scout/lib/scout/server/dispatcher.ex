defmodule Scout.Server.Dispatcher do
  @moduledoc """
  Dispatches Scout fetch jobs to either RabbitMQ or the local executor.
  """

  alias Scout.Agent.Executor
  alias Scout.Fetch.Job
  alias Scout.Server.{JobManager, RabbitMQ, ResultHandler}

  def dispatch(%Job{} = job) do
    case dispatch_mode() do
      :rabbitmq -> RabbitMQ.publish_job(job)
      :local -> dispatch_local(job)
    end
  end

  defp dispatch_mode do
    Application.get_env(:scout, :dispatch_mode, :local)
  end

  defp dispatch_local(job) do
    case Task.Supervisor.start_child(Scout.TaskSupervisor, fn ->
           JobManager.mark_running(job.job_id)
           job |> Executor.fetch() |> ResultHandler.handle_result()
         end) do
      {:ok, _pid} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end
end
