defmodule Rujira.ContractsTest do
  use ExUnit.Case, async: true

  alias Cosmwasm.Wasm.V1.CodeInfoResponse
  alias Cosmwasm.Wasm.V1.QueryBuildAddressRequest
  alias Cosmwasm.Wasm.V1.QueryBuildAddressResponse
  alias Cosmwasm.Wasm.V1.QueryCodeRequest
  alias Cosmwasm.Wasm.V1.QueryCodeResponse
  alias Cosmwasm.Wasm.V1.QueryRawContractStateRequest
  alias Cosmwasm.Wasm.V1.QueryRawContractStateResponse
  alias Cosmwasm.Wasm.V1.QuerySmartContractStateRequest
  alias Rujira.Contracts
  alias Rujira.Test.MockNode

  @height 12_345
  @metadata %{"x-cosmos-block-height" => "12345"}

  defmodule Protocol do
    @moduledoc false
    defstruct address: nil, owner: nil

    @type t :: %__MODULE__{address: String.t() | nil, owner: String.t() | nil}

    @spec new(map()) :: {:ok, t()} | {:error, term()}
    def new(%{"address" => address, "owner" => owner}),
      do: {:ok, %__MODULE__{address: address, owner: owner}}

    def new(_), do: {:error, :invalid_attrs}
  end

  describe "get/2" do
    test "a height read carries the block-height metadata into the config query" do
      MockNode.expect(fn %{"config" => %{}} -> MockNode.ok(%{"owner" => "thor1owner"}) end)

      assert {:ok, %Protocol{address: "thor1contract", owner: "thor1owner"}} =
               Contracts.get({Protocol, "thor1contract"}, height: @height)

      assert_received {:mock_node, %QuerySmartContractStateRequest{address: "thor1contract"},
                       opts}

      assert Keyword.get(opts, :metadata) == @metadata
    end

    test "two height reads are never cached, so both reach the node" do
      MockNode.expect(fn %{"config" => %{}} -> MockNode.ok(%{"owner" => "thor1owner"}) end)

      assert {:ok, %Protocol{}} = Contracts.get({Protocol, "thor1contract"}, height: @height)
      assert {:ok, %Protocol{}} = Contracts.get({Protocol, "thor1contract"}, height: @height)

      assert_received {:mock_node, %QuerySmartContractStateRequest{}, _}
      assert_received {:mock_node, %QuerySmartContractStateRequest{}, _}
    end

    test "a contract struct resolves to the same height read" do
      MockNode.expect(fn %{"config" => %{}} -> MockNode.ok(%{"owner" => "thor1owner"}) end)
      {:ok, contract} = Contracts.from_id("thor1contract")

      assert {:ok, %Protocol{address: "thor1contract"}} =
               Contracts.get({Protocol, contract}, height: @height)

      assert_received {:mock_node, %QuerySmartContractStateRequest{}, opts}
      assert Keyword.get(opts, :metadata) == @metadata
    end
  end

  describe "build_address/4" do
    test "forwards the height to the code-info lookup and the address build" do
      MockNode.expect(fn
        %QueryCodeRequest{code_id: 7} ->
          {:ok, %QueryCodeResponse{code_info: %CodeInfoResponse{data_hash: <<1, 2>>}}}

        %QueryBuildAddressRequest{code_hash: "0102"} ->
          {:ok, %QueryBuildAddressResponse{address: "thor1built"}}
      end)

      assert {:ok, "thor1built"} =
               Contracts.build_address("salt", "thor1creator", 7, height: @height)

      assert_received {:mock_node, %QueryCodeRequest{}, code_opts}
      assert Keyword.get(code_opts, :metadata) == @metadata

      assert_received {:mock_node, %QueryBuildAddressRequest{}, build_opts}
      assert Keyword.get(build_opts, :metadata) == @metadata
    end
  end

  describe "version/2" do
    test "a height read carries the metadata into the raw state query" do
      MockNode.expect(fn %QueryRawContractStateRequest{address: "thor1contract"} ->
        {:ok,
         %QueryRawContractStateResponse{
           data: JSON.encode!(%{"contract" => "rujira-fin", "version" => "1.0.0"})
         }}
      end)

      assert {:ok, %{contract: "rujira-fin", version: "1.0.0"}} =
               Contracts.version("thor1contract", height: @height)

      assert_received {:mock_node, %QueryRawContractStateRequest{}, opts}
      assert Keyword.get(opts, :metadata) == @metadata
    end
  end

  describe "query_state_smart/3" do
    test "defaults to no opts and forwards a height when given" do
      MockNode.expect(fn %{"config" => %{}} -> MockNode.ok(%{"a" => 1}) end)

      assert {:ok, %{"a" => 1}} = Contracts.query_state_smart("thor1contract", %{config: %{}})
      assert_received {:mock_node, %QuerySmartContractStateRequest{}, []}

      assert {:ok, %{"a" => 1}} =
               Contracts.query_state_smart("thor1contract", %{config: %{}}, height: @height)

      assert_received {:mock_node, %QuerySmartContractStateRequest{}, opts}
      assert Keyword.get(opts, :metadata) == @metadata
    end
  end
end
