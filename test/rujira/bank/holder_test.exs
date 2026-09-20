defmodule Rujira.Bank.HolderTest do
  use ExUnit.Case, async: true

  alias Rujira.Bank.Holder

  describe "new/1" do
    test "parses a denom owner" do
      assert {:ok, %Holder{address: "thor1abc", amount: 1000}} =
               Holder.new(%{address: "thor1abc", balance: %{denom: "rune", amount: "1000"}})
    end

    test "errors on a malformed owner" do
      assert {:error, :invalid_attrs} = Holder.new(%{})
    end
  end
end
