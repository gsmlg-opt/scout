defmodule Scout.Server.ResultHandler do
  @moduledoc false

  alias Scout.Fetch.Result
  alias Scout.Server.JobManager

  def handle_result(%Result{} = result) do
    JobManager.handle_result(result)
  end

  def handle_result(map) when is_map(map) do
    map
    |> Result.from_map()
    |> handle_result()
  end
end
