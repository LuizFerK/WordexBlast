defmodule WordexBlast.WordsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `WordexBlast.Words` context.
  """

  @doc """
  Generate a word.
  """
  def word_fixture() do
    {:ok, word} = WordexBlast.Words.create_word("word")
    word
  end
end
