require 'spec_helper'

describe CourseTemplate, type: :model do
  include GitTestActions

  describe 'validation' do
    before :each do
      @repo_path = @test_tmp_dir + '/fake_remote_repo'
      create_bare_repo(@repo_path)
    end

    let(:valid_params) do
      {
        name: 'TestTemplateCourse',
        source_url: @repo_path,
        source_backend: 'git',
        git_branch: 'master',
        title: 'Test Template Title'
      }
    end

    it 'accepts valid parameters' do
      expect do
        CourseTemplate.create!(valid_params)
      end.to_not raise_error
    end

    it 'requires a name' do
      should_be_invalid_params(valid_params.merge(name: nil))
      should_be_invalid_params(valid_params.merge(name: ''))
    end

    it 'requires name to be reasonably short' do
      should_be_invalid_params(valid_params.merge(name: 'a' * 41))
    end

    it 'requires name to be non-unique' do
      CourseTemplate.create!(valid_params)
      should_be_invalid_params(valid_params)
    end

    it 'forbids spaces in the name' do # this could eventually be lifted as long as everything else is made to tolerate spaces
      should_be_invalid_params(valid_params.merge(name: 'Test Template'))
    end

    it 'requires a title' do
      should_be_invalid_params(valid_params.merge(title: nil))
      should_be_invalid_params(valid_params.merge(title: ''))
    end

    it 'requires title to be reasonably short' do
      should_be_invalid_params(valid_params.merge(title: 'a' * 41))
    end

    it 'requires description to be reasonably short' do
      should_be_invalid_params(valid_params.merge(description: 'a' * 513))
    end

    it 'requires a remote repo url' do
      should_be_invalid_params(valid_params.merge(source_url: nil))
      should_be_invalid_params(valid_params.merge(source_url: ''))
    end

    it 'requires correct source_backend' do
      should_be_invalid_params(valid_params.merge(source_backend: 'txt'))
    end

    it 'requires correct git branch' do
      should_be_invalid_params(valid_params.merge(git_branch: 'nonexistent'))
    end

    def should_be_invalid_params(params)
      expect { CourseTemplate.create!(params) }.to raise_error
    end
  end

  it 'refreshes all it\'s courses on refresh call' do
    template = FactoryGirl.create :course_template
    template.courses << FactoryGirl.create(:course, course_template: template, source_url: template.source_url)
    template.courses << FactoryGirl.create(:course, course_template: template, source_url: template.source_url)
    template.courses << FactoryGirl.create(:course, course_template: template, source_url: template.source_url)
    expect(template.cache_version).to eq(0)
    expect(Course.all.pluck :cache_version).to eq([0, 0, 0])

    template.refresh
    expect(template.cache_version).to eq(1)
    expect(Course.all.pluck :cache_version).to eq([1, 1, 1])
  end

  it 'keeps course\'s cache_versions synchronized' do
    template = FactoryGirl.create :course_template
    template.courses << FactoryGirl.create(:course, course_template: template, source_url: template.source_url)
    template.courses << FactoryGirl.create(:course, course_template: template, source_url: template.source_url)
    expect(template.cache_version).to eq(0)
    expect(Course.all.pluck :cache_version).to eq([0, 0])
    template.refresh
    template.courses << FactoryGirl.create(:course, course_template: template, source_url: template.source_url)
    expect(template.cache_version).to eq(1)
    expect(Course.all.pluck :cache_version).to eq([1, 1, 1])
  end

  it 'keeps course\'s source url and git branch synchronized' do
    template = FactoryGirl.create :course_template
    course1 = FactoryGirl.create :course, course_template: template, source_url: template.source_url
    course2 = FactoryGirl.create :course, course_template: template, source_url: template.source_url

    new_repo_path = "#{::Rails.root}/tmp/tests/factory_repo_changed"
    create_bare_repo new_repo_path
    template.source_url = new_repo_path
    template.save!

    expect(template.source_url).to eq(new_repo_path)
    expect(course1.source_url).to eq(new_repo_path)
    expect(course2.source_url).to eq(new_repo_path)

    local_clone = clone_course_repo(course1)
    local_clone.chdir do
      system!('git checkout -b foo >/dev/null 2>&1')
    end
    local_clone.active_branch = 'foo'
    local_clone.copy_fixture_exercise('SimpleExercise', 'MyExercise')
    local_clone.add_commit_push

    template.git_branch = 'foo'
    template.save!

    expect(template.git_branch).to eq('foo')
    expect(course1.git_branch).to eq('foo')
    expect(course2.git_branch).to eq('foo')
  end
end
