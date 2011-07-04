require 'spec_helper'

describe Exercise do

  before :each do
    @repo_dir = Dir.mktmpdir
    @cache_dir = Dir.mktmpdir

    @course = Course.new
    GitBackend.stub!(:repositories_root).and_return(@repo_dir)
    GitBackend.stub!(:cache_root).and_return(@cache_dir)
  end

  after :each do
    FileUtils.remove_entry_secure @repo_dir
    FileUtils.remove_entry_secure @cache_dir
  end
end
