defmodule DojoWeb.SetupController do
  use DojoWeb, :controller

  def setup_ai(conn, _params) do
    pid = self()
    redirect(conn, to: "/#{pid}")
  end
end
