defmodule DojoWeb.SetupController do
  use DojoWeb, :controller

  def setup_ai(conn, _params) do
    random_number = :rand.uniform(1000)
    random_number = Integer.to_string(random_number)
    redirect(conn, to: "/#{random_number}")
  end
end
