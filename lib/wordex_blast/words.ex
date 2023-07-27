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
    |> Map.get(:word)
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
