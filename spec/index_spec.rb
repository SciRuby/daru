require 'spec_helper.rb'

describe Daru::Index do
  context "#initialize" do
    it "creates an Index from Array" do
      idx = Daru::Index.new ['speaker', 'mic', 'guitar', 'amp']

      expect(idx.relation_hash).to eq({speaker: 0, mic: 1, guitar: 2, amp: 3})
    end
  end
end