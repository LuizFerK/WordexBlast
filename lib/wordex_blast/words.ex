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
  def get_word(id), do: Repo.get(Word, id)

  @doc """
  Creates a word.

  ## Examples

      iex> create_word(%{field: value})
      {:ok, %Word{}}
  ** (Ecto.NoResultsError)
      iex> create_word(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_word(attrs \\ %{}) do
    %Word{}
    |> Word.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Deletes a word.

  ## Examples

      iex> delete_word(word)
      {:ok, %Word{}}

      iex> delete_word(word)
      {:error, %Ecto.Changeset{}}

  """
  def delete_word(%Word{} = word) do
    Repo.delete(word)
  end
end
