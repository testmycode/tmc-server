require 'spec_helper'

describe CourseTemplate, type: :model do
  describe 'validation' do
    let(:valid_params) do
      {
        name: 'TestTemplateCourse',
        source_url: 'http://example.com',
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
end
