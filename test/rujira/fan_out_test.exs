defmodule Rujira.FanOutTest do
  @moduledoc """
  One policy governs every concurrent fan-out in the library, and the consumer
  parametrises it through the same query `opts` it already threads down.

  `Rujira.Enum.reduce_async_while_ok/4` owns it: it resolves `:timeout` and
  `:max_concurrency` per key from `opts[:fan_out]`, then app env, then the
  defaults, validates them before running anything, and names the calling
  module in a timeout. `opts` is never altered, so a nested read - and a nested
  fan-out - is governed by the same `:fan_out`, while `Rujira.Node.query/3`
  drops the key before the node implementation sees it.
  """
  use Rujira.Test.CacheCase, async: false

  alias Cosmos.Bank.V1beta1.QueryDenomMetadataRequest
  alias Rujira.Ghost
  alias Rujira.Test.MockNode
  alias Thorchain.Types.ContractInfo
  alias Thorchain.Types.QueryContractInfosRequest

  @height 500
  # Long enough that a 1ms or 50ms per-item timeout is decided by the policy
  # rather than by scheduling noise.
  @slow 500

  setup do
    original = Application.get_env(:rujira_ex, :fan_out)

    on_exit(fn ->
      if original do
        Application.put_env(:rujira_ex, :fan_out, original)
      else
        Application.delete_env(:rujira_ex, :fan_out)
      end

      Memoize.invalidate()
    end)

    Application.delete_env(:rujira_ex, :fan_out)
    Memoize.invalidate()
    :ok
  end

  describe "timeout precedence" do
    test "the default is generous enough for a slow item" do
      assert {:ok, [:done]} = run([1], fn _ -> sleep_then_done(@slow) end, [])
    end

    test "app env applies when the call names no timeout" do
      Application.put_env(:rujira_ex, :fan_out, timeout: 1)

      assert {:error, {:timeout, __MODULE__}} = run([1], fn _ -> sleep_then_done(@slow) end, [])
    end

    test "a per-call timeout overrides the configured one" do
      Application.put_env(:rujira_ex, :fan_out, timeout: 1)

      assert {:ok, [:done]} =
               run([1], fn _ -> sleep_then_done(@slow) end, fan_out: [timeout: 5_000])
    end

    test "a per-call timeout leaves the configured max_concurrency in place" do
      Application.put_env(:rujira_ex, :fan_out, timeout: 1, max_concurrency: 2)

      assert peak_concurrency(1..8, fan_out: [timeout: 5_000]) == 2
    end
  end

  describe "max_concurrency precedence" do
    test "app env applies when the call names no concurrency" do
      Application.put_env(:rujira_ex, :fan_out, max_concurrency: 1)

      assert peak_concurrency(1..4, []) == 1
    end

    test "a per-call concurrency overrides the configured one" do
      Application.put_env(:rujira_ex, :fan_out, max_concurrency: 1)

      assert peak_concurrency(1..8, fan_out: [max_concurrency: 4]) == 4
    end

    test "the default runs more than one item at a time" do
      assert peak_concurrency(1..8, []) > 1
    end
  end

  describe "invalid values" do
    test "are rejected before a single item runs" do
      parent = self()

      for fan_out <- [
            [timeout: 0],
            [timeout: -1],
            [timeout: :none],
            [timeout: nil],
            [max_concurrency: 0],
            [max_concurrency: 1.5],
            %{timeout: 1_000},
            5
          ] do
        assert {:error, :invalid_fan_out} =
                 run([1], fn _ -> send(parent, {:ran, fan_out}) end, fan_out: fan_out)

        refute_received {:ran, ^fan_out}
      end
    end

    test "are rejected when they come from app env" do
      Application.put_env(:rujira_ex, :fan_out, max_concurrency: 0)

      assert {:error, :invalid_fan_out} = run([1], fn _ -> :done end, [])
    end

    test "an unknown key is rejected, from a per-call opts or app env, before a single item runs" do
      parent = self()

      assert {:error, :invalid_fan_out} =
               run([1], fn _ -> send(parent, :ran) end, fan_out: [timout: 1])

      refute_received :ran

      Application.put_env(:rujira_ex, :fan_out, timout: 1)

      assert {:error, :invalid_fan_out} = run([1], fn _ -> send(parent, :ran) end, [])

      refute_received :ran
    end
  end

  describe "opts threading" do
    test "the function receives the caller's opts unchanged" do
      opts = [height: @height, fan_out: [timeout: 5_000], foo: :bar]

      assert {:ok, [^opts]} = run([1], fn _ -> {:ok, opts} end, opts)
    end

    test "a nested fan-out is governed by the same per-call policy" do
      opts = [fan_out: [timeout: 1]]

      assert {:error, {:timeout, __MODULE__}} =
               run([1], fn _ -> run([1, 2], fn _ -> sleep_then_done(@slow) end, opts) end, opts)
    end
  end

  describe "a real facade - Ghost.list_vaults/1" do
    test "a slow vault under a small per-call timeout is a labelled timeout" do
      expect_vaults(@slow)

      assert {:error, {:timeout, Ghost.Vault}} =
               Ghost.list_vaults(height: @height, fan_out: [timeout: 50])
    end

    test "the same read succeeds under a larger one" do
      expect_vaults(100)

      assert {:ok, [_, _]} = Ghost.list_vaults(height: @height, fan_out: [timeout: 5_000])
    end

    test "never passes :fan_out to the node implementation, on the list call or a fan-out leg" do
      parent = self()

      # `MockNode.query/3` sends `{:mock_node, request, opts}` to `self()` right
      # before invoking the script. The list call runs on the test process, so
      # `assert_received` sees it directly; a vault leg runs on its own Task,
      # so its script drains that same message from its own mailbox and
      # forwards it to `parent` instead.
      MockNode.expect(fn
        %QueryContractInfosRequest{} ->
          {:ok, %{infos: [vault_info("thor1vaulta"), vault_info("thor1vaultb")]}}

        %QueryDenomMetadataRequest{denom: denom} ->
          no_denom_metadata(denom)

        %{"config" => _} ->
          # The mailbox message carries the raw `QuerySmartContractStateRequest`,
          # not this decoded map, so it can't be matched by pinning `req`.
          receive do
            {:mock_node, _request, opts} -> send(parent, {:leg_opts, opts})
          end

          MockNode.ok(vault_config())
      end)

      assert {:ok, [_, _]} = Ghost.list_vaults(height: @height, fan_out: [timeout: 5_000])

      assert_received {:mock_node, %QueryContractInfosRequest{}, list_opts}
      refute Keyword.has_key?(list_opts, :fan_out)
      assert Keyword.get(list_opts, :return_headers)

      assert_received {:leg_opts, leg_opts}
      refute Keyword.has_key?(leg_opts, :fan_out)
      assert Keyword.get(leg_opts, :return_headers)
    end
  end

  # --- Helpers ---

  defp run(enum, fun, opts), do: Rujira.Enum.reduce_async_while_ok(enum, fun, opts, __MODULE__)

  defp sleep_then_done(ms) do
    Process.sleep(ms)
    :done
  end

  # Counts how many items are inside `fun` at once, so the resolved
  # `max_concurrency` is observed rather than assumed.
  defp peak_concurrency(enum, opts) do
    {:ok, agent} = Agent.start_link(fn -> {0, 0} end)

    result =
      run(
        enum,
        fn _ ->
          Agent.update(agent, fn {live, peak} -> {live + 1, max(peak, live + 1)} end)
          Process.sleep(50)
          Agent.update(agent, fn {live, peak} -> {live - 1, peak} end)
        end,
        opts
      )

    assert {:ok, _} = result
    {_live, peak} = Agent.get(agent, & &1)
    Agent.stop(agent)
    peak
  end

  defp expect_vaults(delay) do
    MockNode.expect(fn
      %QueryContractInfosRequest{} ->
        {:ok, %{infos: [vault_info("thor1vaulta"), vault_info("thor1vaultb")]}}

      %QueryDenomMetadataRequest{denom: denom} ->
        no_denom_metadata(denom)

      %{"config" => _} ->
        Process.sleep(delay)
        MockNode.ok(vault_config())
    end)
  end

  defp vault_info(address),
    do: %ContractInfo{address: address, contract: "rujira-ghost-vault", version: "1"}

  defp vault_config do
    %{
      "denom" => "rune",
      "fee" => "0.1",
      "fee_address" => "thor1fee",
      "interest" => %{
        "target_utilization" => "0.8",
        "base_rate" => "0",
        "step1" => "1",
        "step2" => "2"
      }
    }
  end

  # A token-factory denom's asset comes from the chain's metadata for it. These
  # fixtures are denoms the node holds none for, which is what names them here.
  defp no_denom_metadata(denom),
    do: {:error, %GRPC.RPCError{status: 5, message: "client metadata for denom #{denom}"}}
end
