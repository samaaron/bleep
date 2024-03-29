defmodule BleepWeb.BleepSocket do
  use Phoenix.Socket
  require Logger

  channel "bleep-audio:*", BleepWeb.BleepSynthChannel
  channel "bleep-time-sync:*", BleepWeb.BleepTimeSyncChannel

  @impl true
  def connect(_params, socket, _connect_info) do
    {:ok, socket}
  end

  # Socket ids are topics that allow you to identify all sockets for a given user:
  #
  #     def id(socket), do: "user_socket:#{socket.assigns.user_id}"
  #
  # Would allow you to broadcast a "disconnect" event and terminate
  # all active sockets and channels for a given user:
  #
  #     Elixir.BleepWeb.Endpoint.broadcast("user_socket:#{user.id}", "disconnect", %{})
  #
  # Returning `nil` makes this socket anonymous.
  @impl true
  def id(_socket), do: nil
end
