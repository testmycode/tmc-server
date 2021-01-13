# frozen_string_literal: true

require 'spec_helper'

describe User, type: :model do
  describe 'sorting' do
    it 'should sort by name' do
      a = [FactoryBot.create(:user, login: 'aa'),
           FactoryBot.create(:user, login: 'cc'),
           FactoryBot.create(:user, login: 'bb')].sort!
      expect(a.first.login).to eq('aa')
      expect(a.last.login).to eq('cc')
    end
  end

  describe 'scopes' do
    before :each do
      @user1 = FactoryBot.create(:user)
      @user2 = FactoryBot.create(:user)
      @course1 = FactoryBot.create(:course)
      @course2 = FactoryBot.create(:course)
      @ex1 = FactoryBot.create(:exercise, course: @course1,
                                           gdocs_sheet: 's1')
      @ex2 = FactoryBot.create(:exercise, course: @course2,
                                           gdocs_sheet: 's2')
      @sub1 = FactoryBot.create(:submission, user: @user1,
                                              course: @course1, exercise: @ex1)
      @sub2 = FactoryBot.create(:submission, user: @user2,
                                              course: @course2, exercise: @ex2)
      @avp1 = FactoryBot.create(:available_point, course: @course1,
                                                   exercise: @ex1, name: 'p1')
      @avp2 = FactoryBot.create(:available_point, course: @course2,
                                                   exercise: @ex2, name: 'p2')
      @awp1 = FactoryBot.create(:awarded_point, course: @course1,
                                                 submission: @sub1, user: @user1,
                                                 name: 'p1')
      @awp2 = FactoryBot.create(:awarded_point, course: @course2,
                                                 submission: @sub2, user: @user2,
                                                 name: 'p2')
    end

    it 'course_students' do
      a = User.course_students(@course1)
      expect(a.length).to eq(1)
      expect(a).to include(@user1)

      a = User.course_students(@course2)
      expect(a.length).to eq(1)
      expect(a).to include(@user2)
    end

    it 'organization_students' do
      organization1 = FactoryBot.create :accepted_organization, slug: 'slug1'
      organization2 = FactoryBot.create :accepted_organization, slug: 'slug2'
      @course1.update(organization: organization1)
      @course2.update(organization: organization2)

      a = User.organization_students(organization1)
      expect(a.length).to eq(1)
      expect(a).to include(@user1)

      a = User.organization_students(organization2)
      expect(a.length).to eq(1)
      expect(a).to include(@user2)
    end

    it 'course_sheet_students' do
      a = User.course_sheet_students(@course1, 's1')
      expect(a.length).to eq(1)
      expect(a).to include(@user1)

      a = User.course_sheet_students(@course2, 's2')
      expect(a.length).to eq(1)
      expect(a).to include(@user2)

      a = User.course_sheet_students(@course1, 'lol')
      expect(a).to be_empty

      a = User.course_sheet_students(@course2, 'wtf')
      expect(a).to be_empty
    end
  end

  describe 'validation' do
    before :each do
      @params = {
        login: 'matt',
        password: 'horner',
        email: 'matt@example.com'
      }
    end

    it 'should succeed given a valid login, password and email' do
      expect(User.new(@params).errors[:login].size).to eq(0)
    end

    it 'should fail without login' do
      @params.delete(:login)

      user = User.new(@params)
      expect(user).not_to be_valid
      expect(user.errors[:login].size).to eq(2)
    end

    it 'should fail with a duplicate login' do
      User.create!(@params)
      @params[:email] = 'another@example.com'

      user = User.new(@params)
      expect(user).not_to be_valid
      expect(user.errors[:login].size).to eq(1)
    end

    it 'should fail without email' do
      @params.delete(:email)

      user = User.new(@params)
      expect(user).not_to be_valid
      expect(user.errors[:email].size).to be > 0
    end

    it 'should fail with duplicate email' do
      User.create!(@params)
      @params[:login] = 'another'

      user = User.new(@params)
      expect(user).not_to be_valid
      expect(user.errors[:email].size).to eq(1)
    end

    it 'should fail with too short a login' do
      @params[:login] = 'a'

      user = User.new(@params)
      expect(user).not_to be_valid
      expect(user.errors[:login].size).to eq(1)
    end

    it 'should succeed without a password for new records' do
      @params.delete(:password)
      expect(User.new(@params)).to be_valid
    end

    it "should be valid after it's reloaded" do
      User.create!(@params)
      user = User.find_by!(login: @params[:login])
      expect(user.password).to be_nil
      expect(user).to be_valid
      user.save!
    end
  end

  describe 'destruction' do
    it 'should destroy its submissions' do
      sub = FactoryBot.create(:submission)
      sub.user.destroy
      expect(Submission.find_by(id: sub.id)).to be_nil
    end

    it 'should destory its points' do
      point = FactoryBot.create(:awarded_point)
      point.user.destroy
      expect(AwardedPoint.find_by(id: point.id)).to be_nil
    end

    it 'should destroy any password reset key it has' do
      user = FactoryBot.create(:user)
      key = ActionToken.create!(user: user, action: :reset_password)
      user.destroy
      expect(ActionToken.find_by(id: key.id)).to be_nil
    end

    it 'should destroy any user field values' do
      user = FactoryBot.create(:user)
      value = UserFieldValue.create!(field_name: 'foo', user: user, value: '')
      user.destroy
      expect(UserFieldValue.find_by(id: value.id)).to be_nil
    end
  end

  it 'should allow authentication after modification' do
    created_user = User.create!(login: 'root',
                                password: 'qwerty123',
                                email: 'qwerty123@example.com',
                                administrator: false)

    u = User.authenticate('root', 'qwerty123')
    expect(u).to eq(created_user)
    u.administrator = true
    u.save!

    u2 = User.authenticate('root', 'qwerty123')
    expect(u2).not_to be_nil

    created_user.destroy
  end

  it 'should not allow authentication with an empty password' do
    User.create!(login: 'user', email: 'user@example.com')
    expect { User.authenticate('user', '') }.to raise_error(Argon2::ArgonHashFail)
    # u = User.authenticate('user', '')
    # expect(u).to be_nil
  end

  it 'should hash the password on create' do
    User.create!(login: 'instructor', password: 'ilikecookies', email: 'instructor@example.com')
    user = User.find_by!(login: 'instructor')
    expect(user.password).to be_nil
    expect(user.password_hash).to be_nil
    expect(user.argon_hash).to_not be_nil
    expect(user).to have_password('ilikecookies')
    expect(user).not_to have_password('ihatecookies')
  end

  it 'should hash the password on update' do
    User.create!(login: 'instructor', password: 'ihatecookies', email: 'instructor@example.com')

    user = User.find_by!(login: 'instructor')
    user.password = 'ilikecookies'
    user.save!

    user = User.find_by!(login: 'instructor')
    expect(user.password).to be_nil
    expect(user.password_hash).to be_nil
    expect(user.argon_hash).to_not be_nil
    expect(user).to have_password('ilikecookies')
    expect(user).not_to have_password('ihatecookies')
  end

  it 'should not reset the password when saved without changing the password' do
    user = User.create!(login: 'instructor', password: 'ihatecookies', email: 'instructor@example.com')
    user.login = 'funny_person'
    user.save!

    user = User.find_by!(login: 'funny_person')
    expect(user).to have_password('ihatecookies')
  end

  it 'should allow authentication of administrators with a correct login/password' do
    user = User.create!(login: 'instructor', password: 'ilikecookies', administrator: true, email: 'instructor@example.com')
    expect(User.authenticate('instructor', 'ilikecookies')).to eq(user)
    expect(User.authenticate('instructor', 'ihatecookies')).to be_nil
    expect(User.authenticate('root', 'ilikecookies')).to be_nil
  end

  describe 'visibility' do
    before :each do
      @organization1 = FactoryBot.create :accepted_organization, slug: 'slug1'
      @organization2 = FactoryBot.create :accepted_organization, slug: 'slug2'
      @user1 = FactoryBot.create :user
      @user2 = FactoryBot.create :user
      @user3 = FactoryBot.create :user
      @course1 = FactoryBot.create :course, organization: @organization1
      @course2 = FactoryBot.create :course, organization: @organization2
      @course3 = FactoryBot.create :course, organization: @organization1
      @ex1 = FactoryBot.create :exercise, course: @course
      @ex2 = FactoryBot.create :exercise, course: @course2
      @ex3 = FactoryBot.create :exercise, course: @course3
      @sub1 = FactoryBot.create :submission, user: @user1,
                                              course: @course1, exercise: @ex1
      @sub2 = FactoryBot.create :submission, user: @user2,
                                              course: @course2, exercise: @ex2
      @sub3 = FactoryBot.create :submission, user: @user3,
                                              course: @course3, exercise: @ex3
      @avp1 = FactoryBot.create :available_point, course: @course1,
                                                   exercise: @ex1, name: 'p1'
      @avp2 = FactoryBot.create :available_point, course: @course2,
                                                   exercise: @ex2, name: 'p2'
      @avp3 = FactoryBot.create :available_point, course: @course3,
                                                   exercise: @ex3, name: 'p3'
      @awp1 = FactoryBot.create :awarded_point, course: @course1,
                                                 submission: @sub1, user: @user1,
                                                 name: 'p1'
      @awp2 = FactoryBot.create :awarded_point, course: @course2,
                                                 submission: @sub2, user: @user2,
                                                 name: 'p2'
      @awp3 = FactoryBot.create :awarded_point, course: @course3,
                                                 submission: @sub3, user: @user3, name: 'p3'
    end

    it 'should tell if student belongs to course' do
      expect(@user1.student_in_course?(@course1)).to be true
      expect(@user1.student_in_course?(@course2)).to be false
      expect(@user2.student_in_course?(@course1)).to be false
      expect(@user2.student_in_course?(@course2)).to be true
    end

    it 'should tell if student belongs to organization' do
      expect(@user1.student_in_organization?(@course1.organization)). to be true
      expect(@user1.student_in_organization?(@course2.organization)). to be false
      expect(@user2.student_in_organization?(@course1.organization)). to be false
      expect(@user2.student_in_organization?(@course2.organization)). to be true
    end

    describe 'teacher' do
      before :each do
        @teacher = FactoryBot.create :user
        Teachership.create! user: @teacher, organization: @organization1
      end

      it 'should be visible to teacher' do
        expect(@user1.visible_to_teacher?(@teacher)).to be true
        expect(@user2.visible_to_teacher?(@teacher)).to be false
      end

      it 'should show courses which teacher can teach' do
        expect(@teacher.teaching_in_courses).to match_array([@course1.id, @course3.id])
      end
    end

    describe 'assistant' do
      before :each do
        @assistant = FactoryBot.create :user
        Assistantship.create! user: @assistant, course: @course1
      end

      it 'should be visible to assistant' do
        expect(@user1.visible_to_assistant?(@assistant)).to be true
        expect(@user2.visible_to_assistant?(@assistant)).to be false
        expect(@user3.visible_to_assistant?(@assistant)).to be false
      end

      it 'should show courses which assistant can teach' do
        Assistantship.create! user: @assistant, course: @course2
        expect(@assistant.teaching_in_courses).to match_array([@course1.id, @course2.id])
      end
    end
  end
end
