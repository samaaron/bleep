defmodule BleepWeb.Router do
  use BleepWeb, :router

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_live_flash)
    plug(:put_root_layout, html: {BleepWeb.Layouts, :root})
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
    plug(BleepWeb.Plugs.AdditionalHeaders)
    plug :put_content_security_policy
  end

  defp put_content_security_policy(conn, _opts) do
    Plug.Conn.put_resp_header(
      conn,
      "content-security-policy",
      "default-src 'self'; style-src 'self' 'unsafe-inline'"
    )
  end

  pipeline :api do
    plug(:accepts, ["json"])
  end

  scope "/", BleepWeb do
    pipe_through(:browser)

    live("/", MainLive)
    live("/artist/:artist", MainLive, :artist)
    live("/user/", MainLive, :user)
    live("/designer", SynthDesignerLive)
  end

  # Other scopes may use custom stacks.
  # scope "/api", BleepWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:bleep, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through(:browser)

      live_dashboard("/dashboard", metrics: BleepWeb.Telemetry)
      forward("/mailbox", Plug.Swoosh.MailboxPreview)
    end
  end
end
