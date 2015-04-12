require 'spec_helper'

describe LorjCloud do
  it 'has a version number' do
    expect(LorjCloud::VERSION).not_to be nil
  end

  it 'Process module loaded in Lorj.' do
    expect(Lorj.processes.key?('cloud')).to equal(true)
  end
end
