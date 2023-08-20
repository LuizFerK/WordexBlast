defmodule WordexBlast.Rooms do
  alias WordexBlast.Rooms.Players
  alias WordexBlast.Rooms.PubSub
  alias WordexBlast.Rooms.Room
  alias WordexBlast.Rooms.Rooms

  def subscribe(), do: PubSub.subscribe()
  def subscribe_to_room(room_id), do: PubSub.subscribe_to_room(room_id)

  def track_player(pid, room_id, player) do
    Players.track_player(pid, room_id, Map.put(player, :lives, 3))
  end

  def list_rooms(), do: Rooms.call(:list)

  def create_room() do
    room_id =
      for(_ <- 0..3, do: List.to_string([Enum.random(65..90)]))
      |> Enum.join()

    Rooms.call({:create, room_id})
  end

  def get_room(room_id), do: Room.call(:get, room_id)

  def validate_answer(answer, room_id) do
    Room.call({:validate_answer, answer}, room_id)
  end
end
