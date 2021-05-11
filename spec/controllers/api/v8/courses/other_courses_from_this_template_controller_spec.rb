# frozen_string_literal: true

require 'spec_helper'

describe Api::V8::Courses::OtherCoursesFromThisTemplateController, type: :controller do
  let!(:user) { FactoryBot.create(:user) }
  let!(:teacher) { FactoryBot.create(:user) }
  let!(:assistant) { FactoryBot.create(:user) }
  let!(:admin) { FactoryBot.create(:admin) }
  let!(:organization) { FactoryBot.create(:accepted_organization) }
  let!(:template) { FactoryBot.create(:course_template, name: 'template') }
  let!(:course) { FactoryBot.create(:course, name: "#{organization.slug}-testcourse", organization: organization, course_template_id: template.id) }
  before :each do
    allow(controller).to receive(:doorkeeper_token) { token }
    Teachership.create(user: teacher, organization: organization)
    Assistantship.create(user: assistant, course: course)
  end

  describe 'GET all courses from same template' do
    describe 'by course id as json' do
      describe 'as an admin' do
        describe 'when logged in' do
          before :each do
            controller.current_user = admin
          end

          it 'should show all courses with same template' do
            two_courses_by_template_id
          end
        end

        describe 'when using access token' do
          let!(:token) { double resource_owner_id: admin.id, acceptable?: true }

          it 'should show all courses with same template' do
            two_courses_by_template_id
          end
        end
      end

      describe 'as a teacher' do
        describe 'when logged in' do
          before :each do
            controller.current_user = teacher
          end

          it 'should show all courses with same template' do
            two_courses_by_template_id
          end
        end

        describe 'when using access token' do
          let!(:token) { double resource_owner_id: teacher.id, acceptable?: true }

          it 'should show all courses with same template' do
            two_courses_by_template_id
          end
        end
      end

      describe 'as an assistant' do
        describe 'when logged in' do
          before :each do
            controller.current_user = assistant
          end

          it 'should show all courses with same template' do
            two_courses_by_template_id
          end
        end

        describe 'when using access token' do
          let!(:token) { double resource_owner_id: assistant.id, acceptable?: true }

          it 'should show all courses with same template' do
            two_courses_by_template_id
          end
        end
      end

      describe 'as a student' do
        describe 'when logged in' do
          before :each do
            controller.current_user = user
          end

          it 'should show all courses with same template' do
            two_courses_by_template_id
          end
        end

        describe 'when using access token' do
          let!(:token) { double resource_owner_id: user.id, acceptable?: true }

          it 'should show all courses with same template' do
            two_courses_by_template_id
          end
        end
      end

      describe 'as an unauthorized user' do
        before :each do
          controller.current_user = Guest.new
        end

        it 'should not show any submissions' do
          get :index, params: { course_id: course.id }

          expect(response).to have_http_status(401)
          expect(response.body).to have_content('Authentication required')
        end
      end
    end
  end

  private
    def two_courses_by_template_id
      course1 = FactoryBot.create(:course, name: "#{organization.slug}-other-course-1", organization: organization, course_template_id: template.id)
      course2 = FactoryBot.create(:course, name: "#{organization.slug}-other-course-2", organization: organization, course_template_id: template.id)

      get :index, params: { course_id: course.id }

      r = JSON.parse response.body

      expect(r.any? { |c|  c['id'] == course1.id }).to be(true), 'course missing from list'
      expect(r.any? { |c|  c['id'] == course2.id }).to be(true), 'course missing from list'
    end
end
