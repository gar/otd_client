defmodule OTDBClient.QuestionTest do
  use ExUnit.Case

  alias OTDBClient.Question

  setup do
    %{
      qmap: %{
        "type" => "multiple",
        "difficulty" => "easy",
        "category" => "Life, the Universe, and Everything",
        "question" =>
          "What is the answer to the Ultimate Question of Life, the Universe, and Everything?",
        "correct_answer" => "42",
        "incorrect_answers" => ["17", "43", "99"]
      }
    }
  end

  describe "new/1" do
    test "converts question type and difficulty into atoms", %{qmap: qmap} do
      qmap = %{qmap | "type" => "multiple", "difficulty" => "hard"}

      assert {:ok, %Question{type: :multiple, difficulty: :hard}} = Question.new(qmap)
    end

    test "HTML decodes any strings in category, question, or answers", %{qmap: qmap} do
      qmap = %{
        qmap
        | "category" => "Maths &amp; Food",
          "question" => "What is &pi;?",
          "correct_answer" => "&gt; 3 &amp; &lt; 4",
          "incorrect_answers" => ["exactly 3", "&gt; 4", "delicious"]
      }

      {:ok, question} = Question.new(qmap)

      assert question.category == "Maths & Food"
      assert question.question == "What is π?"
      assert question.correct_answer == "> 3 & < 4"
      assert Enum.sort(question.incorrect_answers) == Enum.sort(["exactly 3", "> 4", "delicious"])
    end

    test "returns error-tuple if type unknown", %{qmap: qmap} do
      qmap = %{qmap | "type" => "best-guess"}

      assert {:error, {:not_existing_atom, ~s["best-guess"]}} == Question.new(qmap)
    end

    test "returns error-tuple if difficulty unknown", %{qmap: qmap} do
      qmap = %{qmap | "type" => "easy-peasy"}

      assert {:error, {:not_existing_atom, ~s["easy-peasy"]}} == Question.new(qmap)
    end

    test "returns error-tuple if could not HTML decode category", %{qmap: qmap} do
      qmap = %{qmap | "category" => nil}

      assert {:error, {:html_decode_error, "nil"}} == Question.new(qmap)
    end

    test "returns error-tuple if could not HTML decode question", %{qmap: qmap} do
      qmap = %{qmap | "question" => nil}

      assert {:error, {:html_decode_error, "nil"}} == Question.new(qmap)
    end

    test "returns error-tuple if could not HTML decode correct answer", %{qmap: qmap} do
      qmap = %{qmap | "correct_answer" => 42}

      assert {:error, {:html_decode_error, "42"}} == Question.new(qmap)
    end

    test "returns error-tuple if could not HTML decode incorrect_answers", %{qmap: qmap} do
      qmap = %{qmap | "incorrect_answers" => [:not_a_binary]}

      assert {:error, {:html_decode_error, ":not_a_binary"}} == Question.new(qmap)
    end
  end
end
