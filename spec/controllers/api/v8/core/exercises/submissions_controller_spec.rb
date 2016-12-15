require 'spec_helper'

describe Api::V8::Core::Exercises::SubmissionsController, type: :controller do

  describe 'Creating a submission' do
    describe 'as an authenticated user' do
      it 'should accept submissions when the deadline is open' do
        pending("test that submission zip is accepted before deadline")
        fail
      end

      it 'should decline submissions when the deadline is closed' do
        pending("test that submission zip is declined after deadline")
        fail
      end

      it 'should decline submissions when the file is not ZIP' do
        pending("test that submission file is declined when not zip")
        fail
      end

      it 'should decline submissions when a file is not selected' do
        pending("test that submission is declined when no file is given")
        fail
      end
    end

    describe 'as an unauthenticated user' do
      it 'should not allow sending submission' do
        pending("test that submission is declined when no file is given")
        fail
      end
    end
  end
end
