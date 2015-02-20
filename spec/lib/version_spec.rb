require 'spec_helper'

describe Version do
  it 'splits the version string into components' do
    expect(v('1.20.0.0303').parts).to eq([1, 20, 0, 303])
  end

  it 'can be compared with other versions' do
    expect(v('0')).to eq(v('0'))
    expect(v('1')).to eq(v('1'))
    expect(v('0')).to be < v('1')
    expect(v('1')).to be > v('0')

    expect(v('0.1')).to be < v('0.2')
    expect(v('0.2')).to be > v('0.1')
    expect(v('0.2.9')).to be > v('0.1.9')
    expect(v('0.2.9')).to be < v('0.3.9')

    expect(v('0.2.9')).to be < v('0.2.10')
    expect(v('0.2.10')).to be > v('0.2.9')

    expect(v('0.2.09')).to eq(v('0.2.09'))

    expect(v('1.2.09')).to be > v('0.2.09')
    expect(v('0.2.09')).to be < v('1.2.09')

    expect(v('0.2')).to be < v('0.2.1')
    expect(v('0.2.1')).to be > v('0.2')
    expect(v('0.2')).to eq(v('0.2.0'))
    expect(v('0.2.0')).to eq(v('0.2'))
  end

  def v(s)
    Version.new(s)
  end
end
