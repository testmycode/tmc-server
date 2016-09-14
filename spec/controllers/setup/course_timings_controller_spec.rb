require 'spec_helper'

describe Setup::CourseTimingsController, type: :controller do

  before :each do
    @organization = FactoryGirl.create(:accepted_organization)
    @teacher = FactoryGirl.create(:user)
    @user = FactoryGirl.create(:user)
    Teachership.create!(user: @teacher, organization: @organization)
    @course = FactoryGirl.create(:course, organization: @organization)
  end

  describe 'As organization teacher' do
    before :each do
      controller.current_user = @teacher
    end

    describe 'GET show' do
      it 'show the right course' do
        get :show, {organization_id: @organization.slug, course_id: @course.id}
        expect(assigns(:organization)).to eq(@organization)
      end

      it 'should show wizard bar correctly' do
        init_session
        get :show, {organization_id: @organization.slug, course_id: @course.id}
        expect(assigns(:course_setup_phases)).not_to be_nil
      end

      it 'should not show wizard bar when not in wizard mode' do
        get :show, {organization_id: @organization.slug, course_id: @course.id}
        expect(assigns(:course_setup_phases)).to be_nil
      end
    end

    describe 'PUT update' do
      before :each do
        @course.exercises.create(name: 'group1-e1')
        @course.exercises.create(name: 'group2-e1')
        @course.exercises.create(name: 'group3-e1')
      end

      it 'clear all unlocks' do
        @course.exercise_group_by_name('group2').group_unlock_conditions = ['80% from group1'].to_json
        @course.exercise_group_by_name('group3').group_unlock_conditions = ['80% from group2'].to_json
        put :update, {
            organization_id: @organization.slug,
            course_id: @course.id,
            commit: 'Fill and preview',
            unlock_type: 'no_unlocks'
        }
        expect(assigns(:course).exercise_group_by_name('group1').group_unlock_conditions).to eq([''])
        expect(assigns(:course).exercise_group_by_name('group2').group_unlock_conditions).to eq([''])
        expect(assigns(:course).exercise_group_by_name('group3').group_unlock_conditions).to eq([''])
      end

      it 'sets unlock percentages' do
        put :update, {
            organization_id: @organization.slug,
            course_id: @course.id,
            commit: 'Fill and preview',
            unlock_type: 'percent_from_previous',
            unlock_percentage: '73'
        }
        expect(assigns(:course).exercise_group_by_name('group1').group_unlock_conditions).to eq([])
        expect(assigns(:course).exercise_group_by_name('group2').group_unlock_conditions).to eq(['73% from group1'])
        expect(assigns(:course).exercise_group_by_name('group3').group_unlock_conditions).to eq(['73% from group2'])
      end

      it 'clears all deadlines' do
        @course.exercise_group_by_name('group1').hard_group_deadline = ['1.1.2020', ''].to_json
        @course.exercise_group_by_name('group2').hard_group_deadline = ['1.1.2020', ''].to_json
        @course.exercise_group_by_name('group3').hard_group_deadline = ['1.1.2020', ''].to_json
        put :update, {
            organization_id: @organization.slug,
            course_id: @course.id,
            commit: 'Fill and preview',
            deadline_type: 'no_deadlines'
        }
        expect(assigns(:course).exercise_group_by_name('group1').hard_group_deadline.static_deadline_spec).to eq(nil)
        expect(assigns(:course).exercise_group_by_name('group2').hard_group_deadline.static_deadline_spec).to eq(nil)
        expect(assigns(:course).exercise_group_by_name('group3').hard_group_deadline.static_deadline_spec).to eq(nil)
      end

      it 'sets weekly deadlines' do
        put :update, {
            organization_id: @organization.slug,
            course_id: @course.id,
            commit: 'Fill and preview',
            deadline_type: 'weekly_deadlines',
            first_set_date: ['2021-01-01']
        }
        expect(assigns(:course).exercise_group_by_name('group1').hard_group_deadline.static_deadline_spec).to eq('2021-01-01')
        expect(assigns(:course).exercise_group_by_name('group2').hard_group_deadline.static_deadline_spec).to eq('2021-01-08')
        expect(assigns(:course).exercise_group_by_name('group3').hard_group_deadline.static_deadline_spec).to eq('2021-01-15')

      end

      it 'sets same deadlines' do
        put :update, {
            organization_id: @organization.slug,
            course_id: @course.id,
            commit: 'Fill and preview',
            deadline_type: 'all_same_deadline',
            first_set_date: ['2021-01-01']
        }
        expect(assigns(:course).exercise_group_by_name('group1').hard_group_deadline.static_deadline_spec).to eq('2021-01-01')
        expect(assigns(:course).exercise_group_by_name('group2').hard_group_deadline.static_deadline_spec).to eq('2021-01-01')
        expect(assigns(:course).exercise_group_by_name('group3').hard_group_deadline.static_deadline_spec).to eq('2021-01-01')
      end

      it 'saves manual deadlines' do
        put :update, {
            organization_id: @organization.slug,
            course_id: @course.id,
            commit: 'Accept and continue',
            group: {
                group1: {'_unlock_option'=>'no_unlock', 'hard'=>{'static'=>'2016-06-16'}},
                group2: {'_unlock_option'=>'no_unlock', 'hard'=>{'static'=>'2016-07-16'}},
                group3: {'_unlock_option'=>'no_unlock', 'hard'=>{'static'=>'2016-08-16'}}
            }
        }
        expect(assigns(:course).exercise_group_by_name('group1').hard_group_deadline.static_deadline_spec).to eq('2016-06-16')
        expect(assigns(:course).exercise_group_by_name('group2').hard_group_deadline.static_deadline_spec).to eq('2016-07-16')
        expect(assigns(:course).exercise_group_by_name('group3').hard_group_deadline.static_deadline_spec).to eq('2016-08-16')
      end

      it 'saves manual unlocks' do
        put :update, {
            organization_id: @organization.slug,
            course_id: @course.id,
            commit: 'Accept and continue',
            group: {
                group1: {'_unlock_option'=>'no_unlock', 'hard'=>{'static'=>''}},
                group2: {'_unlock_option'=>'percentage_from', '_percentage_required'=>'92', '_unlock_groupname'=>'group1', 'hard'=>{'static'=>''}},
                group3: {'_unlock_option'=>'percentage_from', '_percentage_required'=>'94', '_unlock_groupname'=>'group2', 'hard'=>{'static'=>''}}
            }
        }
        expect(assigns(:course).exercise_group_by_name('group1').group_unlock_conditions).to eq([''])
        expect(assigns(:course).exercise_group_by_name('group2').group_unlock_conditions).to eq(['92% from group1'])
        expect(assigns(:course).exercise_group_by_name('group3').group_unlock_conditions).to eq(['94% from group2'])
      end

      it 'should redirect to next step if in wizard mode' do
        init_session
        put :update, {
            organization_id: @organization.slug,
            course_id: @course.id,
            commit: 'Accept and continue',
            group: {
                group1: {'_unlock_option'=>'no_unlock', 'hard'=>{'static'=>''}},
                group2: {'_unlock_option'=>'percentage_from', '_percentage_required'=>'92', '_unlock_groupname'=>'group1', 'hard'=>{'static'=>''}},
                group3: {'_unlock_option'=>'percentage_from', '_percentage_required'=>'94', '_unlock_groupname'=>'group2', 'hard'=>{'static'=>''}}
            }
        }
        expect(response).to redirect_to(setup_organization_course_course_assistants_path(@organization, @course))
      end

      it 'should not redirect to next step if not in wizard mode' do
        put :update, {
            organization_id: @organization.slug,
            course_id: @course.id,
            commit: 'Accept and continue',
            group: {
                group1: {'_unlock_option'=>'no_unlock', 'hard'=>{'static'=>''}},
                group2: {'_unlock_option'=>'percentage_from', '_percentage_required'=>'92', '_unlock_groupname'=>'group1', 'hard'=>{'static'=>''}},
                group3: {'_unlock_option'=>'percentage_from', '_percentage_required'=>'94', '_unlock_groupname'=>'group2', 'hard'=>{'static'=>''}}
            }
        }
        expect(response).to redirect_to(organization_course_path(@organization, @course))
      end
    end
  end

  describe 'As non-teacher' do
    before :each do
      controller.current_user = @user
    end

    it 'should not allow any access' do
      get :show, {organization_id: @organization.slug, course_id: @course.id}
      expect(response.code.to_i).to eq(401)
      put :update, {organization_id: @organization.slug, course_id: @course.id, commit: 'Fill and preview', unlock_type: '1'}
      expect(response.code.to_i).to eq(401)
    end
  end

  private

  def init_session
    session[:ongoing_course_setup] = {
        course_id: @course.id,
        phase: 3,
        started: Time.now
    }
  end
end
