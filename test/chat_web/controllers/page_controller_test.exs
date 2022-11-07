defmodule DojoWeb.PageControllerTest do
  use DojoWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, "/")
    assert html_response(conn, 200) =~ "Dojo Example"
  end

  # see: https://github.com/dwyl/ping
  test "GET /ping (GIF) renders 1x1 pixel", %{conn: conn} do
    conn = get(conn, "/ping")
    assert conn.status == 200
    assert conn.state == :sent
    assert conn.resp_body =~ <<71, 73, 70, 56, 57>>
  end
end
