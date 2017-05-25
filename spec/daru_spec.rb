require 'spec_helper'

describe 'Daru' do
  it 'default error stream should be $stderr' do
    expect(Daru.error_stream).to eq($stderr)
  end

  it 'should be able to set error stream to nil' do
    Daru.error_stream = nil
    expect(Daru.error_stream).to be_nil
  end
end
