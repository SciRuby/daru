module Daru
  # Defines constants and methods related to configuration
  module Configuration

    INSPECT_OPTIONS_KEYS = [
      :max_rows
    ]

    DEFAULT_MAX_ROWS = 30

    attr_accessor(*INSPECT_OPTIONS_KEYS)

    def configure
      yield self
    end

    def self.extended(base)
      base.reset_options
    end

    def reset_options
      self.max_rows = DEFAULT_MAX_ROWS
    end
  end

  extend Configuration
end
