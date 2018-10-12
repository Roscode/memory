defmodule MemoryWeb.GamesChannel do
  use MemoryWeb, :channel

  alias Memory.GameServer

  def join("games:" <> game_name, payload, socket) do
    if authorized?(payload) do
      socket = socket
               |> assign(:game, game_name)
      {:ok, game} = GameServer.view(game_name)
      {:ok, %{"lobby" => game_name, "game" => game}, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  def handle_in("join", _payload, socket) do
    {:ok, game} = GameServer.join(socket.assigns[:game], socket.assigns[:user])
    broadcast! socket, "update", %{"game" => game}
    {:noreply, socket}
  end

  def handle_in("flip", %{"x" => x, "y" => y}, socket) do
    {:ok, game} = GameServer.flip(socket.assigns[:game], {x, y}, socket.assigns[:user])
    broadcast! socket, "update", %{"game" => game}
    {:noreply, socket}
  end

  def handle_in("restart", _, socket) do
    {:ok, game} = GameServer.restart(socket.assigns[:game])
    broadcast! socket, "update", %{"game" => game}
    {:noreply, socket}
  end

  # Add authorization logic here as required.
  defp authorized?(_payload) do
    true
  end
end
