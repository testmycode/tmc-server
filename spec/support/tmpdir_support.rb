
# We make Course use a temporary directory that we can nuke before
# each test

RSpec.configure do |config|
  config.before(:each) do
    @test_tmp_dir = "#{::Rails.root}/tmp/tests"
    FileUtils.mkdir_p @test_tmp_dir
    
    # Deleting the tmp dir (the cwd) as well would mess up Capybara.
    (Dir.entries(@test_tmp_dir) - ['.', '..']).each do |entry|
      FileUtils.rm_rf "#{@test_tmp_dir}/#{entry}"
    end
    
    FileUtils.cd @test_tmp_dir
    
    @testdata_dir = "#{::Rails.root}/testdata"
    
    @git_backend_cache_dir = "#{::Rails.root}/tmp/tests/cache/git_repos"
    FileUtils.rm_rf @git_backend_cache_dir
    FileUtils.mkdir_p @git_backend_cache_dir

    allow(Course).to receive(:cache_root).and_return(@git_backend_cache_dir)
  end

  config.after(:each) do
    expect(FileUtils.pwd).to eq(@test_tmp_dir)
    # We don't clean up @test_tmp_dir here because in some cases
    # Capybara may leave a file handle to a downloadable repo cache resource open.
    # On NFS, the deletion will be deferred, causing problems.
    # File handles are cleaned up soon after this block, so the cleanup can safely
    # be done in the before :each above.
  end
end
