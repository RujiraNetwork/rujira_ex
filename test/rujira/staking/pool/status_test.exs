defmodule Rujira.Staking.Pool.StatusTest do
  use ExUnit.Case, async: true

  alias Rujira.Staking.Pool
  alias Rujira.Staking.Pool.Status
  alias Rujira.Test.MockNode

  defp status_map do
    %{
      "account_bond" => "1000",
      "assigned_revenue" => "200",
      "liquid_bond_shares" => "500",
      "liquid_bond_size" => "550",
      "undistributed_revenue" => "50"
    }
  end

  describe "new/1" do
    test "parses the five status fields as amounts" do
      assert {:ok,
              %Status{
                account_bond: 1000,
                assigned_revenue: 200,
                liquid_bond_shares: 500,
                liquid_bond_size: 550,
                undistributed_revenue: 50
              }} = Status.new(status_map())
    end

    test "errors on missing fields" do
      assert {:error, :invalid_attrs} = Status.new(%{})
    end
  end

  describe "load/1" do
    setup do
      Memoize.invalidate(Status)
      on_exit(fn -> Memoize.invalidate(Status) end)
      :ok
    end

    test "fills the pool's status from a scripted query" do
      MockNode.expect(fn %{"status" => %{}} -> MockNode.ok(status_map()) end)

      assert {:ok, %Pool{status: %Status{account_bond: 1000}}} =
               Status.load(%Pool{address: "thor1pool"})
    end

    test "propagates a query failure" do
      MockNode.expect(fn _ -> {:error, %GRPC.RPCError{status: 2, message: "boom"}} end)

      assert {:error, %GRPC.RPCError{}} = Status.load(%Pool{address: "thor1pool"})
    end
  end
end
