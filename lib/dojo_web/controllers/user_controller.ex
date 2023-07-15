defmodule DojoWeb.UserController do
  use DojoWeb, :controller

  # alias Dojo.Accounts
  # alias Dojo.Accounts.User

  # def new(conn, _params) do
  #   changeset = Accounts.change_user(%User{})
  #   render(conn, "new.html", changeset: changeset)
  # end

  # def create(conn, %{"user" => user_params}) do
  #   case Accounts.create_user(user_params) do
  #     {:ok, _user} ->
  #       conn
  #       |> put_flash(:info, "User created successfully.")
  #       |> redirect(to: Routes.page_path(conn, :index))

  #     {:error, %Ecto.Changeset{} = changeset} ->
  #       render(conn, "new.html", changeset: changeset)
  #   end
  # end
end
