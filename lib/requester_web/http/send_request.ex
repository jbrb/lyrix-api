defmodule RequesterWeb.Http.SendRequest do
  @api_url "https://api.genius.com/search?q="
  @elchatto_url "https://app.elchatto.com/api/integrations"

  def get_lyrics(params) do
    keyword = String.replace(params["song"], " ", "%20")
    url = @api_url <> keyword
    case HTTPoison.get(url, %{"Authorization" => "Bearer #{params["apikey"]}"}) do
      {:ok, %{status_code: 200, body: body}} ->
        body = Poison.decode!(body, keys: :atoms)

        case List.first(body.response.hits) do
          nil -> not_found_postback_elchatto(params)
          first_hit ->
            song_data = fetch_song_data(first_hit.result.url)
            success_postback_elchatto(song_data, params)
        end
      _ ->
        error_postback_elchatto(params)
    end
  end

  def fetch_song_data(url) do
    {:ok, %{body: body}} = HTTPoison.get(url)

    title = body
    |> Floki.find(".header_with_cover_art-primary_info")
    |> stringify_title_base()

    lyrics = body
    |> Floki.find(".lyrics")
    |> Floki.find("p")
    |> stringify_lyric_base()

    %{title: title, lyrics: lyrics}
   end

  def stringify_lyric_base(lyric_base) do
    Enum.map(lyric_base, fn
      {_, _, lyrics} ->
        stringify_lyric_base(lyrics)
      ""<>lyric -> lyric<>"\n"
      _ -> ""
    end)
    |> List.flatten
    |> to_string
  end

  def stringify_title_base(title_base) do
    Enum.map(title_base, fn
      {_, _, title} ->
        stringify_title_base(title)
      ""<>title -> title
      _ -> ""
    end)
    |> List.flatten
  end

  def success_postback_elchatto(song_data, params) do
    lyrics = process_lyrics(song_data.lyrics)
    body = %{
      token: params["integration_token"],
      chatbot_id: params["bot_id"],
      component_id: params["success_block"],
      messenger_user_id: params["messenger_user_id"],
      attributes: [
        %{
          name: "artist_name",
          value: Enum.at(song_data.title, 1)
        },
        %{
          name: "song",
          value: Enum.at(song_data.title, 0)
        } | lyrics
      ]
    } |> Poison.encode!
    headers = ["Content-Type": "Application/json"]
    HTTPoison.post(@elchatto_url, body, headers, [timeout: 30_000, recv_timeout: 30_000])
  end

  def process_lyrics(lyrics) do
    lyrics = String.replace(lyrics, "\r", "")
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
