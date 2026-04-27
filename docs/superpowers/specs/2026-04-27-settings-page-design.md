# Settings Page Design

## Overview

Add web UI settings management at `/settings` and `/settings/engines` so users can configure the application without editing `settings.yaml` by hand.

## Routes

```
live "/settings",         SettingsLive, :index
live "/settings/engines", EngineSettingsLive, :index
```

## Architecture

### SettingsLive

- Reads `Settings.get()` in `mount/3` to seed the form
- Builds a flat `to_form/1` changeset map from nested settings
- On save: serializes form data back to nested map, writes YAML via `Settings.save!/1`, then `Settings.reload!/0`
- Renders `dm_form_section` blocks per category using `dm_input`, `dm_select`, `dm_switch`

### EngineSettingsLive

- Reads `Settings.get()` in `mount/3`, extracts the `engines` list
- Lists engines as `dm_card` components showing name, shortcut, mode, categories
- Each engine row has Edit (`dm_btn` ghost) and Remove (`dm_btn` error with confirm)
- "Add Engine" opens a `dm_modal` with engine form fields
- On save: reconstructs settings map, persists via `Settings.save!/1`

### Persistence

New function `Settings.save!/1` on the GenServer:

1. Strips `__meta__` from the map
2. Serializes to YAML with `YamlElixir.write_to_file!`
3. Writes atomically (temp file → rename)
4. Calls `reload!` to refresh GenServer state

## Fields

### General section
- instance_name (text)
- default_locale (text)
- request_timeout_ms (number)
- contact_url (text)

### Search section
- result_limit (number)
- max_limit (number)
- autocomplete (text)
- safe_search (select: 0=Off, 1=Moderate, 2=Strict)

### UI section
- theme (text, free-form: "dawn", "sunshine", "moonlight", etc.)
- default_category (text, free-form: "general", "tech", etc.)
- categories_as_tabs (textarea, YAML-formatted map)

### Browser Simulator section
- enabled (switch)
- pool_size (number)
- export_path (text)

### Engines page
- Add/edit modal fields: name, engine, shortcut, mode (select: http/browser), base_url, timeout_ms, categories (comma-separated text), disabled (switch)
- List view: dm_card per engine with name, shortcut, mode badge, categories chips

## DuskMoon Components Used

| Component | Usage |
|-----------|-------|
| `dm_form` | Main form container with `:actions` slot |
| `dm_form_section` | Category grouping with title |
| `dm_form_grid` | Two-column field layout within sections |
| `dm_input` | Text and number fields |
| `dm_select` | Safe search, engine mode dropdowns |
| `dm_switch` | Browser simulator enabled, engine disabled |
| `dm_btn` | Save (primary), Cancel (ghost), Edit (ghost), Remove (error with confirm) |
| `dm_card` | Engine list items |
| `dm_modal` | Add/edit engine form |
| `dm_badge` | Engine mode/category display |
| `dm_flash_group` | Success/error feedback (already in Layouts) |

## Navigation

Add "Settings" `<:menu>` item to `dm_appbar` in `Layouts.app/1`. The existing menu only has "Home".

## Files Changed

- `apps/search_aggregator/lib/search_aggregator/settings.ex` — add `save!/1`
- `apps/search_aggregator_web/lib/search_aggregator_web/router.ex` — add two live routes
- `apps/search_aggregator_web/lib/search_aggregator_web/live/settings_live.ex` — new
- `apps/search_aggregator_web/lib/search_aggregator_web/live/engine_settings_live.ex` — new
- `apps/search_aggregator_web/components/layouts.ex` — add Settings nav link

## Edge Cases

- YAML write failure: show flash error, do not reload
- Invalid form values: validate on change, disable save button
- Empty engines list: show empty state in card
