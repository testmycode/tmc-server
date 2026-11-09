# typed: false
# frozen_string_literal: true

require 'spec_helper'
require 'fileutils'
require 'safe_unzipper'
require 'system_commands'

describe SafeUnzipper do
  def zip_and_unzip
    SystemCommands.sh!('zip', '--symlinks', '-r', 'foo.zip', 'foo')
    Dir.mkdir('out')
    SafeUnzipper.new.unzip('foo.zip', 'out')
  end

  before do
    Dir.mkdir('foo')
    Dir.mkdir('foo/bar')
    File.write('foo/good_file', 'stuff')
    File.write('foo/bar/nested_file', 'more stuff')
  end

  it 'unzips regular files and directories' do
    zip_and_unzip

    expect(File.read('out/foo/good_file')).to eq('stuff')
    expect(File.read('out/foo/bar/nested_file')).to eq('more stuff')
  end

  it 'removes symlinks outside of the unzipped directory' do
    File.symlink('/etc/passwd', 'foo/bad_link')
    File.symlink('../../' + File.basename(Dir.pwd), 'foo/bad_link2')
    zip_and_unzip

    expect(File.exist?('out/foo/good_file')).to be(true)
    expect(File.symlink?('out/foo/bad_link')).to be(false)
    expect(File.symlink?('out/foo/bad_link2')).to be(false)
  end

  it 'removes chained symlinks that only look internal' do
    depth = Dir.pwd.count('/') + 5
    File.symlink('.', 'foo/s')
    File.symlink(('s/' * depth) + ('../' * depth) + 'etc/hostname', 'foo/A.txt')
    zip_and_unzip

    leftover_links = Dir.glob('out/**/*', File::FNM_DOTMATCH).select { |path| File.symlink?(path) }
    expect(leftover_links).to be_empty
    expect(File.read('out/foo/good_file')).to eq('stuff')
  end

  it 'refuses an archive that extracts to more than the size limit' do
    stub_const('SafeUnzipper::MAX_UNCOMPRESSED_BYTES', 1000)
    File.write('foo/big_file', '0' * 1001)
    SystemCommands.sh!('zip', '-r', 'foo.zip', 'foo')
    Dir.mkdir('out')

    expect { SafeUnzipper.new.unzip('foo.zip', 'out') }.to raise_error(SafeUnzipper::ArchiveTooLargeError)
    expect(Dir.empty?('out')).to be(true)
  end

  it 'refuses an archive with more entries than the limit' do
    stub_const('SafeUnzipper::MAX_ENTRIES', 3)
    SystemCommands.sh!('zip', '-r', 'foo.zip', 'foo')
    Dir.mkdir('out')

    expect { SafeUnzipper.new.unzip('foo.zip', 'out') }.to raise_error(SafeUnzipper::ArchiveTooLargeError)
    expect(Dir.empty?('out')).to be(true)
  end

  it 'removes symlinks inside the unzipped directory' do
    File.symlink('../good_file', 'foo/bar/good_link')
    zip_and_unzip

    expect(File.exist?('out/foo/good_file')).to be(true)
    expect(File.symlink?('out/foo/bar/good_link')).to be(false)
  end
end
