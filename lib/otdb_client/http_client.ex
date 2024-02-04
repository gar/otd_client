defmodule OTDBClient.HTTPClient do
  @moduledoc """
  An client that connects to OTDB's HTTP API.
  """
  alias OTDBClient.Question

  @behaviour OTDBClient

  @spec get_questions() :: [Question.t()] | {:error, term()}
  @impl true
  def get_questions do
    with {:ok, response} <- Req.get("https://opentdb.com/api.php?amount=10"),
         {:ok, successful_response} <- parse_response(response) do
      successful_response.body["results"]
    end
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
