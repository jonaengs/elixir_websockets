defmodule WS.Server.Register do
  use GenServer

  def start() do
    GenServer.start(__MODULE__, nil, name: __MODULE__)
  end

  def add(channel) do
    GenServer.cast(__MODULE__, {:add, {self(), channel}})
  end

  def get(channel) do
    GenServer.call(__MODULE__, {:get, channel})
  end

  @impl GenServer
  def init(_) do
    {:ok, %{}}
  end

  @impl GenServer
  def handle_cast({:add, {pid, channel}}, store) do
    {:noreply, Map.update(store, channel, [pid], &([pid | &1]))}
  end

  @impl GenServer
  def handle_call({:get, channel}, _, store) do
    {:reply, Map.get(store, channel, []), store}
  end

end
