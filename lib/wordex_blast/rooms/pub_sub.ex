defmodule WordexBlast.Rooms.PubSub do
  @rooms_topic "rooms"
  @room_topic "room:"

  def subscribe(), do: Phoenix.PubSub.subscribe(WordexBlast.PubSub, @rooms_topic)

  def subscribe_to_room(room_id),
    do: Phoenix.PubSub.subscribe(WordexBlast.PubSub, @room_topic <> room_id)

  def broadcast(room, tag) do
    Phoenix.PubSub.broadcast(
      WordexBlast.PubSub,
      @rooms_topic,
      {tag, room}
    )
  end

  def broadcast_room(room, tag) do
    Phoenix.PubSub.broadcast(
      WordexBlast.PubSub,
      @room_topic <> room.id,
      {tag, room}
    )
  end
end
