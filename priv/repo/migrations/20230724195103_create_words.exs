defmodule WordexBlast.Repo.Migrations.CreateWords do
  use Ecto.Migration

  def change do
    create table(:words, primary_key: false) do
      add :id, :serial, primary_key: true
      add :word, :string
    end

    create index("words", [:word], unique: true)
  end
end
