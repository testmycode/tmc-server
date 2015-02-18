require 'spec_helper'

describe UsersController, type: :controller do
  describe 'GET show' do
    describe 'when accessed as a guest' do
      before :each do
        expect(controller.current_user).to be_guest
      end

      it 'should not deny access' do
        get :show
        expect(response.status).to eq(401)
      end

      it 'should deny access if signup is disabled in site settings' do
        SiteSetting.all_settings['enable_signup'] = false
        get :show
        expect(response.status).to eq(401)
        expect(response.headers).to include 'X-Frame-Options'
      end

      describe 'when using bare layout' do
        it 'should ' do
          get :new, bare_layout: 1
          expect(response.headers).not_to include 'X-Frame-Options'
          expect(response.status).to eq(200)
        end
      end
    end

    describe 'when accessed as a logged in user' do
      before :each do
        controller.current_user = FactoryGirl.create(:user)
      end

      it 'should show the profile page' do
        get :show
        expect(response).to be_success
      end
    end
  end

  describe 'POST create' do
    before :each do
      @valid_attrs = {
        login: 'asd',
        email: 'asd@example.com',
        email_repeat: 'asd@example.com',
        password: 'xoox',
        password_repeat: 'xoox'
      }
    end

    it 'should create a new user account' do
      post :create, user: @valid_attrs

      expect(response).to redirect_to(root_path)
      user = User.find_by_login(@valid_attrs[:login])
      expect(user).not_to be_nil
      expect(user.email).to eq(@valid_attrs[:email])
      expect(user).to have_password(@valid_attrs[:password])
    end

    it 'should require a username' do
      @valid_attrs.delete :login
      post :create, user: @valid_attrs
      expect(User.count).to eq(0)
    end

    it 'should require the username to be unique' do
      post :create, user: @valid_attrs
      @valid_attrs[:email] = @valid_attrs[:email_repeat] = 'bsd@example.com'
      post :create, user: @valid_attrs
      expect(User.count).to eq(1)
    end

    it 'should require an email' do
      @valid_attrs.delete :email
      @valid_attrs.delete :email_repeat
      post :create, user: @valid_attrs
      expect(User.count).to eq(0)
    end

    it 'should require an email confirmation' do
      @valid_attrs.delete :email_repeat
      post :create, user: @valid_attrs
      expect(User.count).to eq(0)
    end

    it 'should require a password' do
      @valid_attrs.delete :password
      @valid_attrs.delete :password_repeat
      post :create, user: @valid_attrs
      expect(User.count).to eq(0)
    end

    it 'should require a password confirmation' do
      @valid_attrs.delete :password_repeat
      post :create, user: @valid_attrs
      expect(User.count).to eq(0)
    end

    it 'should save extra fields' do
      fields = [
        UserField.new(name: 'field1', field_type: 'text'),
        UserField.new(name: 'field2', field_type: 'boolean'),
        UserField.new(name: 'field3', field_type: 'boolean')
      ]
      allow(UserField).to receive_messages(all: fields)
      allow(ExtraField).to receive(:by_kind).with(:user).and_return(fields)

      post :create, user: @valid_attrs, user_field: { 'field1' => 'foo', 'field2' => '1' }
      expect(User.count).to eq(1)

      user = User.find_by_login(@valid_attrs[:login])
      expect(user.field_value_record(fields[0]).value).to eq('foo')
      expect(user.field_value_record(fields[1]).value).not_to be_blank
      expect(user.field_value_record(fields[2]).value).to be_blank
    end

    it 'should fail if signup is disabled in site settings' do
      bypass_rescue

      SiteSetting.all_settings['enable_signup'] = false
      expect { post :create, user: @valid_attrs }.to raise_error(CanCan::AccessDenied)
      expect(User.count).to eq(0)
    end
  end

  describe 'PUT update' do
    before :each do
      @user = FactoryGirl.create(:user, email: 'oldemail')
      controller.current_user = @user
    end

    it 'should save the email field' do
      put :update, user: { email: 'newemail', email_repeat: 'newemail' }
      expect(response).to redirect_to(user_path)
      expect(@user.reload.email).to eq('newemail')
    end

    it 'should not allow changing the login' do
      old_login = @user.login
      put :update, user: { email: 'newemail', login: 'newlogin' }
      expect(response).to redirect_to(user_path)
      expect(@user.reload.login).to eq(old_login)
    end

    it 'should save extra fields' do
      fields = [
        UserField.new(name: 'field1', field_type: 'text'),
        UserField.new(name: 'field2', field_type: 'boolean'),
        UserField.new(name: 'field3', field_type: 'boolean')
      ]
      allow(UserField).to receive_messages(all: fields)
      allow(ExtraField).to receive(:by_kind).with(:user).and_return(fields)

      put :update, user: { email: @user.email }, user_field: { 'field1' => 'foo', 'field2' => '1' }

      expect(@user.field_value_record(fields[0]).value).to eq('foo')
      expect(@user.field_value_record(fields[1]).value).not_to be_blank
      expect(@user.field_value_record(fields[2]).value).to be_blank
    end

    describe 'changing the password' do
      let(:params) { { email: 'newemail' } }

      before :each do
        @user.password = 'oldpassword'
        @user.save!
        expect(@user.reload).to have_password('oldpassword')
      end

      it 'should not try to change the password unless specified' do
        put :update, user: params
        expect(response).to redirect_to(user_path)
        expect(@user.reload).to have_password('oldpassword')
      end

      it 'should change the password if the old password matched and both new password fields were the same' do
        put :update, user: params.merge(old_password: 'oldpassword',
                                        password: 'newpassword',
                                        password_repeat: 'newpassword')
        expect(response).to redirect_to(user_path)
        expect(@user.reload).to have_password('newpassword')
      end

      it 'should not change the password if the old password was wrong' do
        put :update, user: params.merge(old_password: 'wrongpassword',
                                        password: 'newpassword',
                                        password_repeat: 'newpassword')
        expect(response.status).to eq(403)
        expect(@user.reload).to have_password('oldpassword')
      end

      it 'should not change the password if the new password fields were not the same' do
        put :update, user: params.merge(old_password: 'oldpassword',
                                        password: 'newpassword',
                                        password_repeat: 'foo')
        expect(response.status).to eq(403)
        expect(@user.reload).to have_password('oldpassword')
      end

      it 'should not allow changing to a blank password' do
        put :update, user: params.merge(old_password: 'oldpassword',
                                        password: '',
                                        password_repeat: '')
        expect(response.status).to eq(403)
        expect(@user.reload).to have_password('oldpassword')
      end
    end
  end
end
