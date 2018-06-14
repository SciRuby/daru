module Daru
  module Clean
    def validate_df vector, expression
      self[vector].map! {|ele| expression.call(ele)}
    end

    require 'fuzzy_match'
    def fuzzy_match vector, dict
      key = FuzzyMatch.new(dict)
      self[vector].map! {|ele| key.find(ele)}
    end

    require 'statsample'
    def impute vector, method: :regression
      vec = self[vector]
      case method
      when :regression
        x = Daru::Vector.new (0...vec.size)
        reg = Statsample::Regression::Simple.new_from_vectors(x, vec)
        vec.map! { |ele| ele.nil? ? reg.a + reg.b*x : ele }
      when :gradient_boosting
        puts 'gradient_boosting'
      when :dimension_reduction
        puts 'dimension_reduction'
      else
        puts 'invalid method'
      end
    end
  end
end
