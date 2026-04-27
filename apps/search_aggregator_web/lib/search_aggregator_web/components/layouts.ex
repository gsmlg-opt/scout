defmodule SearchAggregatorWeb.Layouts do
  @moduledoc """
  This module holds layouts and related functionality
  used by your application.
  """
  use SearchAggregatorWeb, :html

  # Embed all files in layouts/* within this module.
  # The default root.html.heex file contains the HTML
  # skeleton of your application, namely HTML headers
  # and other static content.
  embed_templates "layouts/*"

  @doc """
  Renders your app layout.

  This function is typically invoked from every template,
  and it often contains your application menu, sidebar,
  or similar.

  ## Examples

      <Layouts.app flash={@flash}>
        <h1>Content</h1>
      </Layouts.app>

  """
  attr :flash, :map, required: true, doc: "the map of flash messages"

  attr :current_scope, :map,
    default: nil,
    doc: "the current [scope](https://hexdocs.pm/phoenix/scopes.html)"

  slot :inner_block, required: true

  def app(assigns) do
    ~H"""
    <.dm_appbar title="SearchAggregator" sticky>
      <:logo>
        <a href="/" class="flex items-center gap-2">
          <img src={~p"/images/logo.svg"} width="36" alt="logo" />
          <span class="text-sm font-semibold">v{Application.spec(:phoenix, :vsn)}</span>
        </a>
      </:logo>
      <:menu>
        <.link navigate={~p"/"} class="text-primary-content/80 hover:text-primary-content">
          Home
        </.link>
      </:menu>
      <:user_profile>
        <.dm_theme_switcher />
      </:user_profile>
    </.dm_appbar>

    <main class="bg-surface px-4 py-20 sm:px-6 lg:px-8">
      <div class="mx-auto max-w-2xl space-y-4">
        {render_slot(@inner_block)}
      </div>
    </main>

    <.dm_flash_group flash={@flash} />
    """
  end
end
