defmodule Scout.SettingsTest do
  use ExUnit.Case, async: true

  test "loads runtime settings yaml with defaults" do
    settings = Scout.Settings.load_file!("test/support/fixtures/settings.yaml")

    assert settings["general"]["instance_name"] == "Test Scout"
    assert settings["general"]["default_region"] == "test"
    assert settings["fetch"]["default_timeout_ms"] == 1000
    assert settings["fetch"]["max_timeout_ms"] == 2000
    assert settings["fetch"]["retry"]["max_attempts"] == 2
    assert settings["agent"]["id"] == "test-agent-1"
    assert settings["rabbitmq"]["queues"]["jobs"] == "scout.fetch.jobs"
  end
end
