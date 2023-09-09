defmodule WordexBlast.Seeds.Accounts do
  alias WordexBlast.Accounts

  def run() do
    [
      %{
        nickname: "Luiz",
        email: "luiz@test.com",
        password: "123123123123",
        points: 200
      },
      %{
        nickname: "João",
        email: "joao@test.com",
        password: "123123123123",
        points: 90
      },
      %{
        nickname: "Pedro",
        email: "pedro@test.com",
        password: "123123123123",
        points: 40
      },
      %{
        nickname: "Ana",
        email: "ana@test.com",
        password: "123123123123",
        points: 120
      },
      %{
        nickname: "José",
        email: "jose@test.com",
        password: "123123123123",
        points: 180
      },
      %{
        nickname: "Marta",
        email: "marta@test.com",
        password: "123123123123",
        points: 140
      }
    ]
    |> Enum.map(&Accounts.register_user/1)
  end
end
