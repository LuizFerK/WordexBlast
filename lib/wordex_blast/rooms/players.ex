defmodule WordexBlast.Rooms.Players do
  alias WordexBlastWeb.Presence

  @topic "players:"

  def subscribe(room_id) do
    Phoenix.PubSub.subscribe(WordexBlast.PubSub, @topic <> room_id)
  end

  def track_player(pid, room_id, player) do
    Presence.track(pid, @topic <> room_id, player.id, player)
  end

  def diff_players(players, diff) do
    players
    |> remove_players(diff.leaves)
    |> add_players(diff.joins)
  end

  defp remove_players(players, leaves) do
    user_ids = Enum.map(leaves, fn {user_id, _} -> user_id end)
    Map.drop(players, user_ids)
  end

  defp add_players(players, joins) do
    Map.merge(players, simple_player_map(joins))
  end

  defp simple_player_map(players) do
    Enum.into(players, %{}, fn {player_id, %{metas: [player | _]}} ->
      {player_id, player}
    end)
  end
end
