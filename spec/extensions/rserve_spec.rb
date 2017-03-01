begin
  require "rserve"
  require 'daru/extensions/rserve'

  describe "Daru rserve extension" do
    before do
      @r = Rserve::Connection.new
    end

    after do
      @r.close
    end

    describe Daru::Vector do
      context "#to_REXP" do
        it "converts to and from R data" do
          a = Daru::Vector.new(100.times.map { |i| rand > 0.9 ? nil : i + rand })
          rexp = a.to_REXP
          expect(rexp.is_a?(Rserve::REXP::Double)).to eq(true)
          expect(rexp.to_ruby).to eq(a.to_a)

          @r.assign 'a', rexp
          expect(@r.eval('a').to_ruby).to eq(a.to_a)
        end
      end
    end

    describe Daru::DataFrame do
      context "#to_REXP" do
        it "converts to and from R data" do
          a = Daru::Vector.new(100.times.map { |i| rand > 0.9 ? nil : i + rand })
          b = Daru::Vector.new(100.times.map { |i| rand > 0.9 ? nil : i + rand })
          c = Daru::Vector.new(100.times.map { |i| rand > 0.9 ? nil : i + rand })
          ds = Daru::DataFrame.new({ :a => a, :b => b, :c => c })
          rexp = ds.to_REXP
          expect(rexp.is_a? Rserve::REXP::GenericVector).to eq(true)

          ret = rexp.to_ruby
          expect(ret['a']).to eq(a.to_a)
          @r.assign 'df', rexp
          out_df = @r.eval('df').to_ruby

          expect(out_df.attributes['class']).to eq('data.frame')
          expect(out_df.attributes['names']).to eq(%w(a b c))
          expect(out_df['a']).to eq(a.to_a)
        end
      end
    end
  end
rescue LoadError => e
  puts "Requires rserve extension"
end
