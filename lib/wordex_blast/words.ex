defmodule WordexBlast.Words do
  @moduledoc """
  The Words context.
  """

  import Ecto.Query, warn: false
  alias WordexBlast.Repo

  alias WordexBlast.Words.Word

  @doc """
  Gets a single word.

  Returns nil if the Word does not exist.

  ## Examples

      iex> get_word("example")
      %Word{}

      iex> get_word("exampl")
      nil

  """
  def get_word(word) do
    Word
    |> Repo.get_by(word: word)
    |> handle_get_word()
  end

  defp handle_get_word(nil), do: nil
  defp handle_get_word(word), do: Map.get(word, :word)

  @doc """
  Gets a word hint.

  ## Examples

      iex> get_hint()
      "avr"

  """
  def get_hint() do
    id = Enum.random(1..245_366)
    size = Enum.random([2, 3])

    word =
      Word
      |> Repo.get_by(id: id)
      |> Map.get(:word)

    slice = String.length(word) / size
    slice = floor(slice)

    String.slice(word, slice..(slice + size - 1))
  end

  @doc """
  Creates a word.

  ## Examples

      iex> create_word(%{id: 1, word: "example"})
      {:ok, %Word{}}
  ** (Ecto.NoResultsError)
      iex> create_word(%{id: 1, word: 1})
      {:error, %Ecto.Changeset{}}

  """
  def create_word(attrs \\ %{}) do
    %Word{}
    |> Word.changeset(attrs)
    |> Repo.insert()
  end
end
