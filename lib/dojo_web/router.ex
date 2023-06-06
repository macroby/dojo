defmodule DojoWeb.Router do
  use DojoWeb, :router

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_flash)
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
  end

  pipeline :api do
    plug(:accepts, ["json"])
    plug(:fetch_session)
    plug(:fetch_flash)
    plug(:put_secure_browser_headers)
  end

  scope "/", DojoWeb do
    pipe_through(:browser)

    get("/", PageController, :index)
    get("/:gameid", PageController, :room)
    get("/ping", PageController, :ping)
  end

  scope "/", DojoWeb do
    pipe_through(:api)

    post("/:gameid/accept", PageController, :accept)
    post("/:gameid/cancel", PageController, :cancel)
  end

  scope "/setup", DojoWeb do
    pipe_through(:browser)

    post("/friend", SetupController, :setup_friend)
    post("/ai", SetupController, :setup_ai)
  end

  # Other scopes may use custom stacks.
  # scope "/api", DojoWeb do
  #   pipe_through :api
  # end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through(:browser)
      live_dashboard("/dashboard", metrics: DojoWeb.Telemetry)
    end
  end
end
