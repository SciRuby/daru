require 'spec_helper'

describe 'Daru' do
  it 'able to set error stream' do
    Daru.error_stream = STDERR
    expect(Daru.error_stream).to eq(STDERR)
    Daru.error_stream = nil
    expect(Daru.error_stream).to eq(nil)
  end
end
