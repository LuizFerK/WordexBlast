defmodule WordexBlast.Rooms do
  use GenServer

  @server {:global, __MODULE__}

  # Client

  def subscribe, do: Phoenix.PubSub.subscribe(WordexBlast.PubSub, "rooms")

  def subscribe_to_room(room_id),
    do: Phoenix.PubSub.subscribe(WordexBlast.PubSub, "room:#{room_id}")

  def list_rooms() do
    GenServer.call(server_pid(), :list)
  end

  def get_room(room_id) do
    GenServer.call(server_pid(), {:get, room_id})
  end

  def create_room() do
    room_id =
      for(_ <- 0..3, do: List.to_string([Enum.random(65..90)]))
      |> Enum.join()

    GenServer.call(server_pid(), {:create, room_id})
  end

  # Server

  def server_pid(), do: GenServer.whereis(@server)

  def start_link(init_arg) do
    GenServer.start_link(__MODULE__, init_arg, name: @server)
  end

  def init(_) do
    {:ok, %{}}
  end

  def handle_call(:list, _, rooms) do
    {:reply, Enum.map(rooms, fn {k, v} -> Map.put(v, :id, k) end), rooms}
  end

  def handle_call({:get, room_id}, _, rooms) do
    room =
      case Map.get(rooms, room_id) do
        nil -> nil
        room -> Map.put(room, :id, room_id)
      end

    {:reply, room, rooms}
  end

  def handle_call({:create, room_id}, _, rooms) do
    Phoenix.PubSub.subscribe(WordexBlast.PubSub, "presence:#{room_id}")
    room = %{id: room_id, status: "waiting", players: %{}}
    broadcast(room, :room_created)

    {:reply, {:ok, room}, Map.put(rooms, room_id, room)}
  end

  # Presence tracking
  def handle_info(%{event: "presence_diff", payload: diff, topic: "presence:" <> room_id}, rooms) do
    room = Map.get(rooms, room_id)

    presences =
      room.players
      |> remove_presences(diff.leaves)
      |> add_presences(diff.joins)

    case Map.keys(presences) |> length() do
      0 ->
        broadcast(room, :room_deleted)
        {:noreply, Map.drop(rooms, [room_id])}

      p when p < 2 ->
        room = Map.put(room, :players, presences)
        broadcast_room(room, :room_updated)

        {:noreply, Map.put(rooms, room_id, room)}

      _ ->
        tick_id = Ecto.UUID.generate()
        send(self(), {:update_room_status, "starting", room.status, room_id, tick_id})
        room = Map.merge(room, %{players: presences, status: "starting", tick_id: tick_id})
        broadcast_room(room, :room_updated)

        {:noreply, Map.put(rooms, room_id, room)}
    end
  end

  # Starting game
  def handle_info({:update_room_status, "starting", "waiting", room_id, tick_id}, rooms) do
    server_pid = self()

    Task.start(fn ->
      :timer.sleep(5000)
      send(server_pid, {:update_room_status, "running", "starting", room_id, tick_id})
    end)

    {:noreply, rooms}
  end

  # Re-starting game (a new player joins while starting)
  def handle_info({:update_room_status, "starting", "starting", room_id, tick_id}, rooms) do
    server_pid = self()

    Task.start(fn ->
      :timer.sleep(5000)
      send(server_pid, {:update_room_status, "running", "starting", room_id, tick_id})
    end)

    {:noreply, rooms}
  end

  # Start game
  def handle_info({:update_room_status, "running", "starting", room_id, tick_id}, rooms) do
    room = Map.get(rooms, room_id)

    if room.tick_id == tick_id do
      # send(self(), {:update_room_status, "running", "waiting", tick_id})
      updated_room = Map.put(room, :status, "running")
      broadcast_room(updated_room, :room_updated)
      {:noreply, Map.put(rooms, room_id, updated_room)}
    else
      {:noreply, rooms}
    end
  end

  def handle_info(a, rooms) do
    IO.inspect(a)
    {:noreply, rooms}
  end

  defp remove_presences(presences, leaves) do
    user_ids = Enum.map(leaves, fn {user_id, _} -> user_id end)
    Map.drop(presences, user_ids)
  end

  defp add_presences(presences, joins) do
    Map.merge(presences, simple_presence_map(joins))
  end

  def simple_presence_map(presences) do
    Enum.into(presences, %{}, fn {user_id, %{metas: [meta | _]}} ->
      {user_id, meta}
    end)
  end

  # Rooms PubSub
  def broadcast(room, tag) do
    Phoenix.PubSub.broadcast(
      WordexBlast.PubSub,
      "rooms",
      {tag, room}
    )
  end

  def broadcast_room(room, tag) do
    Phoenix.PubSub.broadcast(
      WordexBlast.PubSub,
      "room:#{room.id}",
      {tag, room}
    )
  end
end
