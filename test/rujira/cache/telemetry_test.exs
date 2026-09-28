defmodule Rujira.Cache.TelemetryTest do
  @moduledoc """
  `[:rujira, :cache, :fetch]`: which store served a read, and how it went.

  The advance and reset events are covered in `Rujira.Cache.AdvanceTest`, where
  the block and event fixtures that trigger them already live.
  """
  use Rujira.Test.CacheCase, async: false

  import ExUnit.CaptureLog

  alias Cosmos.Bank.V1beta1.Metadata, as: DenomMetadata
  alias Cosmos.Bank.V1beta1.QueryDenomMetadataRequest
  alias Cosmos.Bank.V1beta1.QueryDenomMetadataResponse
  alias Rujira.Assets.Metadata
  alias Rujira.Cache
  alias Rujira.Test.MockNode

  @event [:rujira, :cache, :fetch]
  @key {__MODULE__, :thing, ["thor1a"]}
  @contract [{:contract, "thor1a"}]

  setup do
    attach(@event)
  end

  test "a frontier read is a miss, then a hit" do
    assert {:ok, 1} = Cache.fetch(@key, @contract, [], fn _height -> {:ok, 1} end)

    assert_receive {:telemetry, %{duration: duration},
                    %{store: :frontier, result: :miss, module: __MODULE__, function: :thing}}

    assert duration >= 0

    assert {:ok, 1} = Cache.fetch(@key, @contract, [], fn _height -> {:ok, 2} end)
    assert_receive {:telemetry, _measurements, %{store: :frontier, result: :hit}}
  end

  test "a per-block read is served by the exact store" do
    assert {:ok, 1} = Cache.fetch(@key, [:per_block], [], fn _height -> {:ok, 1} end)
    assert_receive {:telemetry, _measurements, %{store: :exact, result: :miss}}

    assert {:ok, 1} = Cache.fetch(@key, [:per_block], [], fn _height -> {:ok, 2} end)
    assert_receive {:telemetry, _measurements, %{store: :exact, result: :hit}}
  end

  test "an identity read is served by the identity store" do
    assert {:ok, 1} = Cache.fetch(@key, :identity, [], fn nil -> {:ok, 1} end)
    assert_receive {:telemetry, _measurements, %{store: :identity, result: :miss}}

    assert {:ok, 1} = Cache.fetch(@key, :identity, [], fn nil -> {:ok, 2} end)
    assert_receive {:telemetry, _measurements, %{store: :identity, result: :hit}}
  end

  test "a failed read is an error, and the next one is a miss again" do
    assert {:error, :boom} = Cache.fetch(@key, @contract, [], fn _height -> {:error, :boom} end)
    assert_receive {:telemetry, _measurements, %{store: :frontier, result: :error}}

    assert {:ok, 1} = Cache.fetch(@key, @contract, [], fn _height -> {:ok, 1} end)
    assert_receive {:telemetry, _measurements, %{store: :frontier, result: :miss}}
  end

  test "a read whose value is not stored is a bypass, not an error" do
    assert {:ok, 1} = Cache.fetch(@key, @contract, [], fn _height -> {:bypass, 1} end)
    assert_receive {:telemetry, _measurements, %{store: :frontier, result: :bypass}}

    assert {:ok, 2} = Cache.fetch(@key, @contract, [], fn _height -> {:ok, 2} end)
    assert_receive {:telemetry, _measurements, %{store: :frontier, result: :miss}}
  end

  # The absence of a denom's metadata and the metadata itself come out of one
  # node read, and only one of them belongs in the store that read it.
  test "a first read of a denom the node holds metadata for reports no error" do
    denom = "x/telemetry-metadata-test"

    MockNode.expect(fn %QueryDenomMetadataRequest{denom: ^denom} ->
      {:ok, %QueryDenomMetadataResponse{metadata: %DenomMetadata{symbol: "TELE"}}}
    end)

    assert {:ok, %Metadata{symbol: "TELE"}} = Metadata.load_metadata(denom)

    assert_receive {:telemetry, _measurements, %{store: :frontier, result: :bypass}}
    assert_receive {:telemetry, _measurements, %{store: :identity, result: :miss}}
    refute_receive {:telemetry, _measurements, %{result: :error}}
  end

  test "a read below the head is reported once, under the store that served it" do
    height = default_head() - 5

    assert {:ok, 1} = Cache.fetch(@key, @contract, [height: height], fn _h -> {:ok, 1} end)

    assert_receive {:telemetry, _measurements, %{store: :exact, result: :miss}}
    refute_receive {:telemetry, _measurements, _metadata}
  end

  test "a query key that is not an MFA carries no module or function" do
    assert {:ok, 1} = Cache.fetch("a key", @contract, [], fn _height -> {:ok, 1} end)
    assert_receive {:telemetry, _measurements, %{module: nil, function: nil}}
  end

  test "a handler that raises cannot break a read" do
    handler = {__MODULE__, :raising}

    :telemetry.attach(handler, @event, &__MODULE__.raise_it/4, nil)
    on_exit(fn -> :telemetry.detach(handler) end)

    capture_log(fn ->
      assert {:ok, 1} = Cache.fetch(@key, @contract, [], fn _height -> {:ok, 1} end)
    end)
  end

  # --- Fixtures ---

  @doc false
  def forward(_event, measurements, metadata, test),
    do: send(test, {:telemetry, measurements, metadata})

  @doc false
  def raise_it(_event, _measurements, _metadata, _config), do: raise("boom")

  # Forwards one event to the test process. The handler is a module function,
  # not a closure: `:telemetry` logs about the performance of a local one every
  # time it is attached.
  defp attach(event) do
    handler = {__MODULE__, event, System.unique_integer()}

    :telemetry.attach(handler, event, &__MODULE__.forward/4, self())
    on_exit(fn -> :telemetry.detach(handler) end)
    :ok
  end
end
