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
  def handle_info({:update_room_status, "starting", "waiting", room_id, tick_id, 0}, rooms),
    do: starting_game(room_id, tick_id, rooms)

  # Re-starting game (a new player joins while starting)
  def handle_info({:update_room_status, "starting", "starting", room_id, tick_id, 0}, rooms),
    do: starting_game(room_id, tick_id, rooms)

  def handle_info({:update_room_status, "starting", "waiting", room_id, tick_id, tick}, rooms),
    do: next_tick(room_id, tick_id, tick, rooms)

  def handle_info({:update_room_status, "starting", "starting", room_id, tick_id, tick}, rooms),
    do: next_tick(room_id, tick_id, tick, rooms)

  # Start game
  def handle_info({:update_room_status, "running", "starting", room_id, tick_id}, rooms),
    do: start_game(room_id, tick_id, rooms)

  # Next round
  def handle_info({:next_round, last_player_id, room_id}, rooms),
    do: next_round(last_player_id, room_id, rooms)

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
    room = %{id: room_id, status: "waiting", tick: 5, players: %{}, selected_player: {"", %{}}}
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
       when player_count < 2 and room.status == "running" do
    room = Map.merge(room, %{players: players, status: "waiting", selected_player: {"", %{}}})
    rooms = Map.put(rooms, room.id, room)

    RoomsPubSub.broadcast_room(room, :room_updated)

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

    send(self(), {:update_room_status, "starting", room.status, room.id, tick_id, 5})
    RoomsPubSub.broadcast_room(room, :room_updated)

    {:noreply, rooms}
  end

  # Game status

  defp next_tick(room_id, tick_id, tick, rooms) do
    room =
      rooms
      |> Map.get(room_id)
      |> Map.put(:tick, tick)

    rooms = Map.put(rooms, room_id, room)

    RoomsPubSub.broadcast_room(room, :room_updated)

    server_pid = self()

    Task.start(fn ->
      :timer.sleep(1000)
      send(server_pid, {:update_room_status, "starting", "starting", room_id, tick_id, tick - 1})
    end)

    {:noreply, rooms}
  end

  defp starting_game(room_id, tick_id, rooms) do
    room =
      rooms
      |> Map.get(room_id)
      |> Map.put(:tick, "GO!")

    rooms = Map.put(rooms, room_id, room)

    RoomsPubSub.broadcast_room(room, :room_updated)

    server_pid = self()

    Task.start(fn ->
      :timer.sleep(1000)
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
    selected_player =
      room.players
      |> Enum.filter(&Map.get(elem(&1, 1), :is_playing))
      |> Enum.random()

    room = Map.merge(room, %{status: "running", selected_player: selected_player})
    rooms = Map.put(rooms, room.id, room)

    RoomsPubSub.broadcast_room(room, :room_updated)

    server_pid = self()

    Task.start(fn ->
      :timer.sleep(5000)
      send(server_pid, {:next_round, elem(selected_player, 1).id, room.id})
    end)

    {:noreply, rooms}
  end

  defp next_round(last_player_id, room_id, rooms) do
    room = Map.get(rooms, room_id)

    if room.status == "running" do
      selected_player =
        room.players
        |> Enum.filter(&Map.get(elem(&1, 1), :is_playing))
        |> Enum.filter(&(Map.get(elem(&1, 1), :id) != last_player_id))
        |> Enum.random()

      room = Map.put(room, :selected_player, selected_player)

      RoomsPubSub.broadcast_room(room, :room_updated)

      server_pid = self()

      Task.start(fn ->
        :timer.sleep(5000)
        send(server_pid, {:next_round, elem(selected_player, 1).id, room_id})
      end)

      {:noreply, rooms}
    else
      {:noreply, rooms}
    end
  end
end
