defmodule OTDBClient.Question do
  @type t :: %__MODULE__{}

  defstruct [:type, :difficulty, :category, :question, :correct_answer, :incorrect_answers]

  _allowed_types = [:multiple, :boolean]
  _allowed_difficulties = [:easy, :medium, :hard]

  @spec new(map()) :: t()
  def new(question_map) do
    with type <- String.to_existing_atom(question_map["type"]),
         difficulty <- String.to_existing_atom(question_map["difficulty"]),
         {:ok, category} <- safe_html_decode(question_map["category"]),
         {:ok, question} <- safe_html_decode(question_map["question"]),
         {:ok, correct_answer} <- safe_html_decode(question_map["correct_answer"]),
         {:ok, incorrect_answers} <- safe_html_deocde_multi(question_map["incorrect_answers"]) do
      {
        :ok,
        %__MODULE__{
          type: type,
          difficulty: difficulty,
          category: category,
          question: question,
          correct_answer: correct_answer,
          incorrect_answers: incorrect_answers
        }
      }
    end
  end

  # `HtmlEntities.decode/1` raises if a non-string argument is provided, so
  # wrapping it in a function that always returns an ok- or error-tuple.
  defp safe_html_decode(encoded_string) do
    try do
      {:ok, HtmlEntities.decode(encoded_string)}
    rescue
      FunctionClauseError -> {:error, :html_decode_non_string}
    end
  end

  defp safe_html_deocde_multi(encoded_strings) do
    encoded_strings
    |> Enum.reduce_while({:ok, []}, fn encoded, {:ok, acc} ->
      case safe_html_decode(encoded) do
        {:ok, decoded} -> {:cont, {:ok, [decoded | acc]}}
        error = {:error, _} -> {:halt, error}
      end
    end)
    |> case do
      {:ok, decoded_strings} -> {:ok, Enum.reverse(decoded_strings)}
      error -> error
    end
  end
end
