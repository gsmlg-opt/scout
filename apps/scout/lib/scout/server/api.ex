defmodule Scout.Server.API do
  @moduledoc """
  Public server API for fetch job lifecycle operations.
  """

  alias Scout.Server.JobManager

  def submit_fetch(params), do: JobManager.submit(params)
  def get_fetch(job_id), do: JobManager.get(job_id)
  def list_fetches, do: JobManager.list()
  def fetch_sync(params), do: JobManager.fetch_sync(params)
end
