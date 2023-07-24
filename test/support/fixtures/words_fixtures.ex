defmodule WordexBlast.WordsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `WordexBlast.Words` context.
  """

  @doc """
  Generate a word.
  """
  def word_fixture(attrs \\ %{}) do
    {:ok, word} =
      attrs
      |> Enum.into(%{
        word: "some word"
      })
      |> WordexBlast.Words.create_word()

    word
  end
end
