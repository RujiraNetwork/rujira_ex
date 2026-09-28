defmodule Rujira.Ghost.Credit.AccountTest do
  @moduledoc """
  Every query here reads through `Rujira.Cache`, whose stores and head are
  global, so this case runs sync and starts from an empty cache.
  """
  use Rujira.Test.CacheCase, async: false

  alias Rujira.Ghost.Credit.Account
  alias Rujira.Ghost.Credit.Collateral
  alias Rujira.Ghost.Credit.Debt
  alias Rujira.Ghost.Credit.LiquidateMsg
  alias Rujira.Ghost.Credit.LiquidationPreferences
  alias Rujira.Ghost.Credit.LiquidationPreferences.Order
  alias Rujira.Ghost.Vault.Delegate
  alias Rujira.Test.MockNode

  @height 12_345
  @not_found %GRPC.RPCError{
    status: 2,
    message:
      "type: rujira_ghost_credit::account::Stored; key: [61, 74] not found: " <>
        "query wasm contract failed"
  }

  describe "new/2" do
    test "parses an account response, including its liquidation preferences" do
      assert {:ok,
              %Account{
                id: "thor1credit/thor1account",
                credit: "thor1credit",
                owner: "thor1owner",
                account: "thor1account",
                tag: "main",
                collaterals: [%Collateral{coin: coin} = collateral],
                debts: [%Debt{delegate: %Delegate{address: "thor1account"} = delegate} = debt],
                liquidation_preferences: %LiquidationPreferences{
                  messages: [
                    %LiquidateMsg.Repay{asset: repay_asset},
                    %LiquidateMsg.Execute{contract: "thor1fin", msg: msg, funds: [funds]}
                  ],
                  order: %Order{entries: [entry], limit: 100}
                }
              } = account} = Account.new("thor1credit", response())

      assert coin.asset.id == "BTC-BTC"
      assert coin.amount == 100
      assert Decimal.equal?(collateral.value_full, Decimal.new("10"))
      assert Decimal.equal?(collateral.value_adjusted, Decimal.new("8"))
      assert delegate.current == 50
      assert delegate.borrower.asset.id == "THOR.RUNE"
      assert Decimal.equal?(debt.value, Decimal.new("5"))
      assert Decimal.equal?(account.ltv, Decimal.new("0.5"))
      assert repay_asset.id == "THOR.RUNE"
      assert msg == ~s({"swap":{}})
      assert funds.asset.id == "BTC-BTC"
      assert entry.asset.id == "BTC-BTC"
      assert entry.after.id == "ETH-ETH"
    end

    test "an account created without a tag has none" do
      assert {:ok, %Account{tag: nil}} = Account.new("thor1credit", response(%{"tag" => ""}))
    end

    test "errors on missing fields" do
      assert {:error, :invalid_attrs} = Account.new("thor1credit", %{})
    end

    test "collaterals that are not a list are an error" do
      assert {:error, :invalid_attrs} =
               Account.new("thor1credit", response(%{"collaterals" => %{}}))
    end

    test "an unknown collateral variant is an error, not an empty holding" do
      collaterals = [
        %{
          "collateral" => %{"nft" => %{"id" => "1"}},
          "value_full" => "10",
          "value_adjusted" => "8"
        }
      ]

      assert {:error, :invalid_attrs} =
               Account.new("thor1credit", response(%{"collaterals" => collaterals}))
    end

    test "an unrecognised collateral denom is an error" do
      collaterals = [
        %{
          "collateral" => %{"coin" => %{"denom" => "not a denom", "amount" => "100"}},
          "value_full" => "10",
          "value_adjusted" => "8"
        }
      ]

      assert {:error, :invalid_denom} =
               Account.new("thor1credit", response(%{"collaterals" => collaterals}))
    end

    test "a malformed debt is an error" do
      assert {:error, :invalid_attrs} =
               Account.new("thor1credit", response(%{"debts" => [%{"value" => "5"}]}))
    end

    test "an unparseable ltv is an error" do
      assert {:error, :invalid_decimal} = Account.new("thor1credit", response(%{"ltv" => "half"}))
    end

    test "an unknown liquidation message variant is an error" do
      assert {:error, :invalid_attrs} =
               Account.new(
                 "thor1credit",
                 response(%{
                   "liquidation_preferences" =>
                     preferences(%{"messages" => [%{"withdraw" => %{}}]})
                 })
               )
    end

    test "a liquidation message whose msg is not base64 is an error" do
      messages = [%{"execute" => %{"contract_addr" => "thor1fin", "msg" => "!!", "funds" => []}}]

      assert {:error, :invalid_msg} =
               Account.new(
                 "thor1credit",
                 response(%{"liquidation_preferences" => preferences(%{"messages" => messages})})
               )
    end

    test "an unrecognised denom in the liquidation order is an error" do
      order = %{"map" => %{"not a denom" => "eth-eth"}, "limit" => 100}

      assert {:error, :invalid_denom} =
               Account.new(
                 "thor1credit",
                 response(%{"liquidation_preferences" => preferences(%{"order" => order})})
               )
    end

    test "missing liquidation preferences are an error, not a default" do
      assert {:error, :invalid_attrs} =
               Account.new("thor1credit", response(%{"liquidation_preferences" => %{}}))
    end
  end

  describe "get/3 and from_id/2" do
    test "reads one account and round-trips its id" do
      MockNode.expect(fn %{"account" => "thor1account"} -> MockNode.ok(response()) end)

      assert {:ok, %Account{id: "thor1credit/thor1account"} = account} =
               Account.get("thor1credit", "thor1account", height: @height)

      assert {:ok, ^account} = Account.from_id(account.id, height: @height)
    end

    test "an address the credit contract holds no account for is not_found" do
      MockNode.expect(fn %{"account" => _} -> {:error, @not_found} end)

      assert {:error, :not_found} = Account.get("thor1credit", "thor1nope", height: @height)
    end

    test "a missing account is cached, so a second read does not re-ask the node" do
      MockNode.expect(fn %{"account" => _} -> {:error, @not_found} end)

      assert {:error, :not_found} = Account.get("thor1credit", "thor1nope", height: @height)
      assert {:error, :not_found} = Account.get("thor1credit", "thor1nope", height: @height)

      assert_received {:mock_node, _, _}
      refute_received {:mock_node, _, _}
    end

    test "any other query error is handed back unchanged" do
      MockNode.expect(fn %{"account" => _} ->
        {:error, %GRPC.RPCError{status: 3, message: "boom"}}
      end)

      assert {:error, %GRPC.RPCError{status: 3}} =
               Account.get("thor1credit", "thor1account", height: @height)
    end

    test "a malformed id is invalid_id" do
      assert {:error, :invalid_id} = Account.from_id("thor1credit")
      assert {:error, :invalid_id} = Account.from_id("thor1credit/thor1account/extra")
    end

    test "a second read at the same height is served from the cache" do
      MockNode.expect(fn %{"account" => "thor1account"} -> MockNode.ok(response()) end)

      assert {:ok, %Account{}} = Account.get("thor1credit", "thor1account", height: @height)
      assert {:ok, %Account{}} = Account.get("thor1credit", "thor1account", height: @height)

      assert_received {:mock_node, _, _}
      refute_received {:mock_node, _, _}
    end
  end

  describe "list/2" do
    test "pages all_accounts from the last account of each full page" do
      page = Enum.map(1..100, &response(%{"account" => "thor1account#{&1}"}))

      MockNode.expect(fn
        %{"all_accounts" => %{"cursor" => nil, "limit" => 100}} ->
          MockNode.ok(%{"accounts" => page})

        %{"all_accounts" => %{"cursor" => "thor1account100", "limit" => 100}} ->
          MockNode.ok(%{"accounts" => [response(%{"account" => "thor1account101"})]})
      end)

      assert {:ok, accounts} = Account.list("thor1credit", height: @height)
      assert length(accounts) == 101
      assert List.last(accounts).id == "thor1credit/thor1account101"
    end

    test "a malformed account in a page fails the whole list" do
      MockNode.expect(fn %{"all_accounts" => _} ->
        MockNode.ok(%{"accounts" => [response(), %{}]})
      end)

      assert {:error, :invalid_attrs} = Account.list("thor1credit", height: @height)
    end
  end

  describe "list_by_owner/4" do
    test "filters by owner, and by tag when one is given" do
      MockNode.expect(fn
        %{"accounts" => %{"owner" => "thor1owner", "tag" => nil}} ->
          MockNode.ok(%{"accounts" => [response()]})

        %{"accounts" => %{"owner" => "thor1owner", "tag" => "main"}} ->
          MockNode.ok(%{"accounts" => [response()]})
      end)

      assert {:ok, [%Account{owner: "thor1owner"}]} =
               Account.list_by_owner("thor1credit", "thor1owner", nil, height: @height)

      assert {:ok, [%Account{tag: "main"}]} =
               Account.list_by_owner("thor1credit", "thor1owner", "main", height: @height)
    end

    test "a reply without accounts is an error, not an empty list" do
      MockNode.expect(fn %{"accounts" => _} -> MockNode.ok(%{}) end)

      assert {:error, :invalid_attrs} =
               Account.list_by_owner("thor1credit", "thor1owner", nil, height: @height)
    end
  end

  describe "predict/4" do
    test "returns the address the next account would be created at" do
      MockNode.expect(fn %{"predict" => %{"owner" => "thor1owner", "salt" => "AQID"}} ->
        MockNode.ok("thor1predicted")
      end)

      assert {:ok, "thor1predicted"} =
               Account.predict("thor1credit", "thor1owner", <<1, 2, 3>>, height: @height)
    end

    test "a reply that is not an address is an error" do
      MockNode.expect(fn %{"predict" => _} -> MockNode.ok(%{"address" => "thor1predicted"}) end)

      assert {:error, :invalid_response} =
               Account.predict("thor1credit", "thor1owner", <<1, 2, 3>>, height: @height)
    end

    test "a second read at the same height is served from the cache" do
      MockNode.expect(fn %{"predict" => _} -> MockNode.ok("thor1predicted") end)

      assert {:ok, "thor1predicted"} =
               Account.predict("thor1credit", "thor1owner", <<1, 2, 3>>, height: @height)

      assert {:ok, "thor1predicted"} =
               Account.predict("thor1credit", "thor1owner", <<1, 2, 3>>, height: @height)

      assert_received {:mock_node, _, _}
      refute_received {:mock_node, _, _}
    end
  end

  # --- Fixtures ---

  defp response(overrides \\ %{}) do
    Map.merge(
      %{
        "owner" => "thor1owner",
        "account" => "thor1account",
        "tag" => "main",
        "collaterals" => [
          %{
            "collateral" => %{"coin" => %{"denom" => "btc-btc", "amount" => "100"}},
            "value_full" => "10",
            "value_adjusted" => "8"
          }
        ],
        "debts" => [
          %{
            "debt" => %{
              "borrower" => %{
                "addr" => "thor1credit",
                "denom" => "rune",
                "limit" => "500",
                "current" => "100",
                "shares" => "100.5",
                "available" => "400"
              },
              "addr" => "thor1account",
              "current" => "50",
              "shares" => "50.5"
            },
            "value" => "5"
          }
        ],
        "ltv" => "0.5",
        "liquidation_preferences" => preferences()
      },
      overrides
    )
  end

  defp preferences(overrides \\ %{}) do
    Map.merge(
      %{
        "messages" => [
          %{"repay" => "rune"},
          %{
            "execute" => %{
              "contract_addr" => "thor1fin",
              "msg" => Base.encode64(~s({"swap":{}})),
              "funds" => [%{"denom" => "btc-btc", "amount" => "100"}]
            }
          }
        ],
        "order" => %{"map" => %{"btc-btc" => "eth-eth"}, "limit" => 100}
      },
      overrides
    )
  end
end
