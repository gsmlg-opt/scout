defmodule Scout.Agent.Lightpanda do
  @moduledoc """
  Lightpanda adapter boundary.
  """

  @callback fetch(String.t(), map()) :: {:ok, map()} | {:error, map()}

  def fetch(url, opts \\ %{}) do
    adapter().fetch(url, opts)
  end

  defp adapter do
    Application.get_env(:scout_agent, :lightpanda_adapter, Scout.Agent.Lightpanda.CLI)
  end
end
