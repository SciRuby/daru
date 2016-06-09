RSpec::Support.require_rspec_core 'formatters/base_text_formatter'

class SimpleFormatter < RSpec::Core::Formatters::BaseTextFormatter
  RSpec::Core::Formatters.register self,
    :example_passed, :example_pending, :example_failed, :dump_pending, :dump_failures, :dump_summary

  def example_passed(message)
    # Do nothing
  end

  def example_pending(message)
    # Do nothing
  end

  def example_failed(message)
    # Do nothing
  end

  def dump_pending(message)
    # Do nothing
  end

  def dump_failures(message)
  end

  def dump_summary(message)
    colorizer = ::RSpec::Core::Formatters::ConsoleCodes

    output.puts "\nFinished in #{message.formatted_duration} " \
       "(files took #{message.formatted_load_time} to load)\n" \
       "#{message.colorized_totals_line(colorizer)}\n"
  end
end
