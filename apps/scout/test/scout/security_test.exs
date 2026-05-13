defmodule Scout.SecurityTest do
  use ExUnit.Case, async: true

  alias Scout.Fetch.Job

  test "accepts public HTTP and HTTPS URLs" do
    assert {:ok, %Job{url: "https://example.com/docs"}} =
             Job.new(%{"url" => "https://example.com/docs"}, settings())

    assert {:ok, %Job{url: "http://example.com/docs"}} =
             Job.new(%{"url" => "http://example.com/docs"}, settings())
  end

  test "rejects unsupported protocols and local targets" do
    assert {:error, %{type: "unsupported_protocol"}} =
             Job.new(%{"url" => "file:///etc/passwd"}, settings())

    assert {:error, %{type: "blocked_target"}} =
             Job.new(%{"url" => "http://localhost:4000"}, settings())

    assert {:error, %{type: "blocked_target"}} =
             Job.new(%{"url" => "http://127.0.0.1:4000"}, settings())

    assert {:error, %{type: "blocked_target"}} =
             Job.new(%{"url" => "http://10.0.0.1"}, settings())
  end

  defp settings do
    Scout.Settings.default_settings()
  end
end
