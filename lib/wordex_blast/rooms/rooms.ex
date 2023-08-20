defmodule WordexBlast.Rooms.Rooms do
  use GenServer

  alias WordexBlast.Rooms.Room
  alias WordexBlast.Rooms.PubSub

  def call(args) do
    GenServer.call(__MODULE__, args)
  end

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init(_), do: {:ok, %{}}

  # Handlers

  def handle_call(:list, _, rooms) do
    {:reply, list_rooms(rooms), rooms}
  end

  def handle_call({:create, room_id}, _, rooms) do
    {room, rooms} = create_room(room_id, rooms)
    {:reply, room, rooms}
  end

  def handle_info({:room_updated, room}, rooms) do
    rooms = Map.put(rooms, room.id, room)
    {:noreply, rooms}
  end

  def handle_info({:room_deleted, room}, rooms) do
    rooms = Map.drop(rooms, [room.id])
    PubSub.broadcast(room, :room_deleted)
    {:noreply, rooms}
  end

  # Rooms management

  defp list_rooms(rooms) do
    Enum.map(rooms, fn {k, v} -> Map.put(v, :id, k) end)
  end

  defp create_room(room_id, rooms) do
    rooms
    |> Map.get(room_id)
    |> create_room(room_id, rooms)
  end

  defp create_room(nil, room_id, rooms) do
    room = %{id: room_id, status: "waiting", tick: 5, players: %{}, selected_player: {"", %{}}}
    Room.start_link(room)

    PubSub.broadcast(room, :room_created)
    PubSub.subscribe_to_room(room_id)

    {{:ok, room}, Map.put(rooms, room_id, room)}
  end

  defp create_room(_, _, rooms) do
    {{:error, "Error while creating a new room. Try again!"}, rooms}
  end
end
