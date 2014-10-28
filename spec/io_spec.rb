require 'spec_helper.rb'

describe Daru::DataFrame do
  context ".from_csv" do
    it "loads from a CSV file" do
      path = File.expand_path("spec/fixtures/matrix_test.csv", __FILE__)
      df = Daru::DataFrame.from_csv(path, col_sep: ' ', headers: true) do |csv|
        csv.convert do |field, info|
          case info[:header]
          when :true_transform
            field.split(',').map { |s| s.to_f }
          else
            field
          end
        end
      end

      expect(df.vectors).to eq([:image_resolution, :true_transform, :mls].to_index)
      expect(df.vector[:image_resolution].first).to eq(6.55779)
      expect(df.vector[:true_transform].first[15]).to eq(1.0)
    end
  end
end
