defmodule RequesterWeb.RequestController do
  use RequesterWeb, :controller
  alias RequesterWeb.Http.SendRequest

  def post(conn, params) do
    SendRequest.get_lyrics(params)

    send_resp(conn, 200, "ok")
  end
end
