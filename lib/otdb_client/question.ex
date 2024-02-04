defmodule OTDBClient.Question do
  @allowed_types [:multiple, :boolean]
  @allowed_difficulties [:easy, :medium, :hard]

  @moduledoc """
  A struct representing a trivia question along with conveniences functions on
  the struct.

  The struct contains fields related to the question and answers:
  - `:question`: the text of the question
  - `:correct_answer`: the correct answer to the question
  - `:incorrect_answers`: other possible answers, but which are not correct

  The struct also contains some meta-data about the question:
  - `:type`: the expected answer format. Allowed values: #{Enum.join(@allowed_types, ", ")}.
  - `:difficulty`: the difficulty of answering the question: #{Enum.join(@allowed_difficulties, ", ")}.
  - `category`: a string representing the category to which the question
      belongs, e.g. "General Knowledge", "Arts & Entertainment".
  """
  @type t :: %__MODULE__{}

  defstruct [:type, :difficulty, :category, :question, :correct_answer, :incorrect_answers]

  @doc """
  Takes a map representing a question and converts it into a struct.

  Returns an ok-tuple if everything worked, an error-tuple otherwise.

  The following are all required fields on the map (all strings):
  - "type"
  - "difficulty"
  - "category"
  - "question"
  - "correct_answer"
  - "incorrect_answers"
  """
  @spec new(map()) ::
          {:ok, t()}
          | {:error, {:not_existing_atom, binary()}}
          | {:error, {:html_decode_error, binary()}}
  def new(%{
        "type" => type,
        "difficulty" => difficulty,
        "category" => category,
        "question" => question,
        "correct_answer" => correct_answer,
        "incorrect_answers" => incorrect_answers
      }) do
    with {:ok, type} <- safe_to_existing_atom(type),
         {:ok, difficulty} <- safe_to_existing_atom(difficulty),
         {:ok, category} <- safe_html_decode(category),
         {:ok, question} <- safe_html_decode(question),
         {:ok, correct_answer} <- safe_html_decode(correct_answer),
         {:ok, incorrect_answers} <- safe_html_deocde_multi(incorrect_answers) do
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

  defp safe_to_existing_atom(string) do
    {:ok, String.to_existing_atom(string)}
  rescue
    ArgumentError -> {:error, {:not_existing_atom, inspect(string)}}
  end

  # `HtmlEntities.decode/1` raises if a non-string argument is provided, so
  # wrapping it in a function that always returns an ok- or error-tuple.
  defp safe_html_decode(encoded_string) do
    {:ok, HtmlEntities.decode(encoded_string)}
  rescue
    FunctionClauseError -> {:error, {:html_decode_error, inspect(encoded_string)}}
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

  @doc false
  # Just used to make sure atoms are preexisting
  def allowed_types, do: @allowed_types

  @doc false
  # Just used to make sure atoms are preexisting
  def allowed_difficulties, do: @allowed_difficulties
end
