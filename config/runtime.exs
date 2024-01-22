import Config

if System.get_env("PHX_SERVER") do
  config :bleep, BleepWeb.Endpoint, server: true
end

if config_env() == :prod do
  # The secret key base is used to sign/encrypt cookies and other secrets.
  # A default value is used in config/dev.exs and config/test.exs but you
  # want to use a different value for prod and you most likely don't want
  # to check this value into version control, so we use an environment
  # variable instead.
  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  host = System.get_env("PHX_HOST") || "example.com"
  port = String.to_integer(System.get_env("PORT") || "4000")
  https_port = String.to_integer(System.get_env("HTTPS_PORT") || "4001")

  if System.get_env("BLEEP_SECURE_SERVER") do
    config :bleep, BleepWeb.Endpoint,
      secret_key_base: secret_key_base,
      url: [host: host, port: https_port, scheme: "https"],
      https: [
        compress: true,
        otp_app: :bleep,
        port: https_port,
        protocol_options: [
          max_connections: 1000
        ],
        versions: [:"tlsv1.2"],
        ciphers: [
          ~c"ECDHE-RSA-AES256-GCM-SHA384",
          ~c"ECDHE-RSA-AES128-GCM-SHA256",
          ~c"ECDHE-RSA-AES128-GCM-SHA256",
          ~c"ECDHE-ECDSA-AES128-GCM-SHA256"
        ],
        honor_cipher_order: true,
        keyfile: System.get_env("BLEEP_SSL_KEY_PATH"),
        certfile: System.get_env("BLEEP_SSL_CERT_PATH")
      ]
  else
    config :bleep, BleepWeb.Endpoint,
      secret_key_base: secret_key_base,
      https: [
        otp_app: :bleep,
        port: https_port,
        cipher_suite: :strong,
        keyfile: System.get_env("BLEEP_SSL_KEY_PATH"),
        certfile: System.get_env("BLEEP_SSL_CERT_PATH")
      ],
      http: [
        # Enable IPv6 and bind on all interfaces.
        # Set it to  {0, 0, 0, 0, 0, 0, 0, 1} for local network only access.
        # See the documentation on https://hexdocs.pm/plug_cowboy/Plug.Cowboy.html
        # for details about using IPv6 vs IPv4 and loopback vs public addresses.
        ip: {0, 0, 0, 0, 0, 0, 0, 0},
        port: port
      ]
  end
end
