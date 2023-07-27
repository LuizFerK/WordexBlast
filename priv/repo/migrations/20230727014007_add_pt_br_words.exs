defmodule WordexBlast.Repo.Migrations.AddPtBrWords do
  use Ecto.Migration

  alias WordexBlast.Repo
  alias WordexBlast.Words

  def up do
    "assets/dictionaries/pt-br.txt"
    |> File.read!()
    |> String.split("\n")
    |> Enum.with_index()
    |> Enum.each(fn {word, idx} ->
      Words.create_word(%{id: idx, word: word})
    end)
  end

  def down do
    Repo.query("delete from words;")
  end
end
