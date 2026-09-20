defmodule Rujira.StringTest do
  use ExUnit.Case, async: true

  alias Rujira.String

  test "re-exports the standard-library String API" do
    assert String.split("a/b", "/") == ["a", "b"]
    assert String.downcase("BTC") == "btc"
    assert String.replace("a-b", "-", ".", global: false) == "a.b"
  end

  describe "nil_if_empty/1" do
    test "maps empty and nil to nil, passes other values through" do
      assert String.nil_if_empty("") == nil
      assert String.nil_if_empty(nil) == nil
      assert String.nil_if_empty("thor1abc") == "thor1abc"
    end
  end
end
