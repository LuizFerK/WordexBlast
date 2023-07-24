defmodule WordexBlast.RoomsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `WordexBlast.Rooms` context.
  """

  @doc """
  Generate a room.
  """
  def room_fixture(attrs \\ %{}) do
    {:ok, room} =
      attrs
      |> Enum.into(%{
        is_private: true,
        language: "some language"
      })
      |> WordexBlast.Rooms.create_room()

    room
  end
end
