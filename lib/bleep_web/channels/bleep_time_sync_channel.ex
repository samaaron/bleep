defmodule BleepWeb.BleepTimeSyncChannel do
  use BleepWeb, :channel
  require Logger

  @impl true
  def join("bleep-time-sync:" <> user_id, _payload, socket) do
    kalman = Kalman.new(q: 0.005, r: 1, x: 0.05)

    {:ok,
     socket
     |> assign(:user_id, user_id)
     |> assign(:kalman, kalman)}
  end

  @impl true
  def handle_in("time-ping", %{"time_s" => time_s}, socket) do
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
    user_id = socket.assigns.user_id
    latency_est_ms = latency_est_s * 1000

    BleepWeb.MainLive.id_send(user_id, {:latency_update, latency_est_ms})

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
