require 'spec_helper'

describe CourseTemplate, type: :model do
  describe 'validation' do
    before :each do
      @repo_path = @test_tmp_dir + '/fake_remote_repo'
      create_bare_repo(@repo_path)
    end

    let(:valid_params) do
      {
        name: 'TestTemplateCourse',
        source_url: @repo_path,
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

    it 'requires title to be reasonably long' do
      should_be_invalid_params(valid_params.merge(title: 'aaa'))
    end

    it 'requires description to be reasonably short' do
      should_be_invalid_params(valid_params.merge(description: 'a' * 513))
    end

    it 'requires a remote repo url' do
      should_be_invalid_params(valid_params.merge(source_url: nil))
      should_be_invalid_params(valid_params.merge(source_url: ''))
    end

    def should_be_invalid_params(params)
      expect { CourseTemplate.create!(params) }.to raise_error
    end
  end

  it 'refreshes all it\'s courses on refresh call' do
    template = FactoryGirl.create :course_template
    FactoryGirl.create :course, course_template: template, source_url: template.source_url
    FactoryGirl.create :course, course_template: template, source_url: template.source_url
    FactoryGirl.create :course, course_template: template, source_url: template.source_url
    expect(template.cache_version).to eq(0)
    expect(Course.all.pluck :cache_version).to eq([0, 0, 0])
    template.refresh
    expect(template.cache_version).to eq(1)
    expect(Course.all.pluck :cache_version).to eq([1, 1, 1])
  end

  it 'keeps course\'s cache_versions synchronized' do
    template = FactoryGirl.create :course_template
    FactoryGirl.create :course, course_template: template, source_url: template.source_url
    FactoryGirl.create :course, course_template: template, source_url: template.source_url
    expect(template.cache_version).to eq(0)
    expect(Course.all.pluck :cache_version).to eq([0, 0])
    template.refresh
    FactoryGirl.create :course, course_template: template, source_url: template.source_url
    expect(template.cache_version).to eq(1)
    expect(Course.all.pluck :cache_version).to eq([1, 1, 1])
  end

  it 'removes cloned repository if no courses' do
    template = FactoryGirl.create :course_template
    course = FactoryGirl.create :course, course_template: template, source_url: template.source_url
    template.refresh
    cache_path = template.cache_path
    expect(Dir.exist? cache_path).to be(true)
    course.destroy
    expect(Dir.exist? cache_path).to be(true)
    template.destroy
    expect(Dir.exist? cache_path).to be(false)
  end

  it 'keeps course\'s source_urls synchronized'
end
