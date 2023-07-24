defmodule WordexBlast.Repo.Migrations.CreateWords do
  use Ecto.Migration

  def change do
    create table(:words, primary_key: false) do
      add :word, :string, primary_key: true
    end
  end
end
