# File for patching DataFrame and Vector 
# to make them compatible with statsample.
module Daru
  class DataFrame
    alias :correlation_matrix :corr
    alias :fields :vectors
  end

  class Vector
    alias :flawed? :has_missing_data?
    alias :is_valid? :exists?
  end
end