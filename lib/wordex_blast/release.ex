defmodule WordexBlast.Release do
  @moduledoc """
  Used for executing DB release tasks when run in production without Mix
  installed.
  """
  alias WordexBlast.Seeds

  @app :wordex_blast

  def migrate do
    load_app()

    for repo <- repos() do
      {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :up, all: true))
    end
  end

  def seeds do
    load_app()

    {:ok, _, _} = Ecto.Migrator.with_repo(WordexBlast.Repo, fn _ -> run_seeds() end)
  end

  def rollback(repo, version) do
    load_app()
    {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :down, to: version))
  end

  defp run_seeds do
    Seeds.Accounts.run()
    Seeds.PtBrWords.run()
  end

  defp repos do
    Application.fetch_env!(@app, :ecto_repos)
  end

  defp load_app do
    Application.load(@app)
  end
end
