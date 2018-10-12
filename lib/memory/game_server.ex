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
      [{pid, _}] = active_game?
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
    GenServer.call(get_game(game_name), {:flip, coords, user, game_name})
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
  def handle_info({:flip_back, game, name}, _state) do
    MemoryWeb.Endpoint.broadcast! "games:" <> name, "update", %{"game" => Game.client_view(game)}
    {:noreply, game}
  end

  @impl true
  def handle_call({:flip, coords, user, game_name}, _from, state) do
    {final_game, temp_game} = Game.flip(state, coords, user)
    if temp_game do
      Process.send_after(self(), {:flip_back, final_game, game_name}, 1500)
      {:reply, {:ok, Game.client_view(temp_game)}, Map.put(temp_game, :frozen, true)}
    else
      {:reply, {:ok, Game.client_view(final_game)}, final_game}
    end
  end

  @impl true
  def handle_call(:restart, _from, _state) do
    game = Game.new()
    {:reply, {:ok, Game.client_view(game)}, game}
  end
end

