defmodule RequesterWeb.Router do
  use RequesterWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", RequesterWeb do
    pipe_through :api

    post("/send", RequestController, :post)
  end
end
