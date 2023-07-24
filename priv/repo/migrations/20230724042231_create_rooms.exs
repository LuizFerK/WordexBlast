defmodule WordexBlast.Repo.Migrations.CreateRooms do
  use Ecto.Migration

  def change do
    create table(:rooms, primary_key: false) do
      add :id, :string, primary_key: true
      add :is_private, :boolean, default: false, null: false
      add :language, :string

      timestamps()
    end
  end
end
