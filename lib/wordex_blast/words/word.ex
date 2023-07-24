defmodule WordexBlast.Words.Word do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:word, :string, autogenerate: false}
  schema "words" do
  end

  @doc false
  def changeset(word, attrs) do
    word
    |> cast(attrs, [:word])
    |> validate_required([:word])
  end
end
