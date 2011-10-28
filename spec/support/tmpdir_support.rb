
# We make Course use a temporary directory that we can nuke before
# each test

RSpec.configure do |config|
  config.before(:each) do
    @test_tmp_dir = "#{::Rails.root}/tmp/tests"
    FileUtils.rm_rf @test_tmp_dir
    FileUtils.mkdir_p @test_tmp_dir
    FileUtils.cd @test_tmp_dir
    
    @testdata_dir = "#{::Rails.root}/testdata"
    
    @git_backend_cache_dir = "#{::Rails.root}/tmp/tests/cache/git_repos"
    FileUtils.rm_rf @git_backend_cache_dir
    FileUtils.mkdir_p @git_backend_cache_dir

    Course.stub!(:cache_root).and_return(@git_backend_cache_dir)
  end

  config.after(:each) do
    FileUtils.pwd.should == @test_tmp_dir
    # We don't clean up @test_tmp_dir here because in some cases
    # Capybara may leave a file handle to a downloadable repo cache resource open.
    # When on NFS, the deletion will be deferred, causing problems.
    # File handles are cleaned up soon after this block, so the cleanup can safely
    # be done in the before :each above.
  end
end

