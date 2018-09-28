# frozen_string_literal: true

require 'spec_helper'
require 'fileutils'
require 'safe_unzipper'
require 'system_commands'

describe SafeUnzipper do
  it 'removes symlinks outside of the unzipped directory' do
    Dir.mkdir('foo')
    File.open('foo/good_file', 'wb') { |f| f.write('stuff') }
    File.symlink('/etc/passwd', 'foo/bad_link')
    File.symlink('../../' + File.basename(Dir.pwd), 'foo/bad_link2')
    SystemCommands.sh!('zip', '--symlinks', '-r', 'foo.zip', 'foo')

    Dir.mkdir('out')
    SafeUnzipper.new.unzip('foo.zip', 'out')

    expect(File.exist?('out/foo/good_file')).to eq(true)
    expect(File.exist?('out/foo/bad_link')).to eq(false)
    expect(File.exist?('out/foo/bad_link2')).to eq(false)
  end

  it 'preserves symlinks inside the unzipped directory' do
    Dir.mkdir('foo')
    Dir.mkdir('foo/bar')
    File.open('foo/good_file', 'wb') { |f| f.write('stuff') }
    File.symlink('../good_file', 'foo/bar/good_link')
    SystemCommands.sh!('zip', '--symlinks', '-r', 'foo.zip', 'foo')

    Dir.mkdir('out')
    SafeUnzipper.new.unzip('foo.zip', 'out')

    expect(File.exist?('out/foo/good_file')).to eq(true)
    expect(File.exist?('out/foo/bar/good_link')).to eq(true)
    expect(File.symlink?('out/foo/bar/good_link')).to eq(true)
    expect(File.readlink('out/foo/bar/good_link')).to eq('../good_file')
  end
end
