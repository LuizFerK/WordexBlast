defmodule WordexBlast.Rooms.Room do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :string, autogenerate: false}
  schema "rooms" do
    field :is_private, :boolean, default: false
    field :language, :string

    timestamps()
  end

  @doc false
  def changeset(room, attrs) do
    room
    |> cast(attrs, [:id, :is_private, :language])
    |> validate_required([:id])
    |> unique_constraint(:id)
  end
end
