# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

# Configures the endpoint
config :bleep, BleepWeb.Endpoint,
  url: [host: "localhost"],
  render_errors: [
    formats: [html: BleepWeb.ErrorHTML, json: BleepWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: Bleep.PubSub,
  live_view: [signing_salt: "KJ/zGXna"]

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :bleep, Bleep.Mailer, adapter: Swoosh.Adapters.Local

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.21.4",
  default: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/* --loader:.ttf=file),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ],
  web_workers: [
    args: ~w(
      js/lib/bleep_prescheduler.worker.js
      --bundle
      --target=es2017
      --outdir=../priv/static/assets/),
    cd: Path.expand("../assets", __DIR__)
  ],
  monaco_editor: [
    args: ~w(
      vendor/monaco-editor/esm/vs/editor/editor.worker.js
      --bundle
      --target=es2017
      --outdir=../priv/static/assets/monaco-editor
      ),
    cd: Path.expand("../assets", __DIR__)
  ],
  synth_designer_live: [
    args: ~w(
      js/synth_designer_live.js
      --bundle
      --target=es2017
      --outdir=../priv/static/assets/synth_designer/),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ],
  synth_designer: [
    args: ~w(
      vendor/bleep-synth/app.js
      vendor/bleep-synth/sheet.css
      --bundle
      --target=es2017
      --outdir=../priv/static/assets/synth_designer/),
    cd: Path.expand("../assets", __DIR__)
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "3.4.3",
  default: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/style.css
      --output=../priv/static/assets/style.css
      ),
    cd: Path.expand("../assets", __DIR__)
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
