require 'spec_helper'

describe User, type: :model do
  describe 'sorting' do
    it 'should sort by name' do
      a = [FactoryGirl.create(:user, login: 'aa'),
           FactoryGirl.create(:user, login: 'cc'),
           FactoryGirl.create(:user, login: 'bb')].sort!
      expect(a.first.login).to eq('aa')
      expect(a.last.login).to eq('cc')
    end
  end

  describe 'scopes' do
    before :each do
      @user1 = FactoryGirl.create(:user)
      @user2 = FactoryGirl.create(:user)
      @course1 = FactoryGirl.create(:course)
      @course2 = FactoryGirl.create(:course)
      @ex1 = FactoryGirl.create(:exercise, course: @course1,
                                           gdocs_sheet: 's1')
      @ex2 = FactoryGirl.create(:exercise, course: @course2,
                                           gdocs_sheet: 's2')
      @sub1 = FactoryGirl.create(:submission, user: @user1,
                                              course: @course1, exercise: @ex1)
      @sub2 = FactoryGirl.create(:submission, user: @user2,
                                              course: @course2, exercise: @ex2)
      @avp1 = FactoryGirl.create(:available_point, course: @course1,
                                                   exercise: @ex1, name: 'p1')
      @avp2 = FactoryGirl.create(:available_point, course: @course2,
                                                   exercise: @ex2, name: 'p2')
      @awp1 = FactoryGirl.create(:awarded_point, course: @course1,
                                                 submission: @sub1, user: @user1,
                                                 name: 'p1')
      @awp2 = FactoryGirl.create(:awarded_point, course: @course2,
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
      expect(user.errors[:email].size).to eq(1)
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

    it 'should fail with too long a login' do
      @params[:login] = 'a' * 21

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
      user = User.find_by_login!(@params[:login])
      expect(user.password).to be_nil
      expect(user).to be_valid
      user.save!
    end
  end

  describe 'destruction' do
    it 'should destroy its submissions' do
      sub = FactoryGirl.create(:submission)
      sub.user.destroy
      expect(Submission.find_by_id(sub.id)).to be_nil
    end

    it 'should destory its points' do
      point = FactoryGirl.create(:awarded_point)
      point.user.destroy
      expect(AwardedPoint.find_by_id(point.id)).to be_nil
    end

    it 'should destroy any password reset key it has' do
      user = FactoryGirl.create(:user)
      key = PasswordResetKey.create!(user: user)
      user.destroy
      expect(PasswordResetKey.find_by_id(key.id)).to be_nil
    end

    it 'should destroy any user field values' do
      user = FactoryGirl.create(:user)
      value = UserFieldValue.create!(field_name: 'foo', user: user, value: '')
      user.destroy
      expect(UserFieldValue.find_by_id(value.id)).to be_nil
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
    u = User.authenticate('user', '')
    expect(u).to be_nil
  end

  it 'should hash the password on create' do
    User.create!(login: 'instructor', password: 'ilikecookies', email: 'instructor@example.com')
    user = User.find_by_login!('instructor')
    expect(user.password).to be_nil
    expect(user.password_hash).not_to be_nil
    expect(user).to have_password('ilikecookies')
    expect(user).not_to have_password('ihatecookies')
  end

  it 'should hash the password on update' do
    User.create!(login: 'instructor', password: 'ihatecookies', email: 'instructor@example.com')

    user = User.find_by_login!('instructor')
    user.password = 'ilikecookies'
    user.save!

    user = User.find_by_login!('instructor')
    expect(user.password).to be_nil
    expect(user.password_hash).not_to be_nil
    expect(user).to have_password('ilikecookies')
    expect(user).not_to have_password('ihatecookies')
  end

  it 'should not reset the password when saved without changing the password' do
    user = User.create!(login: 'instructor', password: 'ihatecookies', email: 'instructor@example.com')
    user.login = 'funny_person'
    user.save!

    user = User.find_by_login!('funny_person')
    expect(user).to have_password('ihatecookies')
  end

  it 'should allow authentication of administrators with a correct login/password' do
    user = User.create!(login: 'instructor', password: 'ilikecookies', administrator: true, email: 'instructor@example.com')
    expect(User.authenticate('instructor', 'ilikecookies')).to eq(user)
    expect(User.authenticate('instructor', 'ihatecookies')).to be_nil
    expect(User.authenticate('root', 'ilikecookies')).to be_nil
  end
end
