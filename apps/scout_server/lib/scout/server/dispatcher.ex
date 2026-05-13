defmodule Scout.Server.Dispatcher do
  @moduledoc """
  Dispatches Scout fetch jobs to either RabbitMQ or the local executor.
  """

  alias Scout.Fetch.Job
  alias Scout.RabbitMQ

  def dispatch(%Job{} = job) do
    publisher().publish_job(job)
  end

  defp publisher, do: Application.get_env(:scout_server, :job_publisher, RabbitMQ)
end
