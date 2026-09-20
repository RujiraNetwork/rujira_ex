defmodule Rujira.Thorchain.MimirTest do
  use ExUnit.Case, async: true

  alias Rujira.Thorchain.Mimir
  alias Thorchain.Types.Mimir, as: TcMimir

  describe "new/1" do
    test "uses the key as id" do
      assert {:ok, %Mimir{id: "MAXSYNTHPERPOOLDEPTH", key: "MAXSYNTHPERPOOLDEPTH", value: 5000}} =
               Mimir.new(%TcMimir{key: "MAXSYNTHPERPOOLDEPTH", value: 5000})
    end
  end
end
