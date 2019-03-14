defmodule RequesterWeb.Http.SendRequest do
  @api_url "https://orion.apiseeds.com/api/music/lyric/"
  @elchatto_url "https://app.elchatto.com/api/integrations"

  def get_lyrics(params) do
    case HTTPoison.get(@api_url <> "#{params["artist"]}/#{params["song"]}?apikey=#{params["apikey"]}", [], [timeout: 30_000, recv_timeout: 30_000]) do
      {:ok, %{status_code: 200, body: body}} ->
        body = Poison.decode!(body, keys: :atoms)
        success_postback_elchatto(body, params)
      {:ok, %{status_code: 404}} ->
        not_found_postback_elchatto(params)
      _ ->
        error_postback_elchatto(params)
    end
  end

  def success_postback_elchatto(resp_body, params) do
    lyrics = process_lyrics(resp_body.result.track.text)
    body = %{
      token: params["integration_token"],
      chatbot_id: params["bot_id"],
      component_id: params["success_block"],
      messenger_user_id: params["messenger_user_id"],
      attributes: [
        %{
          name: "artist_name",
          value: resp_body.result.artist.name
        },
        %{
          name: "song",
          value: resp_body.result.track.name
        },
        %{
          name: "notice",
          value: resp_body.result.copyright.notice
        },
        %{
          name: "copyright",
          value: resp_body.result.copyright.artist
        },
        %{
          name: "copyright_message",
          value: resp_body.result.copyright.text
        } | lyrics
      ]
    } |> Poison.encode!
    headers = ["Content-Type": "Application/json"]
    HTTPoison.post(@elchatto_url, body, headers, [timeout: 30_000, recv_timeout: 30_000])
  end

  def process_lyrics(lyrics) do
    length = lyrics
    |> String.length()

    attribute_needed = length
    |> Kernel./(255)

    remainder = length
    |> Kernel.rem(255)

    attribute_needed =
      case remainder do
        0 -> attribute_needed
        _ -> attribute_needed
        |> round
        |> Kernel.+(1)
      end

    Enum.map(1..attribute_needed, fn(x) ->
      start = x
      |> Kernel.-(1)
      |> Kernel.*(255)
      last_count = x
      |> Kernel.*(255)
      |> Kernel.-(1)

      %{
        name: "lyrics_ext#{x}",
        value: String.slice(lyrics, start..last_count)
      }
    end)
  end

  def not_found_postback_elchatto(params) do
    body = %{
      token: params["integration_token"],
      chatbot_id: params["bot_id"],
      component_id: params["not_found_block"],
      messenger_user_id: params["messenger_user_id"]
    } |> Poison.encode!
    headers = ["Content-Type": "Application/json"]
    HTTPoison.post(@elchatto_url, body, headers, [timeout: 30_000, recv_timeout: 30_000])
  end

  def error_postback_elchatto(params) do
    body = %{
      token: params["integration_token"],
      chatbot_id: params["bot_id"],
      component_id: params["error_block"],
      messenger_user_id: params["messenger_user_id"]
    } |> Poison.encode!
    headers = ["Content-Type": "Application/json"]
    HTTPoison.post(@elchatto_url, body, headers, [timeout: 30_000, recv_timeout: 30_000])
  end
end
