defmodule WordexBlast.Rooms.Server do
  use GenServer

  alias WordexBlast.Rooms.Players
  alias WordexBlast.Rooms.PubSub, as: RoomsPubSub

  @server {:global, __MODULE__}

  def call(args) do
    @server
    |> GenServer.whereis()
    |> GenServer.call(args)
  end

  def start_link(init_arg) do
    GenServer.start_link(__MODULE__, init_arg, name: @server)
  end

  def init(_), do: {:ok, %{}}

  # Handlers

  def handle_call(:list, _, rooms) do
    {:reply, list_rooms(rooms), rooms}
  end

  def handle_call({:get, room_id}, _, rooms) do
    {:reply, get_room(room_id, rooms), rooms}
  end

  def handle_call({:create, room_id}, _, rooms) do
    {room, rooms} = create_room(room_id, rooms)
    {:reply, room, rooms}
  end

  # Players tracking
  def handle_info(%{event: "presence_diff", payload: diff, topic: "players:" <> room_id}, rooms) do
    room = Map.get(rooms, room_id)
    players = Players.diff_players(room.players, diff)

    players
    |> Map.keys()
    |> length()
    |> update_room(room, rooms, players)
  end

  # Starting game         Destination state ⬎           ⬐ Source state
  def handle_info({:update_room_status, "starting", "waiting", room_id, tick_id}, rooms),
    do: starting_game(room_id, tick_id, rooms)

  # Re-starting game (a new player joins while starting)
  def handle_info({:update_room_status, "starting", "starting", room_id, tick_id}, rooms),
    do: starting_game(room_id, tick_id, rooms)

  # Start game
  def handle_info({:update_room_status, "running", "starting", room_id, tick_id}, rooms),
    do: start_game(room_id, tick_id, rooms)

  def handle_info(a, rooms) do
    IO.inspect(a)
    {:noreply, rooms}
  end

  # Rooms management

  defp list_rooms(rooms) do
    Enum.map(rooms, fn {k, v} -> Map.put(v, :id, k) end)
  end

  defp get_room(room_id, rooms) do
    rooms
    |> Map.get(room_id)
    |> get_room()
  end

  defp get_room(nil), do: nil
  defp get_room(room), do: Map.put(room, :id, room.id)

  defp create_room(room_id, rooms) do
    rooms
    |> Map.get(room_id)
    |> create_room(room_id, rooms)
  end

  defp create_room(nil, room_id, rooms) do
    room = %{id: room_id, status: "waiting", players: %{}}
    rooms = Map.put(rooms, room_id, room)

    Players.subscribe(room_id)
    RoomsPubSub.broadcast(room, :room_created)

    {{:ok, room}, rooms}
  end

  defp create_room(_, _, rooms) do
    {{:error, "Error while creating a new room. Try again!"}, rooms}
  end

  defp update_room(0, room, rooms, _) do
    rooms = Map.drop(rooms, [room.id])
    RoomsPubSub.broadcast(room, :room_deleted)

    {:noreply, rooms}
  end

  defp update_room(player_count, room, rooms, players)
       when player_count < 2 or room.status == "running" do
    room = Map.put(room, :players, players)
    rooms = Map.put(rooms, room.id, room)

    RoomsPubSub.broadcast_room(room, :room_updated)

    {:noreply, rooms}
  end

  defp update_room(_, room, rooms, players) do
    tick_id = Ecto.UUID.generate()

    room = Map.merge(room, %{players: players, status: "starting", tick_id: tick_id})
    rooms = Map.put(rooms, room.id, room)

    send(self(), {:update_room_status, "starting", room.status, room.id, tick_id})
    RoomsPubSub.broadcast_room(room, :room_updated)

    {:noreply, rooms}
  end

  # Game status

  defp starting_game(room_id, tick_id, rooms) do
    server_pid = self()

    Task.start(fn ->
      :timer.sleep(5000)
      send(server_pid, {:update_room_status, "running", "starting", room_id, tick_id})
    end)

    {:noreply, rooms}
  end

  defp start_game(room_id, tick_id, rooms) do
    rooms
    |> Map.get(room_id)
    |> then(&start_on_valid_tick(&1, rooms, &1.tick_id == tick_id))
  end

  defp start_on_valid_tick(_room, rooms, false), do: {:noreply, rooms}

  defp start_on_valid_tick(room, rooms, true) do
    room = Map.put(room, :status, "running")
    rooms = Map.put(rooms, room.id, room)

    RoomsPubSub.broadcast_room(room, :room_updated)

    {:noreply, rooms}
  end
end