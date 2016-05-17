require_relative '_base'

n = 40_000
keys = (1..(n)).to_a
base_data = { idx: 1.upto(n).to_a, keys: 1.upto(n).map { |v| keys[Random.rand(n)]}}
lookup_hash = keys.map { |k| [k, k * 100]}.to_h

base_data_df = Daru::DataFrame.new(base_data)
lookup_df = Daru::DataFrame.new(keys: lookup_hash.keys, values: lookup_hash.values)

__profile__ do
  base_data_df.join(lookup_df, on: [:keys], how: :inner)
end
