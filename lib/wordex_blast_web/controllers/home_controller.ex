defmodule WordexBlastWeb.HomeController do
  use WordexBlastWeb, :controller

  def home(conn, _), do: render(conn, :home, layout: {WordexBlastWeb.Layouts, :app})
end
