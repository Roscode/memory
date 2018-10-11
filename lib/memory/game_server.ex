defmodule Memory.GameServer do
  use GenServer

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
    GenServer.start_link(__MODULE__, [3], name: reg(name))
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
  def handle_call({:view, user}, _from, state) do
    {:reply, {:ok, Game.client_view(state)}, state}
  end

  @impl true
  def handle_call({:join, user}, _from, state) do
    {:reply, {:ok, Game.client_view(state)}, state}
  end

  @impl true
  def handle_call({:flip, coords, user}, state) do
    {:reply, {:ok, Game.client_view(state)}, state}
  end

  @impl true
  def handle_call(:restart, state) do
    {:reply, {:ok, Game.client_view(state)}, state}
  end
end

