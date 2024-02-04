defmodule OTDBClient do
  @moduledoc """
  A client to access trivia questions from the Open Trivia DB.
  """

  alias OTDBClient.HTTPClient
  alias OTDBClient.Question

  @callback get_questions() :: [Question.t()]

  @spec get_questions(keyword()) :: [Question.t()] | {:error, term()}
  def get_questions(opts \\ []) do
    impl().get_questions(opts)
    |> Enum.reduce_while({:ok, []}, fn question_map, {:ok, acc} ->
      case Question.new(question_map) do
        {:ok, question} -> {:cont, {:ok, [question | acc]}}
        {:error, _} = error -> {:halt, error}
      end
    end)
    |> case do
      {:ok, questions} -> Enum.reverse(questions)
      error -> error
    end
  end

  defp impl do
    Application.get_env(:otdb_client, :api_client, HTTPClient)
  end
end
