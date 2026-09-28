defmodule Rujira.Revenue do
  @moduledoc """
  Public API for the rujira-revenue protocol.

  Pure delegation facade. Each resource module owns its struct, construction,
  and queries. Invalidate cache on the resource module, not here.

  Every query takes a trailing `opts`, forwarded to `Rujira.Node.query/3`, so a
  caller can read a whole composite at one `height:` - `load_converter/2` reads
  the converter's actions and status at the same one.
  """

  alias Rujira.Revenue.Converter

  # --- Converter ---

  defdelegate get_converter(address, opts \\ []), to: Converter, as: :get
  defdelegate list_converters(opts \\ []), to: Converter, as: :list
  defdelegate load_converter(converter, opts \\ []), to: Converter, as: :load
  defdelegate converter_from_id(id, opts \\ []), to: Converter, as: :from_id
end
