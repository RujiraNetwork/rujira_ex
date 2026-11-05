defmodule Rujira.ThorchainArbTest do
  @moduledoc """
  Reads go through `Rujira.Cache`, whose stores and head are global, so this
  case runs sync and starts from an empty cache.
  """
  use Rujira.Test.CacheCase, async: false

  alias Cosmwasm.Wasm.V1.QuerySmartContractStateRequest
  alias Rujira.Test.MockNode
  alias Rujira.ThorchainArb
  alias Rujira.ThorchainArb.Guard
  alias Thorchain.Types.ContractInfo
  alias Thorchain.Types.QueryContractInfosRequest

  @address "thor1g7cqgq389q738jrwnxhuah0u86t2pwnruvsdq70l7yt6egj6q9jq4kfeqf"

  # The VS v2 guard's config at ~28531530 (#28), keys as the contract's
  # `InstantiateMsg` on `feat/optimize`. The live denom list is long; this
  # keeps a representative slice. The live guard omits
  # `prepared_fin_checksum`, which `skip_serializing_if`s a `None`.
  defp config do
    %{
      "markets" => ["thor18wkpr24rha007awldxx5hkyxdtnw5jamnuez9e27y6qy9u0tpkrqukal6t"],
      "denoms" => [
        "btc-btc",
        "eth-eth",
        "rune",
        "tron-usdt-tr7nhqjekqxgtci8q8zy4pl8otszgjlj6t"
      ],
      "max_queue" => 32,
      "max_offer_bps" => 50,
      "reserve_fee" => "0.0003",
      "fee" => ["0.00025", "thor1gm8q2gr25nzzsxzdp2mpja4hyvyhjlr4s6krcsgv2y953uu0js3qhwpus7"],
      "chain_defaults" => %{
        "MaxSwapsPerBlock" => 100,
        "StableSlipMinBps" => 5,
        "WasmArbSlipMinBps" => -1
      }
    }
  end

  defp info(address),
    do: %ContractInfo{address: address, contract: "rujira-thorchain-arb", version: "0.1.0"}

  describe "get/2" do
    test "maps the config exactly as the contract's InstantiateMsg defines it" do
      MockNode.expect(fn %{"config" => %{}} -> MockNode.ok(config()) end)

      assert {:ok,
              %Guard{
                id: @address,
                address: @address,
                markets: ["thor18wkpr24rha007awldxx5hkyxdtnw5jamnuez9e27y6qy9u0tpkrqukal6t"],
                denoms: [
                  "btc-btc",
                  "eth-eth",
                  "rune",
                  "tron-usdt-tr7nhqjekqxgtci8q8zy4pl8otszgjlj6t"
                ],
                max_queue: 32,
                max_offer_bps: 50,
                reserve_fee: reserve_fee,
                fee: fee,
                fee_address: "thor1gm8q2gr25nzzsxzdp2mpja4hyvyhjlr4s6krcsgv2y953uu0js3qhwpus7",
                chain_defaults: %{
                  "MaxSwapsPerBlock" => 100,
                  "StableSlipMinBps" => 5,
                  "WasmArbSlipMinBps" => -1
                },
                prepared_fin_checksum: nil
              }} = ThorchainArb.get(@address)

      assert Decimal.equal?(reserve_fee, Decimal.new("0.0003"))
      assert Decimal.equal?(fee, Decimal.new("0.00025"))
    end

    test "decodes prepared_fin_checksum to bytes when the config carries one" do
      checksum = :crypto.hash(:sha256, "fin")
      config = Map.put(config(), "prepared_fin_checksum", Base.encode64(checksum))
      MockNode.expect(fn %{"config" => %{}} -> MockNode.ok(config) end)

      assert {:ok, %Guard{prepared_fin_checksum: ^checksum}} = ThorchainArb.get(@address)
    end

    test "a prepared_fin_checksum that is not base64 fails the read" do
      config = Map.put(config(), "prepared_fin_checksum", "not base64!")
      MockNode.expect(fn %{"config" => %{}} -> MockNode.ok(config) end)

      assert {:error, :invalid_checksum} = ThorchainArb.get(@address)
    end

    test "a denom rujira_ex doesn't know stays a string and doesn't fail the read" do
      config = Map.update!(config(), "denoms", &["unknown-zzz-0xdeadbeef" | &1])
      MockNode.expect(fn %{"config" => %{}} -> MockNode.ok(config) end)

      assert {:ok, %Guard{denoms: ["unknown-zzz-0xdeadbeef" | _]}} = ThorchainArb.get(@address)
    end

    test "a config missing a required key is invalid_attrs" do
      config = Map.delete(config(), "chain_defaults")
      MockNode.expect(fn %{"config" => %{}} -> MockNode.ok(config) end)

      assert {:error, :invalid_attrs} = ThorchainArb.get(@address)
    end

    test "a non-integer chain default is invalid_attrs" do
      config = put_in(config(), ["chain_defaults", "MaxSwapsPerBlock"], "100")
      MockNode.expect(fn %{"config" => %{}} -> MockNode.ok(config) end)

      assert {:error, :invalid_attrs} = ThorchainArb.get(@address)
    end
  end

  describe "from_id/2" do
    test "round-trips on the guard's id" do
      MockNode.expect(fn %{"config" => %{}} -> MockNode.ok(config()) end)
      assert {:ok, %Guard{id: @address} = guard} = ThorchainArb.get(@address)

      assert {:ok, ^guard} = ThorchainArb.from_id(guard.id)
    end

    test "a well-formed id with no contract behind it is not_found" do
      MockNode.expect(fn %{"config" => %{}} ->
        {:error, %GRPC.RPCError{status: 2, message: "codespace wasm code 22: no such contract"}}
      end)

      assert {:error, :not_found} = ThorchainArb.from_id("thor1missing")
    end
  end

  describe "list/1" do
    test "lists every deployed guard" do
      configs = %{
        "thor1guarda" => config(),
        "thor1guardb" => Map.put(config(), "prepared_fin_checksum", Base.encode64("sum"))
      }

      MockNode.expect(fn
        %QueryContractInfosRequest{} ->
          {:ok, %{infos: [info("thor1guarda"), info("thor1guardb")]}}

        %{"config" => _} ->
          receive do
            {:mock_node, %QuerySmartContractStateRequest{address: address}, _opts} ->
              MockNode.ok(Map.fetch!(configs, address))
          end
      end)

      assert {:ok,
              [
                %Guard{address: "thor1guarda", prepared_fin_checksum: nil},
                %Guard{address: "thor1guardb", prepared_fin_checksum: "sum"}
              ]} = ThorchainArb.list()
    end

    test "fails as a whole when one guard fails" do
      MockNode.expect(fn
        %QueryContractInfosRequest{} ->
          {:ok, %{infos: [info("thor1guarda"), info("thor1guardb")]}}

        %{"config" => _} ->
          receive do
            {:mock_node, %QuerySmartContractStateRequest{address: "thor1guarda"}, _opts} ->
              MockNode.ok(config())

            {:mock_node, %QuerySmartContractStateRequest{address: "thor1guardb"}, _opts} ->
              MockNode.ok(Map.delete(config(), "fee"))
          end
      end)

      assert {:error, :invalid_attrs} = ThorchainArb.list()
    end
  end
end
