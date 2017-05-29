require 'spec_helper'

describe 'Daru' do
  it 'default error stream should be $stderr' do
    expect(Daru.error_stream).to eq($stderr)
  end

  it 'should be able to set error stream to nil' do
    Daru.error_stream = nil
    expect(Daru.error_stream).to be_nil
  end

  it 'should print error message if error stream set to $stderr' do
    Daru.error_stream = $stderr
    allow($stderr).to receive(:puts).and_return(true)
    Daru.error('priting error message')
    expect($stderr).to have_received(:puts)
  end

  it 'should not print error message if it is set to nil' do
    Daru.error_stream = nil
    allow($stderr).to receive(:puts).and_return(true)
    Daru.error('priting error message')
    expect($stderr).not_to have_received(:puts)
  end
end
