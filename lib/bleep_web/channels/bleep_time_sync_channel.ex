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
  def handle_in("time-ping", %{"time_s" => time_s, "latency_s" => latency_s}, socket) do
    user_id = socket.assigns.user_id
    Logger.info("latency_s: #{:erlang.float(latency_s)}")
    BleepWeb.MainLive.id_send(user_id, {:latency_update, :erlang.float(latency_s) * 1000})

    msg = %{
      client_timestamp: time_s,
      server_timestamp: :erlang.system_time(:milli_seconds) / 1000.0
    }

    {:reply, {:ok, msg}, socket}
  end

  @impl true
  def handle_in("time-sync", %{"time_s" => time_s, "latency_s" => latency_s}, socket) do
    socket = assign(socket, :kalman, Kalman.step(0, latency_s, socket.assigns.kalman))
    latency_est_s = Kalman.estimate(socket.assigns.kalman)

    latency_est_ms = latency_est_s * 1000

    msg = %{
      client_timestamp: time_s,
      latency_est: latency_est_s,
      server_timestamp: :erlang.system_time(:milli_seconds) / 1000.0
    }

    {:reply, {:ok, msg}, socket}
  end

  # Add authorization logic here as required.
  # defp authorized?(_payload) do
  #   true
  # end
end
