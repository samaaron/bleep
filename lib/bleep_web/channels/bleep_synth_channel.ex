defmodule BleepWeb.BleepSynthChannel do
  use BleepWeb, :channel
  require Logger

  @impl true
  def join("bleep-audio:" <> room, payload, socket) do
    socket = assign(socket, :room, room)

    if authorized?(payload) do
      {:ok, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  def authorized?(_payload) do
    true
  end
end
