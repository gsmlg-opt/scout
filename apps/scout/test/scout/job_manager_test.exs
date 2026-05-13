defmodule Scout.JobManagerTest do
  use ExUnit.Case, async: false

  alias Scout.Server.API

  setup do
    previous_adapter = Application.get_env(:scout, :lightpanda_adapter)
    previous_dispatch = Application.get_env(:scout, :dispatch_mode)

    Application.put_env(:scout, :lightpanda_adapter, Scout.Test.FakeLightpanda)
    Application.put_env(:scout, :dispatch_mode, :local)

    on_exit(fn ->
      restore_env(:lightpanda_adapter, previous_adapter)
      restore_env(:dispatch_mode, previous_dispatch)
    end)

    :ok
  end

  test "runs a local fetch job and stores the markdown result" do
    Phoenix.PubSub.subscribe(Scout.PubSub, "scout:jobs")

    assert {:ok, %{job_id: job_id, status: "queued"}} =
             API.submit_fetch(%{"url" => "https://example.com/docs"})

    completed = assert_job_status(job_id, "completed")

    assert completed.result.markdown =~ "# Example Documentation"
    assert completed.result.word_count > 0

    assert {:ok, stored} = API.get_fetch(job_id)
    assert stored.status == "completed"
  end

  test "runs a synchronous fetch without RabbitMQ" do
    assert {:ok, result} = API.fetch_sync(%{"url" => "https://example.com/sync"})

    assert result.ok
    assert result.markdown =~ "https://example.com/sync"
  end

  defp assert_job_status(job_id, expected) do
    receive do
      {:job_updated, %{job_id: ^job_id, status: ^expected} = job} ->
        job

      {:job_updated, %{job_id: ^job_id}} ->
        assert_job_status(job_id, expected)
    after
      1_000 -> flunk("expected job #{job_id} to reach #{expected}")
    end
  end

  defp restore_env(key, nil), do: Application.delete_env(:scout, key)
  defp restore_env(key, value), do: Application.put_env(:scout, key, value)
end
