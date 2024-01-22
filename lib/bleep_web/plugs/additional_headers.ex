defmodule BleepWeb.Plugs.AdditionalHeaders do
  @moduledoc """
  This plug adds additional security headers to the response.
  """
  import Plug.Conn

  def init(default), do: default

  def call(conn, _opts) do
    conn
    |> put_resp_header("x-xss-protection", "0")
  end
end
