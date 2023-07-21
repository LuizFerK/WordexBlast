defmodule WordexBlastWeb.PageController do
  use WordexBlastWeb, :controller

  def home(conn, _params) do
    render(conn, :home, layout: false)
  end
end
