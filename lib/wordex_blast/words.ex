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
      "example"

      iex> get_word("exampl")
      nil

  """
  def get_word(word) do
    Word
    |> Repo.get(word)
    |> Map.get(:word)
  end

  @doc """
  Creates a word.

  ## Examples

      iex> create_word("example")
      {:ok, "example"}
  ** (Ecto.NoResultsError)
      iex> create_word(1)
      {:error, %Ecto.Changeset{}}

  """
  def create_word({:ok, %Word{word: word}}) do
    {:ok, word}
  end

  def create_word({:error, _} = error), do: error

  def create_word(word) do
    %Word{}
    |> Word.changeset(%{word: word})
    |> Repo.insert()
    |> create_word()
  end
end
