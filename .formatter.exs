[
  import_deps: [:phoenix],
  plugins: [Phoenix.LiveView.HTMLFormatter],
  inputs: ["*.{heex,ex,exs}", "config/**/*.{heex,ex,exs}"],
  subdirectories: ["apps/*"]
]
