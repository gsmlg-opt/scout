defmodule Scout.Settings do
  @moduledoc """
  Runtime loader for Scout's `settings.yaml` file.
  """

  use GenServer

  @default_settings %{
    "general" => %{
      "instance_name" => "Scout",
      "default_region" => "local",
      "request_timeout_ms" => 30_000
    },
    "rabbitmq" => %{
      "enabled" => false,
      "url" => "amqp://guest:guest@localhost:5672",
      "queues" => %{
        "jobs" => "scout.fetch.jobs",
        "results" => "scout.fetch.results",
        "failed" => "scout.fetch.failed",
        "heartbeat" => "scout.agent.heartbeat"
      },
      "regional_queues" => %{
        "eu" => "scout.fetch.jobs.eu",
        "us" => "scout.fetch.jobs.us",
        "asia" => "scout.fetch.jobs.asia"
      }
    },
    "fetch" => %{
      "default_timeout_ms" => 30_000,
      "max_timeout_ms" => 60_000,
      "max_page_size_bytes" => 5_000_000,
      "browser" => %{
        "wait_until" => "network_idle",
        "wait_for" => nil,
        "javascript" => true
      },
      "retry" => %{
        "max_attempts" => 3,
        "base_backoff_ms" => 500,
        "max_backoff_ms" => 5_000,
        "jitter" => true
      }
    },
    "agent" => %{
      "id" => nil,
      "region" => "local",
      "heartbeat_interval_ms" => 10_000,
      "capacity" => 16,
      "browser_instances" => 2,
      "page_concurrency" => 16,
      "lightpanda_path" => "lightpanda"
    },
    "security" => %{
      "allowed_schemes" => ["http", "https"],
      "redirect_limit" => 5,
      "blocked_cidrs" => [
        "127.0.0.0/8",
        "10.0.0.0/8",
        "172.16.0.0/12",
        "192.168.0.0/16",
        "169.254.0.0/16",
        "::1/128",
        "fc00::/7"
      ]
    }
  }

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def get do
    GenServer.call(__MODULE__, :get)
  end

  def reload! do
    GenServer.call(__MODULE__, :reload)
  end

  def settings_path do
    Application.fetch_env!(:scout, :settings_path)
  end

  @impl true
  def init(_state) do
    {:ok, load_settings!()}
  end

  @impl true
  def handle_call(:get, _from, state), do: {:reply, state, state}

  @impl true
  def handle_call(:reload, _from, _state) do
    state = load_settings!()
    {:reply, state, state}
  end

  def load_file!(path) do
    path
    |> YamlElixir.read_from_file!()
    |> normalize()
  end

  def default_settings, do: @default_settings

  defp load_settings! do
    settings_path()
    |> load_file!()
    |> Map.put("__meta__", %{"path" => settings_path()})
  end

  defp normalize(raw) when is_map(raw) do
    raw
    |> deep_stringify_keys()
    |> then(&deep_merge(@default_settings, &1))
    |> normalize_agent_id()
  end

  defp normalize(_), do: raise(ArgumentError, "settings.yaml must contain a top-level map")

  defp normalize_agent_id(settings) do
    id =
      settings["agent"]["id"] ||
        System.get_env("SCOUT_AGENT_ID") ||
        "#{settings["agent"]["region"]}-agent-#{System.get_env("HOSTNAME") || "local"}"

    put_in(settings, ["agent", "id"], id)
  end

  defp deep_stringify_keys(value) when is_map(value) do
    Map.new(value, fn {key, nested_value} ->
      {to_string(key), deep_stringify_keys(nested_value)}
    end)
  end

  defp deep_stringify_keys(value) when is_list(value), do: Enum.map(value, &deep_stringify_keys/1)
  defp deep_stringify_keys(value), do: value

  defp deep_merge(left, right) when is_map(left) and is_map(right) do
    Map.merge(left, right, fn _key, left_value, right_value ->
      deep_merge(left_value, right_value)
    end)
  end

  defp deep_merge(_left, right), do: right
end
