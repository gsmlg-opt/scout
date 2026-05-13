defmodule Scout.Server.JobManagerTest do
  use ExUnit.Case, async: false

  alias Scout.Fetch.Result
  alias Scout.Server.ResultHandler

  setup do
    previous_publisher = Application.get_env(:scout_server, :job_publisher)

    Application.put_env(:scout_server, :job_publisher, __MODULE__.Publisher)

    on_exit(fn ->
      restore_env(:job_publisher, previous_publisher)
    end)

    :ok
  end

  test "submits a fetch job and stores the markdown result from an agent" do
    Phoenix.PubSub.subscribe(Scout.PubSub, "scout:jobs")

    assert {:ok, %{job_id: job_id, status: "queued"}} =
             Scout.Server.submit_fetch(%{"url" => "https://example.com/docs"})

    completed = assert_job_status(job_id, "completed")

    assert completed.result.markdown =~ "# Example Documentation"
    assert completed.result.word_count > 0

    assert {:ok, stored} = Scout.Server.get_fetch(job_id)
    assert stored.status == "completed"
  end

  test "runs a synchronous fetch by dispatching and waiting for a result" do
    assert {:ok, result} = Scout.Server.fetch_sync(%{"url" => "https://example.com/sync"})

    assert result.ok
    assert result.markdown =~ "https://example.com/sync"
  end

  test "lists agent heartbeats" do
    Scout.Server.AgentRegistry.update_heartbeat(%{
      "agent_id" => "agent-1",
      "region" => "test",
      "status" => "healthy",
      "running_jobs" => 0,
      "capacity" => 1,
      "version" => "0.1.0",
      "timestamp" => DateTime.utc_now() |> DateTime.to_iso8601()
    })

    assert [%{agent_id: "agent-1", status: "healthy"}] = Scout.Server.list_agents()
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

  defp restore_env(key, nil), do: Application.delete_env(:scout_server, key)
  defp restore_env(key, value), do: Application.put_env(:scout_server, key, value)

  defmodule Publisher do
    def publish_job(job) do
      Task.start(fn ->
        markdown = "# Example Documentation\n\nFetched #{job.url}"

        ResultHandler.handle_result(
          Result.success(job, %{
            markdown: markdown,
            title: "Example Documentation",
            final_url: job.url,
            agent_id: "test-agent-1",
            duration_ms: 1,
            word_count: 4
          })
        )
      end)

      :ok
    end
  end
end
