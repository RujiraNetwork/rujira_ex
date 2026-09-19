defmodule Rujira.ContractsTest do
  use ExUnit.Case, async: true

  alias Rujira.Contracts

  describe "unsupported_query?/1" do
    test "a contract that predates the query variant answers with a ParseErr" do
      # What a FIN build from before dynamic ranges returns for
      # `{"ranges": {"dynamic": {...}}}`: the contract's own `StdError::ParseErr`,
      # surfaced unprefixed with the node's `: query wasm contract failed` suffix.
      error = %GRPC.RPCError{
        status: 2,
        message:
          "Error parsing into type rujira_fin::msg::QueryMsg: unknown field `dynamic`, " <>
            "expected one of `owner`, `cursor`, `limit`: query wasm contract failed"
      }

      assert Contracts.unsupported_query?(error)
    end

    test "matches an untagged-union mismatch too" do
      error = %GRPC.RPCError{
        status: 2,
        message:
          "Error parsing into type rujira_fin::msg::QueryMsg: data did not match any " <>
            "variant of untagged enum RangesQuery: query wasm contract failed"
      }

      assert Contracts.unsupported_query?(error)
    end

    test "a genuine query failure is not treated as unsupported" do
      # Every one of these is a real fault that must keep propagating, not be
      # silently turned into an empty result.
      for message <- [
            "NotFound: query wasm contract failed",
            "codespace wasm code 22: no such contract: thor1abc",
            "Generic error: Parsing u128: invalid digit found in string: query wasm contract failed",
            "Generic error: Error parsing whole: query wasm contract failed",
            "codespace wasm code 29: wasmvm error: Error calling the VM"
          ] do
        refute Contracts.unsupported_query?(%GRPC.RPCError{status: 2, message: message})
      end
    end

    test "tolerates errors that carry no message" do
      refute Contracts.unsupported_query?(:timeout)
      refute Contracts.unsupported_query?(%{})
      refute Contracts.unsupported_query?(%GRPC.RPCError{status: 2, message: nil})
    end
  end
end
