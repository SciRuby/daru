dataframe = DataFrame.new(
  {
    Ukraine: [51_838, 49_429, 45_962],
    India: [873_785, 1_053_898, 1_182_108],
    Argentina: [32_730, 37_057, 41_223]
  },
  index: [1990, 2000, 2010],
  name: 'Populations × 1000'
)

# one row, fetching data
dataframe.rows[1990][:Ukraine]
dataframe.rows[1990].each { |idx, val| p [idx, val] }
dataframe.rows[1990].select { |idx, val| val > 50_000 }

# one row, mutating
dataframe.rows[1990][:Ukraine] += 1
dataframe.rows[1990].recode! { |_idx, val| val.to_f }
# reject!, select!, reindex! are not accessible as they will change shape/index of one DF row
# replace_values! and similar ARE accessible

# all rows mutating
dataframe.rows[1990] = row, row proxy, array
dataframe.rows[1990..2000] = (array of rows, other df, rows proxy)
dataframe.rows.select! { |idx, row| ... }
dataframe.rows[1990..2000].reject! { |idx, row| ... }
dataframe.rows.recode! { |idx, row| ... }

# reject!, select! — updates df contents by:
# 1. receive array of true/false
# 2. res.each_with_index {|i, remove| df.columns.each { delete_at(i) } if remove }
# recode! — updates df contents by df.columns.each { set_at }
