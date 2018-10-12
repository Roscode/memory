defmodule Memory.GameServer do
  use GenServer

  alias Memory.Game

  defp reg(id) do
    {:via, Registry, {Memory.GameRegistry, id}}
  end

  # Client methods

  def start(id) do
    spec = %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [id]},
      restart: :permanent,
      type: :worker,
    }
    DynamicSupervisor.start_child(Memory.GameSupervisor, spec)
  end

  def start_link(name) do
    GenServer.start_link(__MODULE__, Game.new(), name: reg(name))
  end

  defp get_game(game_name) do
    active_game? = Registry.lookup(Memory.GameRegistry, game_name)
    if length(active_game?) > 0 do
      [{pid, value}] = active_game?
      pid
    else
      {:ok, pid} = start(game_name)
      pid
    end
  end

  def view(game_name) do
    GenServer.call(get_game(game_name), :view)
  end

  def join(game_name, user) do
    GenServer.call(get_game(game_name), {:join, user})
  end

  def flip(game_name, coords, user) do
    GenServer.call(get_game(game_name), {:flip, coords, user})
  end

  def restart(game_name) do
    GenServer.call(get_game(game_name), :restart)
  end

  # Server callbacks

  @impl true
  def init(state) do
    {:ok, state}
  end

  @impl true
  def handle_call(:view, _from, state) do
    {:reply, {:ok, Game.client_view(state)}, state}
  end

  @impl true
  def handle_call({:join, user}, _from, state) do
    game = Game.add_player(state, user)
    {:reply, {:ok, Game.client_view(game)}, game}
  end

  @impl true
  def handle_call({:flip, coords, user}, _from, state) do
    IO.inspect(coords)
    IO.inspect(user)
    {final_game, temp_game} = Game.flip(state, coords, user)
    {:reply, {:ok, Game.client_view(if temp_game do temp_game else final_game end)}, final_game}
  end

  @impl true
  def handle_call(:restart, _from, state) do
    game = Game.new()
    {:reply, {:ok, Game.client_view(game)}, game}
  end
end

