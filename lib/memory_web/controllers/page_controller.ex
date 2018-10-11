defmodule MemoryWeb.PageController do
  use MemoryWeb, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end

  # Significantly influenced by nat tuck's lecture notes
  def join(conn, %{"join" => %{"player" => p, "game" => g}}) do
    conn
    |> put_session(:user, p)
    |> redirect(to: "/game/#{g}")
  end

  # Also influenced by the notes
  def game(conn, params) do
    user = get_session(conn, :user)
    if user do
      render conn, "game.html", game: params["game"], user: user
    else
      conn
      |> put_flash(:error, "Must pick a username")
      |> redirect(to: "/")
    end
  end
end
