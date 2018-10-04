defmodule MemoryWeb.GamesChannel do
  use MemoryWeb, :channel

  alias Memory.Game

  def join("games:" <> name, payload, socket) do
    if authorized?(payload) do
      game = Game.new()
      socket = socket
               |> assign(:game, game)
               |> assign(:name, name)
      {:ok, %{"join" => name, "game" => Game.client_view(game)}, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  # Channels can be used in a request/response fashion
  # by sending replies to requests from the client
  def handle_in("guess", %{"x" => x, "y" => y}, socket) do
    game = Game.flip(socket.assigns[:game], {x, y})
    socket = assign(socket, :game, game)
    {:reply, {:ok, %{"game" => Game.client_view(game)}}, socket}
  end

  def handle_in("restart", _, socket) do
    game = Game.new()
    socket = assign(socket, :game, game)
    {:reply, {:ok, %{"game" => Game.client_view(game)}}, socket}
  end

  # It is also common to receive messages from the client and
  # broadcast to everyone in the current topic (games:lobby).
  # def handle_in("shout", payload, socket) do
  #   broadcast socket, "shout", payload
  #   {:noreply, socket}
  # end

  # Add authorization logic here as required.
  defp authorized?(_payload) do
    true
  end
end
