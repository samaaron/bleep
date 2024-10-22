defmodule BleepWeb.BleepTimeSyncChannel do
  use BleepWeb, :channel
  require Logger

  @impl true
  def join("bleep-time-sync:" <> user_id, _payload, socket) do
    {
      :ok,
      socket
      |> assign(:user_id, user_id)
    }
  end

  @impl true
  def handle_in("time-ping", %{"time_s" => time_s, "ping_s" => ping_s}, socket) do
    user_id = socket.assigns.user_id
    BleepWeb.MainLive.id_send(user_id, {:ping_update, :erlang.float(ping_s) * 1000})

    msg = %{
      client_timestamp: time_s,
      server_timestamp: :erlang.system_time(:milli_seconds) / 1000.0
    }

    {:reply, {:ok, msg}, socket}
  end
end
