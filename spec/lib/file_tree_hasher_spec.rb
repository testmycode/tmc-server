require 'spec_helper'
require 'fileutils'

describe FileTreeHasher do
  def write_file(path, content)
    File.open(path, 'wb') {|f| f.write(content) }
  end

  it "should give the same hash for the files with the same names and content" do
    FileUtils.mkdir('subdir')
    write_file('foo', 'contents of file 1')
    write_file('subdir/foo', 'contents of file 2')
    write_file('subdir/foo2', 'contents of file 3')

    hash1 = FileTreeHasher.hash_file_tree('.')
    FileUtils.touch('foo')
    hash2 = FileTreeHasher.hash_file_tree('.')

    expect(hash1).to eq(hash2)
  end

  it "should give a different hash if a file's contents are changed" do
    write_file('foo', 'initial contents')
    hash1 = FileTreeHasher.hash_file_tree('.')
    write_file('foo', 'changed contents')
    hash2 = FileTreeHasher.hash_file_tree('.')

    expect(hash1).not_to eq(hash2)
  end

  it "should give a different hash if a file is moved" do
    write_file('one', 'first file')

    hash1 = FileTreeHasher.hash_file_tree('.')

    FileUtils.mv('one', 'two')

    hash2 = FileTreeHasher.hash_file_tree('.')

    FileUtils.mkdir('subdir')
    FileUtils.mv('two', 'subdir/one')

    hash3 = FileTreeHasher.hash_file_tree('.')

    expect(hash1).not_to eq(hash2)
    expect(hash2).not_to eq(hash3)
    expect(hash3).not_to eq(hash1)
  end

  it "should give the same hash for the same file tree in another subdirectory" do
    FileUtils.mkdir('a')
    FileUtils.mkdir('b')
    write_file('a/file', 'the contents')
    write_file('b/file', 'the contents')

    hash1 = FileTreeHasher.hash_file_tree('a')
    hash2 = FileTreeHasher.hash_file_tree('b')

    expect(hash1).to eq(hash2)
  end
end
