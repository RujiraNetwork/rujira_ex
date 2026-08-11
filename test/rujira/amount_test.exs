defmodule Rujira.AmountTest do
  use ExUnit.Case, async: true

  alias Rujira.Amount

  # The @moduledoc and @doc blocks in Rujira.Amount carry iex> examples that
  # nothing executed before this line existed. Running them keeps the published
  # documentation honest.
  doctest Rujira.Amount

  describe "decimals/0 and precision/0" do
    test "expose the 8-decimal convention" do
      assert Amount.decimals() == 8
      assert Amount.precision() == 100_000_000
    end

    test "precision is 10 raised to decimals" do
      assert Amount.precision() == 10 ** Amount.decimals()
    end
  end

  describe "new/1" do
    test "passes nil through" do
      assert {:ok, nil} = Amount.new(nil)
    end

    test "accepts non-negative integers" do
      assert {:ok, 0} = Amount.new(0)
      assert {:ok, 100} = Amount.new(100)
    end

    test "rejects negative integers" do
      assert {:error, :invalid_amount} = Amount.new(-1)
    end

    test "parses integer strings" do
      assert {:ok, 500} = Amount.new("500")
    end

    test "floors fractional strings rather than rounding" do
      assert {:ok, 1000} = Amount.new("1000.75")
      assert {:ok, 1000} = Amount.new("1000.99")
    end

    test "rejects negative strings" do
      assert {:error, :invalid_amount} = Amount.new("-5")
    end

    test "rejects unparseable strings" do
      assert {:error, :invalid_amount} = Amount.new("abc")
      assert {:error, :invalid_amount} = Amount.new("")
      assert {:error, :invalid_amount} = Amount.new("12abc")
    end

    test "accepts Decimals, flooring them" do
      assert {:ok, 1000} = Amount.new(Decimal.new("1000"))
      assert {:ok, 1000} = Amount.new(Decimal.new("1000.9"))
    end

    test "rejects negative Decimals" do
      assert {:error, :invalid_amount} = Amount.new(Decimal.new("-1"))
    end

    test "accepts non-negative floats, flooring them" do
      assert {:ok, 1} = Amount.new(1.9)
      assert {:ok, 0} = Amount.new(0.0)
    end

    test "rejects negative floats" do
      assert {:error, :invalid_amount} = Amount.new(-1.5)
    end

    test "rejects unsupported types" do
      assert {:error, :invalid_amount} = Amount.new(%{})
      assert {:error, :invalid_amount} = Amount.new(:atom)
      assert {:error, :invalid_amount} = Amount.new([1])
    end
  end

  describe "normalize/2" do
    test "scales 6-decimal amounts up to 8" do
      assert {:ok, 100_000_000} = Amount.normalize(1_000_000, 6)
    end

    test "scales 18-decimal amounts down to 8" do
      assert {:ok, 100_000_000} = Amount.normalize(1_000_000_000_000_000_000, 18)
    end

    test "is a no-op at 8 decimals" do
      assert {:ok, 12_345} = Amount.normalize(12_345, 8)
    end

    test "floors precision lost on the way down" do
      # 1 unit at 18 decimals is far below 1e-8, so it floors to zero.
      assert {:ok, 0} = Amount.normalize(1, 18)
    end

    test "rejects negative results" do
      assert {:error, :invalid_amount} = Amount.normalize(-1_000_000, 6)
    end

    test "rejects non-integer input" do
      assert {:error, :invalid_amount} = Amount.normalize("1000", 6)
      assert {:error, :invalid_amount} = Amount.normalize(1000, "6")
    end
  end

  describe "to_decimal/1" do
    test "converts an 8-decimal integer to its Decimal value" do
      assert Decimal.eq?(Amount.to_decimal(100_000_000), Decimal.new(1))
      assert Decimal.eq?(Amount.to_decimal(50_000), Decimal.new("0.0005"))
    end

    test "converts zero" do
      assert Decimal.eq?(Amount.to_decimal(0), Decimal.new(0))
    end
  end

  # These assert current behaviour, which is NOT the fixed-width 8-decimal output
  # the docs used to promise. Trailing zeros are stripped. Whether that is right
  # for a display helper is being decided in #12 — if it changes, these
  # assertions and the doctests in lib/rujira/amount.ex move together.
  describe "format/1" do
    test "strips trailing zeros rather than padding to 8 places" do
      assert Amount.format(100_000_000) == "1"
      assert Amount.format(50_000) == "0.0005"
    end

    test "renders zero" do
      assert Amount.format(0) == "0"
    end

    test "renders full precision when every place is significant" do
      assert Amount.format(123_456_789) == "1.23456789"
    end

    test "produces inconsistent widths for equivalent-precision amounts" do
      # Pinned deliberately: this is the behaviour under review.
      assert Amount.format(100_000_000) == "1"
      assert Amount.format(100_000_001) == "1.00000001"
    end

    test "round-trips a value parsed by new/1" do
      assert {:ok, amount} = Amount.new(100_000_000)
      assert Amount.format(amount) == "1"
    end
  end
end
