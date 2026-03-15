defprotocol BamlElixir.Encoder do
  @fallback_to_any true
  def encode(value)
end

defimpl BamlElixir.Encoder, for: [Date, Time, DateTime, NaiveDateTime] do
  def encode(value), do: to_string(value)
end

defimpl BamlElixir.Encoder, for: Any do
  def encode(value), do: value
end
