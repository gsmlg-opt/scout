defmodule SearchAggregatorWeb.SearchLive do
  use SearchAggregatorWeb, :live_view

  alias SearchAggregator.Search
  alias SearchAggregator.Search.QueryParams
  alias SearchAggregator.Settings

  @impl true
  def mount(_params, _session, socket) do
    settings = Settings.get()

    {:ok,
     assign(socket,
       page_title: "Search",
       query: "",
       form: to_form(%{"q" => ""}),
       category: settings["ui"]["default_category"],
       language: settings["general"]["default_locale"],
       selected_engines: MapSet.new(),
       settings: settings,
       results: [],
       engine_reports: [],
       search_ref: nil,
       pending_engines: 0,
       completed_engines: 0,
       result_limit: settings["search"]["result_limit"]
     )}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    parsed = QueryParams.parse(params, socket.assigns.settings)

    {:noreply, apply_search(socket, parsed.query, parsed.opts, from_params?: true)}
  end

  @impl true
  def handle_event("search", %{"q" => raw_query}, socket) do
    opts = %{
      "category" => socket.assigns.category,
      "limit" => socket.assigns.result_limit,
      "engines" => socket.assigns.selected_engines,
      "language" => socket.assigns.language
    }

    {:noreply,
     push_patch(socket,
       to: ~p"/?#{QueryParams.to_query_params(raw_query, opts, socket.assigns.settings)}"
     )}
  end

  @impl true
  def handle_event("set_category", %{"category" => category}, socket) do
    opts = current_opts(socket) |> Map.put("category", category)

    {:noreply,
     push_patch(socket,
       to:
         ~p"/?#{QueryParams.to_query_params(socket.assigns.query, opts, socket.assigns.settings)}"
     )}
  end

  @impl true
  def handle_event("set_limit", %{"limit" => limit}, socket) do
    opts = current_opts(socket) |> Map.put("limit", limit)

    {:noreply,
     push_patch(socket,
       to:
         ~p"/?#{QueryParams.to_query_params(socket.assigns.query, opts, socket.assigns.settings)}"
     )}
  end

  @impl true
  def handle_event("toggle_engine", %{"engine" => engine}, socket) do
    selected =
      if MapSet.member?(socket.assigns.selected_engines, engine) do
        MapSet.delete(socket.assigns.selected_engines, engine)
      else
        MapSet.put(socket.assigns.selected_engines, engine)
      end

    opts = current_opts(socket) |> Map.put("engines", selected)

    {:noreply,
     push_patch(socket,
       to:
         ~p"/?#{QueryParams.to_query_params(socket.assigns.query, opts, socket.assigns.settings)}"
     )}
  end

  defp apply_search(socket, query, opts, from_params?: _from_params?) do
    if query == "" do
      assign(socket,
        query: "",
        form: to_form(%{"q" => ""}),
        category: opts["category"],
        language: opts["language"],
        selected_engines: opts["engine_names"],
        results: [],
        engine_reports: [],
        search_ref: nil,
        pending_engines: 0,
        completed_engines: 0,
        result_limit: opts["limit"]
      )
    else
      run = Search.start(query, self(), opts)

      assign(socket,
        query: query,
        form: to_form(%{"q" => query}),
        category: run.opts["category"],
        language: run.opts["language"],
        selected_engines: run.opts["engine_names"],
        results: [],
        engine_reports: [],
        search_ref: run.ref,
        pending_engines: run.total,
        completed_engines: 0,
        settings: run.settings,
        result_limit: run.opts["limit"]
      )
    end
  end

  @impl true
  def handle_info({:search_engine_result, ref, payload}, %{assigns: %{search_ref: ref}} = socket) do
    results =
      Search.merge_results(
        socket.assigns.results,
        payload.results,
        socket.assigns.result_limit
      )

    engine_reports =
      [payload | socket.assigns.engine_reports]
      |> Enum.sort_by(& &1.engine)

    {:noreply,
     assign(socket,
       results: results,
       engine_reports: engine_reports,
       completed_engines: socket.assigns.completed_engines + 1,
       pending_engines: max(socket.assigns.pending_engines - 1, 0)
     )}
  end

  def handle_info({:search_engine_result, _ref, _payload}, socket), do: {:noreply, socket}

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <main class="search-page">
        <section class="hero">
          <p class="eyebrow">{@settings["general"]["instance_name"]}</p>
          <h1 class="text-on-surface">SearXNG-style metasearch, implemented in Elixir.</h1>
          <p class="text-on-surface-variant">
            Parallel engine execution, YAML-driven runtime configuration, graceful degradation,
            and privacy-first defaults. This first slice already queries multiple providers and
            merges results live as engines finish.
          </p>

          <.form for={@form} as={:search} phx-submit="search" class="search-form">
            <div class="category-tabs">
              <.dm_btn
                :for={{name, _targets} <- @settings["ui"]["categories_as_tabs"]}
                variant={if @category == name, do: "primary", else: "ghost"}
                size="sm"
                phx-click="set_category"
                phx-value-category={name}
              >
                {humanize_category(name)}
              </.dm_btn>
            </div>
            <div class="search-bar">
              <.dm_input
                field={@form[:q]}
                placeholder="Search without being profiled"
                autocomplete="off"
              />
              <.dm_btn variant="primary" type="submit">Search</.dm_btn>
            </div>
            <div class="control-row">
              <div class="control-block">
                <span class="eyebrow">Limit</span>
                <div class="flex flex-wrap gap-2">
                  <.dm_btn
                    :for={limit <- [5, 8, 10, 20]}
                    variant={if @result_limit == limit, do: "primary", else: "ghost"}
                    size="sm"
                    phx-click="set_limit"
                    phx-value-limit={limit}
                  >
                    {limit}
                  </.dm_btn>
                </div>
              </div>
              <div class="control-block">
                <span class="eyebrow">Engines</span>
                <div class="engine-chips">
                  <.dm_btn
                    :for={engine <- available_engines(@settings, @category)}
                    variant={
                      if MapSet.size(@selected_engines) == 0 or
                           MapSet.member?(@selected_engines, engine["name"]),
                         do: "primary",
                         else: "ghost"
                    }
                    size="sm"
                    phx-click="toggle_engine"
                    phx-value-engine={engine["name"]}
                  >
                    {engine["name"]}
                  </.dm_btn>
                </div>
              </div>
            </div>
          </.form>
        </section>

        <section class="meta-strip">
          <.dm_card>
            <p class="eyebrow">Enabled Engines</p>
            <p class="metric">{active_engine_count(@settings, @category, @selected_engines)}</p>
          </.dm_card>
          <.dm_card>
            <p class="eyebrow">Category</p>
            <p class="metric">{humanize_category(@category)}</p>
          </.dm_card>
          <.dm_card>
            <p class="eyebrow">Progress</p>
            <p class="metric">{@completed_engines}/{@completed_engines + @pending_engines}</p>
          </.dm_card>
        </section>

        <section class="results-shell">
          <div class="results-list">
            <%= if @results == [] do %>
              <.dm_card class="empty-state">
                Results will appear here progressively as each engine responds.
              </.dm_card>
            <% else %>
              <.dm_card :for={result <- @results}>
                <:title>
                  <a href={result.url} target="_blank" rel="noreferrer">{result.title}</a>
                </:title>
                <p class="eyebrow">{result.source}</p>
                <p class="text-on-surface-variant">{result.content}</p>
                <div class="flex flex-wrap gap-2.5 items-center mt-3">
                  <.dm_badge variant="primary">{result.engine}</.dm_badge>
                  <span class="text-on-surface-variant text-sm truncate">{result.url}</span>
                </div>
              </.dm_card>
            <% end %>
          </div>

          <aside class="status-list">
            <.dm_card>
              <p class="eyebrow">Config</p>
              <h3 class="text-lg font-semibold">{Path.basename(@settings["__meta__"]["path"])}</h3>
              <p class="text-on-surface-variant">
                Runtime settings are loaded from YAML, not from compile-time Elixir config.
              </p>
              <div class="flex flex-wrap gap-2.5 items-center mt-3">
                <span class="text-on-surface-variant text-sm">API: /search?q=phoenix</span>
                <span class="text-on-surface-variant text-sm">Limit: {@result_limit}</span>
              </div>
            </.dm_card>

            <.dm_card :for={report <- @engine_reports}>
              <p class="eyebrow">{report.engine}</p>
              <h3 class={[
                "text-lg font-semibold",
                if(report.ok?, do: "text-success", else: "text-error")
              ]}>
                {if report.ok?, do: "Completed", else: "Failed"}
              </h3>
              <p class="text-on-surface-variant">
                {if report.ok?, do: "#{length(report.results)} results merged", else: report.error}
              </p>
              <div class="flex flex-wrap gap-2.5 items-center mt-3">
                <.dm_badge variant="ghost">{report.mode}</.dm_badge>
                <span class="text-on-surface-variant text-sm">{report.duration_ms} ms</span>
              </div>
            </.dm_card>
          </aside>
        </section>
      </main>
    </Layouts.app>
    """
  end

  defp humanize_category(category) do
    category
    |> to_string()
    |> String.replace("_", " ")
    |> Phoenix.Naming.humanize()
  end

  defp current_opts(socket) do
    %{
      "category" => socket.assigns.category,
      "limit" => socket.assigns.result_limit,
      "engines" => socket.assigns.selected_engines,
      "language" => socket.assigns.language
    }
  end

  defp available_engines(settings, category) do
    Search.enabled_engines(settings, %{"category" => category, "engine_names" => MapSet.new()})
  end

  defp active_engine_count(settings, category, selected_engines) do
    Search.enabled_engines(settings, %{"category" => category, "engine_names" => selected_engines})
    |> length()
  end
end
