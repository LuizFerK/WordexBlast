defmodule WordexBlast.Words.Word do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :id, autogenerate: true}
  schema "words" do
    field(:word, :string)
  end

  @doc false
  def changeset(word, attrs) do
    word
    |> cast(attrs, [:word])
    |> validate_required([:word])
  end
end
