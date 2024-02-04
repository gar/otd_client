defmodule OTDBClient.HTTPClient do
  @moduledoc """
  An client that connects to OTDB's HTTP API.
  """
  alias OTDBClient.Question

  @behaviour OTDBClient

  @spec get_questions() :: [Question.t()] | {:error, term()}
  @impl true
  def get_questions(opts \\ []) do
    with {:ok, params} <- build_question_params(opts),
         {:ok, response} <- request("/api.php", params),
         {:ok, successful_response} <- parse_response(response) do
      successful_response.body["results"]
    end
  end

  @allowed_question_params ~w(amount category difficulty type)a
  defp build_question_params(opts) do
    opts
    |> Keyword.keys()
    |> Enum.all?(fn key -> key in @allowed_question_params end)
    |> case do
      true -> {:ok, Keyword.merge([amount: 10], opts)}
      false -> {:error, "Invalid question params in #{inspect(opts)}"}
    end
  end

  defp request(path, params) do
    Req.new(base_url: "https://opentdb.com/")
    |> Req.get(url: path, params: params)
  end

  defp parse_response(%Req.Response{body: %{"response_code" => 0}} = response),
    do: {:ok, response}

  defp parse_response(%Req.Response{body: %{"response_code" => 1}}), do: {:error, :no_results}

  defp parse_response(%Req.Response{body: %{"response_code" => 2}}),
    do: {:error, :invalid_parameter}

  defp parse_response(%Req.Response{body: %{"response_code" => 3}}),
    do: {:error, :token_not_found}

  defp parse_response(%Req.Response{body: %{"response_code" => 4}}), do: {:error, :token_empty}
  defp parse_response(%Req.Response{body: %{"response_code" => 5}}), do: {:error, :rate_limit}
end
