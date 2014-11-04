require 'spec_helper.rb'

describe Daru::DataFrame do
  context ".from_csv" do
    it "loads from a CSV file" do
      df = Daru::DataFrame.from_csv('spec/fixtures/matrix_test.csv', 
        col_sep: ' ', headers: true) do |csv|
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

  context "JSON" do
    it "loads parsed JSON" do
      require 'json'

      json = File.read 'spec/fixtures/countries.json'
      df   = Daru::DataFrame.new JSON.parse(json)

      expect(df.vectors).to eq([
        :name, :nativeName, :tld, :cca2, :ccn3, :cca3, :currency, :callingCode, 
        :capital, :altSpellings, :relevance, :region, :subregion, :language, 
        :languageCodes, :translations, :latlng, :demonym, :borders, :area].to_index)

      expect(df.row[0][:name]).to eq("Afghanistan")
    end
  end

  context "#inspect" do
    it "prints DataFrame pretty" do

    end
  end

  context "#to_csv" do
    # TODO
  end
end