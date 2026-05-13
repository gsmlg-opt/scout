defmodule Scout.AgentTest do
  use ExUnit.Case, async: false

  test "fetches a job through the Lightpanda pool" do
    assert {:ok, job} = Scout.Fetch.Job.new(%{"url" => "https://example.com/docs"})

    result = Scout.Agent.fetch(job)

    assert result.ok
    assert result.markdown =~ "# Example Documentation"
    assert result.agent_id == "test-agent-1"
  end

  test "reports agent status from settings and pool state" do
    assert %{
             agent_id: "test-agent-1",
             status: "healthy",
             running_jobs: 0,
             capacity: 1
           } = Scout.Agent.status()
  end
end
