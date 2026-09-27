defmodule Rujira.Brune.NodeTest do
  use ExUnit.Case, async: true

  alias Rujira.Brune.Node

  defp attrs(extra \\ %{}) do
    Map.merge(
      %{
        "addr" => "thor1node",
        "fee" => "0.1",
        "bond" => "1000000",
        "weight" => "0.5",
        "capacity" => "2000000",
        "is_leaving" => false,
        "status" => "active",
        "node" => %{}
      },
      extra
    )
  end

  describe "new/1" do
    test "parses a node with a recognised status" do
      assert {:ok, %Node{addr: "thor1node", status: :active}} = Node.new(attrs())
    end

    test "parses every recognised status" do
      for status <- ~w(whitelisted standby ready active disabled) do
        assert {:ok, %Node{status: parsed}} = Node.new(attrs(%{"status" => status}))
        assert parsed == String.to_existing_atom(status)
      end
    end

    test "errors on an unrecognised status instead of defaulting to :unknown" do
      assert {:error, :invalid_status} = Node.new(attrs(%{"status" => "bogus"}))
    end

    test "errors on missing fields" do
      assert {:error, :invalid_attrs} = Node.new(%{})
    end
  end
end
