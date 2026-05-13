defmodule Scout.Fetch.RetryPolicy do
  @moduledoc false

  alias Scout.Fetch.Result
  alias Scout.Settings

  @retryable_types ~w(timeout temporary_network_failure 429 502 503 browser_crash browser_unavailable command_failed)

  def retryable?(%Result{ok: true}), do: false

  def retryable?(%Result{error: %{retryable: true}}), do: true

  def retryable?(%Result{error: %{type: type}}) do
    to_string(type) in @retryable_types
  end

  def retryable?(_result), do: false

  def delay_ms(attempt, settings \\ Settings.get()) do
    retry = settings["fetch"]["retry"]
    base = retry["base_backoff_ms"]
    max_delay = retry["max_backoff_ms"]
    exponential = base * trunc(:math.pow(2, max(attempt - 1, 0)))
    delay = min(exponential, max_delay)

    if retry["jitter"] do
      delay + :rand.uniform(max(div(delay, 2), 1))
    else
      delay
    end
  end
end
