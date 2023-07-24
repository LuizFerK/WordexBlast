defmodule WordexBlast.Rooms do
  @moduledoc """
  The Rooms context.
  """

  import Ecto.Query, warn: false
  alias WordexBlast.Repo

  alias WordexBlast.Rooms.Room

  def subscribe do
    Phoenix.PubSub.subscribe(WordexBlast.PubSub, "rooms")
  end

  def broadcast({:ok, room}, tag) do
    Phoenix.PubSub.broadcast(
      WordexBlast.PubSub,
      "rooms",
      {tag, room}
    )

    {:ok, room}
  end

  def broadcast({:error, _changeset} = error, _tag), do: error

  @doc """
  Returns the list of rooms.

  ## Examples

      iex> list_rooms()
      [%Room{}, ...]

  """
  def list_rooms do
    Repo.all(Room)
  end

  @doc """
  Gets a single room.

  Returns nil if the Room does not exist.

  ## Examples

      iex> get_room("AB12")
      %Room{}

      iex> get_room("CD34")
      nil

  """
  def get_room(id), do: Repo.get(Room, id)

  @doc """
  Creates a room.

  ## Examples

      iex> create_room(%{field: value})
      {:ok, %Room{}}

      iex> create_room(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_room(attrs \\ %{}) do
    id =
      for(_ <- 0..3, do: List.to_string([Enum.random(65..90)]))
      |> Enum.join()

    attrs = Map.put(attrs, :id, id)

    %Room{}
    |> Room.changeset(attrs)
    |> Repo.insert()
    |> broadcast(:room_created)
  end

  @doc """
  Updates a room.

  ## Examples

      iex> update_room(room, %{field: new_value})
      {:ok, %Room{}}

      iex> update_room(room, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_room(%Room{} = room, attrs) do
    room
    |> Room.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a room.

  ## Examples

      iex> delete_room(room)
      {:ok, %Room{}}

      iex> delete_room(room)
      {:error, %Ecto.Changeset{}}

  """
  def delete_room(%Room{} = room) do
    room
    |> Repo.delete()
    |> broadcast(:room_deleted)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking room changes.

  ## Examples

      iex> change_room(room)
      %Ecto.Changeset{data: %Room{}}

  """
  def change_room(%Room{} = room, attrs \\ %{}) do
    Room.changeset(room, attrs)
  end
end
