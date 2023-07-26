defmodule WordexBlast.WordsTest do
  use WordexBlast.DataCase, async: true

  alias WordexBlast.Words

  describe "words" do
    import WordexBlast.WordsFixtures

    @invalid_attrs %{word: nil}

    test "get_word/1 returns the word with given word" do
      word = word_fixture()
      assert Words.get_word(word) == word
    end

    test "create_word/1 with valid data creates a word" do
      assert {:ok, word} = Words.create_word("word")
      assert word == "word"
    end

    test "create_word/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Words.create_word(@invalid_attrs)
    end
  end
end
