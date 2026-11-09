# typed: false
# frozen_string_literal: true

require 'spec_helper'

describe BadUtf8Helper, type: :helper do
  it 'returns valid UTF-8 unchanged' do
    expect(force_utf8_violently('päivä')).to eq('päivä')
  end

  it 'reads binary strings holding UTF-8 bytes as UTF-8' do
    result = force_utf8_violently('päivä'.b)
    expect(result.encoding).to eq(Encoding::UTF_8)
    expect(result).to eq('päivä')
  end

  it 'decodes invalid UTF-8 as Latin-1' do
    result = force_utf8_violently("p\xE4iv\xE4".dup.force_encoding('UTF-8'))
    expect(result.encoding).to eq(Encoding::UTF_8)
    expect(result).to be_valid_encoding
    expect(result).to eq('päivä')
  end

  it 'decodes binary strings that are not UTF-8 as Latin-1' do
    expect(force_utf8_violently("p\xE4iv\xE4".b)).to eq('päivä')
  end
end
