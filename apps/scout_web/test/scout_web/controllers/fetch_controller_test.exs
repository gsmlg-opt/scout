defmodule ScoutWeb.FetchControllerTest do
  use ScoutWeb.ConnCase, async: false

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

  test "submits a fetch job", %{conn: conn} do
    conn = post(conn, ~p"/api/fetch", %{url: "https://example.com/docs"})

    body = json_response(conn, 202)

    assert %{"job_id" => job_id, "status" => "queued"} = body
    assert {:ok, _job} = Scout.get_fetch(job_id)
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

  defp restore_env(key, nil), do: Application.delete_env(:scout, key)
  defp restore_env(key, value), do: Application.put_env(:scout, key, value)
end
