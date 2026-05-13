defmodule ScoutWeb.DashboardLiveTest do
  use ScoutWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  test "renders the Scout dashboard", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/")

    assert has_element?(view, "#fetch-form")
    assert has_element?(view, "#jobs")
    assert has_element?(view, "#agents")
  end
end
