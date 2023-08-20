defmodule WordexBlast.Rooms.Room do
  use GenServer

  alias WordexBlast.Words
  alias WordexBlast.Rooms.Players
  alias WordexBlast.Rooms.PubSub

  def call(args, room_id) do
    "room:#{room_id}"
    |> String.to_atom()
    |> GenServer.whereis()
    |> handle_pid(args)
  end

  def handle_pid(nil, _), do: {:error, :not_found}
  def handle_pid(pid, args), do: GenServer.call(pid, args)

  def start_link(args) do
    server_name = String.to_atom("room:#{args.id}")
    GenServer.start_link(__MODULE__, args, name: server_name)
  end

  def init(room) do
    Players.subscribe(room.id)
    {:ok, room}
  end

  # Handlers

  def handle_call(:get, _, room) do
    {:reply, room, room}
  end

  # Players tracking

  def handle_info(%{event: "presence_diff", payload: diff, topic: "players:" <> _}, room) do
    players = Players.diff_players(room.players, diff)

    players
    |> Map.keys()
    |> length()
    |> update_room(players, room)
  end

  # Starting game         Destination state ⬎           ⬐ Source state
  def handle_info({:update_room_status, "starting", "waiting", tick_id, 0}, room),
    do: starting_game(tick_id, room)

  # Re-starting game (a new player joins while starting)
  def handle_info({:update_room_status, "starting", "starting", tick_id, 0}, room),
    do: starting_game(tick_id, room)

  def handle_info({:update_room_status, "starting", "waiting", tick_id, tick}, room),
    do: next_tick(tick_id, tick, room)

  def handle_info({:update_room_status, "starting", "starting", tick_id, tick}, room),
    do: next_tick(tick_id, tick, room)

  # Start game
  def handle_info({:update_room_status, "running", "starting", tick_id}, room),
    do: start_game(tick_id, room)

  # Next round
  def handle_info({:next_round, last_player_id}, room),
    do: next_round(last_player_id, room)

  def handle_info(a, room) do
    IO.inspect(a)
    {:noreply, room}
  end

  # # Rooms management

  defp update_room(0, _, room) do
    PubSub.broadcast_room(room, :room_deleted)
    {:noreply, room}
  end

  defp update_room(player_count, players, room) when player_count < 2 do
    room = Map.merge(room, %{players: players, status: "waiting", selected_player: {"", %{}}, tick_id: nil})
    PubSub.broadcast_room(room, :room_updated)

    {:noreply, room}
  end

  defp update_room(_, players, room) do
    tick_id = Ecto.UUID.generate()

    room = Map.merge(room, %{players: players, status: "starting", tick_id: tick_id})

    send(self(), {:update_room_status, "starting", room.status, tick_id, 5})
    PubSub.broadcast_room(room, :room_updated)

    {:noreply, room}
  end

  # # Game status

  defp next_tick(tick_id, tick, room) do
    room = Map.put(room, :tick, tick)
    PubSub.broadcast_room(room, :room_updated)

    server_pid = self()

    Task.start(fn ->
      :timer.sleep(1000)
      send(server_pid, {:update_room_status, "starting", "starting", tick_id, tick - 1})
    end)

    {:noreply, room}
  end

  defp starting_game(tick_id, room) do
    room = Map.merge(room, %{tick: "GO!", hint: Words.get_hint()})
    PubSub.broadcast_room(room, :room_updated)

    server_pid = self()

    Task.start(fn ->
      :timer.sleep(1000)
      send(server_pid, {:update_room_status, "running", "starting", tick_id})
    end)

    {:noreply, room}
  end

  defp start_game(tick_id, room) do
    start_on_valid_tick(room, room.tick_id == tick_id)
  end

  defp start_on_valid_tick(room, false), do: {:noreply, room}

  defp start_on_valid_tick(room, true) do
    selected_player =
      room.players
      |> Enum.filter(&Map.get(elem(&1, 1), :is_playing))
      |> Enum.random()

    room = Map.merge(room, %{status: "running", selected_player: selected_player})
    PubSub.broadcast_room(room, :room_updated)

    server_pid = self()

    Task.start(fn ->
      :timer.sleep(5000)
      send(server_pid, {:next_round, elem(selected_player, 1).id})
    end)

    {:noreply, room}
  end

  defp next_round(last_player_id, room) when room.status == "running" do
    {last_player, _} = Enum.find(room.players, &(Map.get(elem(&1, 1), :id) == last_player_id))

    selected_player =
      room.players
      |> Enum.filter(&Map.get(elem(&1, 1), :is_playing))
      |> Enum.filter(&(Map.get(elem(&1, 1), :id) != last_player_id))
      |> Enum.random()

    hint = Words.get_hint()

    players =
      room.players
      |> Map.update!(last_player, &update_last_player(&1, &1.lives - 1))

    room = Map.merge(room, %{selected_player: selected_player, players: players, hint: hint})
    PubSub.broadcast_room(room, :room_updated)

    active_players = Enum.filter(players, &Map.get(elem(&1, 1), :is_playing))
    is_finished = length(active_players) == 1

    room =
      if is_finished do
        tick_id = Ecto.UUID.generate()

        players =
          players
          |> Enum.map(fn {k, v} -> {k, Map.merge(v, %{lives: 3, is_playing: true})} end)
          |> Map.new()

        room = Map.merge(room, %{status: "finished", players: players, selected_player: hd(active_players), tick_id: tick_id})
        PubSub.broadcast_room(room, :room_updated)
        send(self(), {:update_room_status, "starting", "starting", tick_id, 10})

        room
      else
        room = Map.merge(room, %{selected_player: selected_player, players: players, hint: hint})
        PubSub.broadcast_room(room, :room_updated)

        server_pid = self()

        Task.start(fn ->
          :timer.sleep(5000)
          send(server_pid, {:next_round, elem(selected_player, 1).id})
        end)

        room
      end

    {:noreply, room}
  end

  defp next_round(_, room), do: {:noreply, room}

  defp update_last_player(last_player, 0) do
    Map.merge(last_player, %{lives: 0, is_playing: false})
  end

  defp update_last_player(last_player, lives) do
    Map.put(last_player, :lives, lives)
  end
end
