describe Daru::Clean do
  before(:each) do
    @df = Daru::DataFrame.new(
      {
        a: [1,2,3,4,5],
        b: ['mal','femal','M','F','Fem'],
        c: [10,nil,30,40,nil],
        d: ['a,c','a','b','b','b,a'],
        e: [:A,:N,:B,:C,:N]
      })
  end

  context "fuzzy_match" do
    it "formats data based on similarity to a given dictionary" do
      expect(@df.fuzzy_match :b, ['MALE', 'FEMALE'])
        .to eq(Daru::DataFrame.new(
          {
            a: [3,4,5,6,7],
            b: ['MALE','FEMALE','MALE','FEMALE','FEMALE'],
            c: [10,nil,30,40,nil]
            d: ['a,c','a','b','b','b,a']
            e: [:A,:N,:B,:C,:N]
          }))
    end
  end


  context "impute" do
    it "imputes data using regression"
      expect(@df.validate_df :a)
        .to eq(Daru::DataFrame.new(
          {
            a: [3,4,5,6,7],
            b: ['MALE','FEMALE','MALE','FEMALE','FEMALE'],
            c: [10,20,30,40,50]
            d: ['a,c','a','b','b','b,a']
            e: [:A,:N,:B,:C,:N]
          }))
    end
  end

  context "split_cell" do
    it "splits multi valued cells"
      expect(@df.validate_df :d)
        .to eq(Daru::DataFrame.new(
          {
            a: [3,4,5,6,7,4,7],
            b: ['MALE','FEMALE','MALE','FEMALE','FEMALE','MALE','FEMALE'],
            c: [10,nil,30,40,nil,10,nil]
            d: ['a','a','b','b','b','c','a']
            e: [:A,:N,:B,:C,:N,:A,:N]
          }))
    end
  end

  context "depend?" do
    it "checks if one column depends on another"
      expect(@df.validate_df :a, :e ).to eq(true)
      expect(@df.validate_df :a, :b ).to eq(false)
    end
  end
end
