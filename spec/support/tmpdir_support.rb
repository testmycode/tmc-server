
# We make GitBackend use a temporary directory that we can nuke before
# each test

RSpec.configure do |config|
  config.before(:each) do
    @test_tmp_dir = "#{::Rails.root}/tmp/tests"
    FileUtils.mkdir_p @test_tmp_dir
    FileUtils.cd @test_tmp_dir
    
    @testdata_dir = "#{::Rails.root}/testdata"
    
    @git_backend_root_dir = "#{::Rails.root}/tmp/tests/gitrepos"
    @git_backend_cache_dir = "#{::Rails.root}/tmp/tests/cache/gitrepos"
    FileUtils.rm_rf @git_backend_root_dir
    FileUtils.rm_rf @git_backend_cache_dir
    FileUtils.mkdir_p @git_backend_root_dir
    FileUtils.mkdir_p @git_backend_cache_dir

    GitBackend.stub!(:repositories_root).and_return(@git_backend_root_dir)
    GitBackend.stub!(:cache_root).and_return(@git_backend_cache_dir)
  end

  config.after(:each) do
    FileUtils.pwd.should == "#{::Rails.root}/tmp/tests"
    FileUtils.remove_entry_secure @test_tmp_dir
  end
end

