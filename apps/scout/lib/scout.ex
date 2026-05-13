defmodule Scout do
  @moduledoc """
  Public boundary for Scout fetch jobs.

  Scout is intentionally narrow: URL in, Lightpanda-rendered Markdown out.
  """

  alias Scout.Server.API

  defdelegate submit_fetch(params), to: API
  defdelegate get_fetch(job_id), to: API
  defdelegate list_fetches(), to: API
  defdelegate fetch_sync(params), to: API
end
