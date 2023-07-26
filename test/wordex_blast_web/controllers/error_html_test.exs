defmodule WordexBlastWeb.ErrorHTMLTest do
  use WordexBlastWeb.ConnCase, async: true

  # Bring render_to_string/4 for testing custom views
  import Phoenix.Template

  test "renders 404.html" do
    assert render_to_string(WordexBlastWeb.ErrorHTML, "404", "html", []) =~ "404!"
  end

  test "renders 500.html" do
    assert render_to_string(WordexBlastWeb.ErrorHTML, "500", "html", []) =~ "500!"
  end
end
