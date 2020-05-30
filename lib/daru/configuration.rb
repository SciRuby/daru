module Daru
  # Defines constants and methods related to configuration
  module Configuration
    INSPECT_OPTIONS_KEYS = [
      :max_rows,
      # Terminal
      :spacing
    ].freeze

    # Jupyter
    DEFAULT_MAX_ROWS = 30

    # Terminal
    DEFAULT_SPACING = 10

    attr_accessor(*INSPECT_OPTIONS_KEYS)

    def configure
      yield self
    end

    def self.extended(base)
      base.reset_options
    end

    def reset_options
      self.max_rows  = DEFAULT_MAX_ROWS

      self.spacing   = DEFAULT_SPACING
    end
  end

  extend Configuration
end
