defmodule WordexBlast.Rooms.Monitor do
  use GenServer

  alias WordexBlast.Rooms
  alias WordexBlastWeb.Presence

  def monitor(room_pid, room_id) do
    pid = GenServer.whereis({:global, __MODULE__})
    GenServer.call(pid, {:monitor, {room_pid, room_id}})
  end

  def init(_) do
    {:ok, %{rooms: %{}}}
  end

  def start_link(init_arg) do
    GenServer.start_link(__MODULE__, init_arg, name: {:global, __MODULE__})
  end

  def handle_call({:monitor, {room_pid, room_id}}, _, state) do
    Process.monitor(room_pid)
    rooms = Map.put(state.rooms, room_pid, room_id)

    {:reply, :ok, %{state | rooms: rooms}}
  end

  def handle_info({:DOWN, _ref, :process, room_pid, _reason}, state) do
    {room_id, updated_rooms} = Map.pop(state.rooms, room_pid)
    presences = Presence.list("play:#{room_id}")

    if presences == %{} do
      room_id
      |> Rooms.get_room()
      |> Rooms.delete_room()
    end

    {:noreply, %{state | rooms: updated_rooms}}
  end
end
