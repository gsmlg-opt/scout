defmodule ScoutWeb.FetchControllerTest do
  use ScoutWeb.ConnCase, async: false

  setup do
    previous_publisher = Application.get_env(:scout_server, :job_publisher)

    Application.put_env(:scout_server, :job_publisher, __MODULE__.Publisher)

    on_exit(fn ->
      restore_env(:scout_server, :job_publisher, previous_publisher)
    end)

    :ok
  end

  test "submits a fetch job", %{conn: conn} do
    conn = post(conn, ~p"/api/fetch", %{url: "https://example.com/docs"})

    body = json_response(conn, 202)

    assert %{"job_id" => job_id, "status" => "queued"} = body
    assert {:ok, _job} = Scout.Server.get_fetch(job_id)
  end

  test "rejects private network targets", %{conn: conn} do
    conn = post(conn, ~p"/api/fetch", %{url: "http://127.0.0.1:4000"})

    assert %{"error" => %{"type" => "blocked_target"}} = json_response(conn, 422)
  end

  test "runs a synchronous fetch", %{conn: conn} do
    conn = post(conn, ~p"/api/fetch/sync", %{url: "https://example.com/docs"})

    body = json_response(conn, 200)

    assert body["ok"]
    assert body["markdown"] =~ "# Example Documentation"
  end

  defp restore_env(app, key, nil), do: Application.delete_env(app, key)
  defp restore_env(app, key, value), do: Application.put_env(app, key, value)

  defmodule Publisher do
    alias Scout.Fetch.Result
    alias Scout.Server.ResultHandler

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
