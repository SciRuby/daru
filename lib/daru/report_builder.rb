module Daru
  module ReportBuilder
    # Generate a summary of this object with ReportBuilder.
    def summary(method = :to_text)
      ReportBuilder.new(no_title: true).add(self).send(method)
    end
  end
end if Daru.has_reportbuilder?
