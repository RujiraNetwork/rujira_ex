defmodule Rujira.Revenue.ConverterTest do
  use Rujira.Test.CacheCase, async: false

  alias Rujira.Revenue.Converter
  alias Rujira.Revenue.Converter.Action
  alias Rujira.Revenue.Converter.TargetAddress
  alias Rujira.Revenue.Converter.TargetDenom
  alias Rujira.Test.MockNode
  alias Thorchain.Types.ContractInfo
  alias Thorchain.Types.QueryContractInfosRequest

  defp config do
    %{
      "address" => "thor1revenue",
      "owner" => "thor1owner",
      "executor" => "thor1executor",
      "target_denoms" => [["rune", "1000000"], ["x/ruji", "2000000"]],
      "target_addresses" => [["thor1a", 60], ["thor1b", 40]],
      "schedule" => 12_345,
      "last_executed" => "1700000000000000000"
    }
  end

  defp config_v1 do
    %{
      "executor" => "thor1305z",
      "owner" => "thor1lt2r",
      "target_addresses" => [["thor1lt2r", 100]],
      "target_denoms" => ["rune"],
      "address" => "thor1revenuev1"
    }
  end

  describe "new/1" do
    test "parses a v2.0.1 converter config" do
      assert {:ok,
              %Converter{
                id: "thor1revenue",
                address: "thor1revenue",
                owner: "thor1owner",
                executor: "thor1executor",
                target_denoms: [
                  %TargetDenom{max_per_second: 1_000_000},
                  %TargetDenom{max_per_second: 2_000_000}
                ],
                target_addresses: [
                  %TargetAddress{address: "thor1a", weight: 60},
                  %TargetAddress{address: "thor1b", weight: 40}
                ],
                schedule: 12_345,
                actions: :not_loaded,
                last_action: :not_loaded
              } = converter} = Converter.new(config())

      assert Enum.at(converter.target_denoms, 0).asset.id == "THOR.RUNE"
      assert Enum.at(converter.target_denoms, 1).asset.id == "THOR.RUJI"
      assert converter.last_executed == ~U[2023-11-14 22:13:20.000000000Z]
    end

    test "a null schedule is nil" do
      assert {:ok, %Converter{schedule: nil}} = Converter.new(%{config() | "schedule" => nil})
    end

    test "errors on missing fields" do
      assert {:error, :invalid_attrs} = Converter.new(%{})
    end

    test "an invalid target denom is an error" do
      assert {:error, :invalid_denom} =
               Converter.new(%{config() | "target_denoms" => [["NOPE", "1"]]})
    end

    test "an invalid target denom amount is an error" do
      assert {:error, :invalid_amount} =
               Converter.new(%{config() | "target_denoms" => [["rune", "abc"]]})
    end

    test "an invalid target address weight is an error" do
      assert {:error, :invalid_integer} =
               Converter.new(%{config() | "target_addresses" => [["thor1a", "abc"]]})
    end

    test "an invalid schedule is an error" do
      assert {:error, :invalid_integer} = Converter.new(%{config() | "schedule" => "abc"})
    end

    test "an invalid last_executed is an error" do
      assert {:error, :invalid_integer} =
               Converter.new(%{config() | "last_executed" => "abc"})
    end

    test "a nil last_executed is an error" do
      assert {:error, :invalid_integer} = Converter.new(%{config() | "last_executed" => nil})
    end

    test "a nil target address weight is an error" do
      assert {:error, :invalid_integer} =
               Converter.new(%{config() | "target_addresses" => [["thor1a", nil]]})
    end

    test "a non-binary target address is an error" do
      assert {:error, :invalid_attrs} =
               Converter.new(%{config() | "target_addresses" => [[123, 60]]})
    end

    test "parses a live v1.1.0 converter config" do
      assert {:ok,
              %Converter{
                id: "thor1revenuev1",
                address: "thor1revenuev1",
                owner: "thor1lt2r",
                executor: "thor1305z",
                target_denoms: [%TargetDenom{max_per_second: nil}],
                target_addresses: [%TargetAddress{address: "thor1lt2r", weight: 100}],
                schedule: nil,
                last_executed: nil,
                actions: :not_loaded,
                last_action: :not_loaded
              } = converter} = Converter.new(config_v1())

      assert converter.target_denoms |> Enum.at(0) |> Map.get(:asset) |> Map.get(:id) ==
               "THOR.RUNE"
    end

    test "a v1.1.0 config with an invalid target denom is an error" do
      assert {:error, :invalid_denom} =
               Converter.new(%{config_v1() | "target_denoms" => ["NOPE"]})
    end

    test "a config with only some v2 keys is invalid_attrs, not guessed as v1" do
      assert {:error, :invalid_attrs} =
               Converter.new(Map.put(config_v1(), "schedule", 12_345))

      assert {:error, :invalid_attrs} =
               Converter.new(Map.put(config_v1(), "last_executed", "1700000000000000000"))
    end
  end

  describe "get/2 and from_id/2" do
    test "round-trips on the converter's id" do
      MockNode.expect(fn %{"config" => %{}} -> MockNode.ok(config()) end)
      assert {:ok, %Converter{id: "thor1revenue"} = converter} = Converter.get("thor1revenue")

      MockNode.expect(fn %{"config" => %{}} -> MockNode.ok(config()) end)
      assert {:ok, ^converter} = Converter.from_id(converter.id)
    end

    test "a well-formed id with no contract behind it is not_found" do
      MockNode.expect(fn %{"config" => %{}} ->
        {:error, %GRPC.RPCError{status: 2, message: "codespace wasm code 22: no such contract"}}
      end)

      assert {:error, :not_found} = Converter.from_id("thor1missing")
    end
  end

  describe "list/1" do
    test "fails as a whole when any target fails" do
      MockNode.expect(fn _ -> {:error, %GRPC.RPCError{status: 2, message: "boom"}} end)

      assert {:error, _} = Converter.list()
    end

    test "resolves one v1.1.0 and one v2.x target" do
      Memoize.invalidate(Converter)

      on_exit(fn ->
        Memoize.invalidate(Converter)
      end)

      counter = :atomics.new(1, [])

      MockNode.expect(fn
        %QueryContractInfosRequest{} ->
          {:ok,
           %{
             infos: [
               %ContractInfo{address: "thor1revenuev1", contract: "rujira-revenue", version: "1"},
               %ContractInfo{address: "thor1revenue", contract: "rujira-revenue", version: "2"}
             ]
           }}

        %{"config" => %{}} ->
          case :atomics.add_get(counter, 1, 1) do
            1 -> MockNode.ok(config_v1())
            _ -> MockNode.ok(config())
          end
      end)

      assert {:ok, converters} = Converter.list()
      assert length(converters) == 2
      assert Enum.any?(converters, &(&1.schedule == nil))
      assert Enum.any?(converters, &(&1.schedule == 12_345))
    end
  end

  describe "load/2" do
    setup do
      Memoize.invalidate(Converter)
      on_exit(fn -> Memoize.invalidate(Converter) end)
      :ok
    end

    test "resolves actions and a last action from status" do
      msg = Base.encode64(~s({"swap":{}}))

      MockNode.expect(fn
        %{"actions" => %{}} ->
          MockNode.ok(%{
            "actions" => [
              %{
                "denom" => "rune",
                "contract" => "thor1fin",
                "min" => "1000",
                "max" => "2000",
                "msg" => msg
              }
            ]
          })

        %{"status" => %{}} ->
          MockNode.ok(%{"last" => "rune"})
      end)

      converter = %Converter{address: "thor1revenue"}

      assert {:ok, %Converter{actions: [%Action{} = action], last_action: last_action}} =
               Converter.load(converter)

      assert action.asset.id == "THOR.RUNE"
      assert action.contract == "thor1fin"
      assert action.min == 1000
      assert action.max == 2000
      assert action.msg == ~s({"swap":{}})
      assert last_action.id == "THOR.RUNE"
    end

    test "a null status last is a nil last_action" do
      MockNode.expect(fn
        %{"actions" => %{}} -> MockNode.ok(%{"actions" => []})
        %{"status" => %{}} -> MockNode.ok(%{"last" => nil})
      end)

      assert {:ok, %Converter{actions: [], last_action: nil}} =
               Converter.load(%Converter{address: "thor1revenue"})
    end

    test "an invalid base64 msg is an error" do
      MockNode.expect(fn
        %{"actions" => %{}} ->
          MockNode.ok(%{
            "actions" => [
              %{
                "denom" => "rune",
                "contract" => "thor1fin",
                "min" => "1000",
                "max" => "2000",
                "msg" => "not-base64!!"
              }
            ]
          })

        %{"status" => %{}} ->
          MockNode.ok(%{"last" => nil})
      end)

      assert {:error, :invalid_msg} = Converter.load(%Converter{address: "thor1revenue"})
    end

    test "propagates a query failure" do
      MockNode.expect(fn _ -> {:error, %GRPC.RPCError{status: 2, message: "boom"}} end)

      assert {:error, %GRPC.RPCError{}} = Converter.load(%Converter{address: "thor1revenue"})
    end

    test "a v1.1.0 action's limit becomes max, with min nil" do
      msg = Base.encode64(~s({"swap":{}}))

      MockNode.expect(fn
        %{"actions" => %{}} ->
          MockNode.ok(%{
            "actions" => [
              %{
                "denom" => "rune",
                "contract" => "thor1fin",
                "limit" => "2000",
                "msg" => msg
              }
            ]
          })

        %{"status" => %{}} ->
          MockNode.ok(%{"last" => nil})
      end)

      assert {:ok, %Converter{actions: [%Action{} = action]}} =
               Converter.load(%Converter{address: "thor1revenue"})

      assert action.asset.id == "THOR.RUNE"
      assert action.min == nil
      assert action.max == 2000
    end

    test "an action with neither v1 nor v2 shape is an error" do
      MockNode.expect(fn
        %{"actions" => %{}} ->
          MockNode.ok(%{
            "actions" => [
              %{"denom" => "rune", "contract" => "thor1fin", "msg" => "not-relevant"}
            ]
          })

        %{"status" => %{}} ->
          MockNode.ok(%{"last" => nil})
      end)

      assert {:error, :invalid_attrs} = Converter.load(%Converter{address: "thor1revenue"})
    end
  end
end
