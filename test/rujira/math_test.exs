defmodule Rujira.MathTest do
  use ExUnit.Case, async: true

  alias Rujira.Math

  describe "to_integer/1" do
    test "passes absent values through" do
      assert {:ok, nil} = Math.to_integer(nil)
      assert {:ok, nil} = Math.to_integer("")
    end

    test "returns integers unchanged" do
      assert {:ok, 42} = Math.to_integer(42)
      assert {:ok, -7} = Math.to_integer(-7)
      assert {:ok, 0} = Math.to_integer(0)
    end

    test "parses integer strings" do
      assert {:ok, 42} = Math.to_integer("42")
      assert {:ok, -7} = Math.to_integer("-7")
    end

    test "rejects strings with trailing content" do
      assert {:error, :invalid_integer} = Math.to_integer("42abc")
      assert {:error, :invalid_integer} = Math.to_integer("1.5")
    end

    test "rejects non-numeric strings" do
      assert {:error, :invalid_integer} = Math.to_integer("abc")
    end

    test "rejects other types" do
      assert {:error, :invalid_integer} = Math.to_integer(1.5)
      assert {:error, :invalid_integer} = Math.to_integer(%{})
      assert {:error, :invalid_integer} = Math.to_integer(:atom)
    end
  end

  describe "to_decimal/1" do
    test "passes absent values through" do
      assert {:ok, nil} = Math.to_decimal(nil)
      assert {:ok, nil} = Math.to_decimal("")
    end

    test "accepts the widest value a CosmWasm Decimal can serialise" do
      # u128 mantissa, 18 decimal places — 39 significant digits, which is past
      # the 34-digit decimal128 default that Decimal 3 would otherwise enforce.
      cw_max = "340282366920938463463.374607431768211455"

      assert {:ok, decimal} = Math.to_decimal(cw_max)
      assert Decimal.to_string(decimal, :normal) == cw_max
    end

    test "accepts the widest value a CosmWasm Decimal256 can serialise" do
      cw256_max = String.duplicate("9", 78) <> "." <> String.duplicate("9", 18)

      assert {:ok, _} = Math.to_decimal(cw256_max)
    end

    test "still rejects exponent-amplification payloads (CVE-2026-32686)" do
      assert {:error, :invalid_decimal} = Math.to_decimal("1e1000000000")
      assert {:error, :invalid_decimal} = Math.to_decimal("1E999999999")
    end

    test "rejects a value wider than any chain type" do
      assert {:error, :invalid_decimal} = Math.to_decimal(String.duplicate("9", 97))
    end

    test "returns Decimals unchanged" do
      d = Decimal.new("1.5")
      assert {:ok, ^d} = Math.to_decimal(d)
    end

    test "converts integers" do
      assert {:ok, decimal} = Math.to_decimal(42)
      assert Decimal.eq?(decimal, Decimal.new(42))
    end

    test "converts floats" do
      assert {:ok, decimal} = Math.to_decimal(1.5)
      assert Decimal.eq?(decimal, Decimal.new("1.5"))
    end

    test "parses decimal strings" do
      assert {:ok, decimal} = Math.to_decimal("1.5")
      assert Decimal.eq?(decimal, Decimal.new("1.5"))
    end

    test "rejects strings with trailing content" do
      assert {:error, :invalid_decimal} = Math.to_decimal("1.5abc")
    end

    test "rejects non-numeric strings" do
      assert {:error, :invalid_decimal} = Math.to_decimal("abc")
    end

    test "rejects other types" do
      assert {:error, :invalid_decimal} = Math.to_decimal(%{})
      assert {:error, :invalid_decimal} = Math.to_decimal(:atom)
    end
  end

  describe "mul_floor/2" do
    test "multiplies and floors" do
      assert Math.mul_floor(3, 4) == 12
      assert Math.mul_floor(Decimal.new("2.5"), 3) == 7
    end

    test "floors towards negative infinity" do
      assert Math.mul_floor(Decimal.new("-2.5"), 1) == -3
    end

    test "handles zero" do
      assert Math.mul_floor(0, 100) == 0
    end
  end

  describe "mul_ceil/2" do
    test "multiplies and ceils" do
      assert Math.mul_ceil(3, 4) == 12
      assert Math.mul_ceil(Decimal.new("2.5"), 3) == 8
    end

    test "ceils towards positive infinity" do
      assert Math.mul_ceil(Decimal.new("-2.5"), 1) == -2
    end

    test "handles zero" do
      assert Math.mul_ceil(0, 100) == 0
    end
  end

  describe "div_floor/2" do
    test "divides and floors" do
      assert Math.div_floor(10, 3) == 3
      assert Math.div_floor(12, 4) == 3
    end

    test "floors towards negative infinity" do
      assert Math.div_floor(-10, 3) == -4
    end
  end

  describe "safe_div/2" do
    test "divides normally" do
      assert Decimal.eq?(Math.safe_div(10, 4), Decimal.new("2.5"))
    end

    test "returns zero instead of raising when the divisor is zero" do
      assert Decimal.eq?(Math.safe_div(10, 0), Decimal.new(0))
    end

    test "returns zero for a zero Decimal divisor" do
      assert Decimal.eq?(Math.safe_div(10, Decimal.new("0")), Decimal.new(0))
    end
  end

  describe "normalize/3" do
    test "scales up when the target precision is larger" do
      assert Decimal.eq?(Math.normalize(1, 0, 2), Decimal.new(100))
    end

    test "scales down when the target precision is smaller" do
      assert Decimal.eq?(Math.normalize(100, 2, 0), Decimal.new(1))
    end

    test "is a no-op when precisions match" do
      assert Decimal.eq?(Math.normalize(42, 6, 6), Decimal.new(42))
    end

    test "accepts floats" do
      assert Decimal.eq?(Math.normalize(1.5, 0, 2), Decimal.new(150))
    end

    test "defaults the target to the 8-decimal amount precision" do
      assert Decimal.eq?(Math.normalize(1), Decimal.new(100_000_000))
    end
  end

  describe "floor/1" do
    test "floors decimals" do
      assert Math.floor(Decimal.new("1.9")) == 1
      assert Math.floor(Decimal.new("-1.1")) == -2
    end

    test "leaves integers unchanged" do
      assert Math.floor(5) == 5
    end
  end

  describe "avg/2" do
    test "averages two numbers" do
      assert Decimal.eq?(Math.avg(2, 4), Decimal.new(3))
    end

    test "produces a fractional average" do
      assert Decimal.eq?(Math.avg(1, 2), Decimal.new("1.5"))
    end

    test "accepts Decimals" do
      assert Decimal.eq?(Math.avg(Decimal.new("1.5"), Decimal.new("2.5")), Decimal.new(2))
    end
  end
end
