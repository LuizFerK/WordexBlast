defmodule WordexBlast.Rooms do
  alias WordexBlast.Rooms.Players
  alias WordexBlast.Rooms.PubSub
  alias WordexBlast.Rooms.Server

  def subscribe(), do: PubSub.subscribe()
  def subscribe_to_room(room_id), do: PubSub.subscribe_to_room(room_id)

  def track_player(pid, room_id, player) do
    Players.track_player(pid, room_id, player)
  end

  def list_rooms(), do: Server.call(:list)
  def get_room(room_id), do: Server.call({:get, room_id})

  def create_room() do
    room_id =
      for(_ <- 0..3, do: List.to_string([Enum.random(65..90)]))
      |> Enum.join()

    Server.call({:create, room_id})
  end
end
