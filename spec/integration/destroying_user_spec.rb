require 'spec_helper'

describe "Deleting own user", type: :request, integration: true do
  include IntegrationTestActions

  it 'sending email should generate token' do
    user = User.create!(login: 'user', password: 'password', email: 'theuser@example.com')

    visit '/'
    log_in_as('user', 'password')

    visit '/user'

    click_button 'Request deleting account'

    # Yay, you got mail!

    token = user.verification_tokens.delete_user[0]

    expect(token.nil? == false)
    expect(User.find_by(login: user.login) == user)
  end

  it 'verify destroy page should have a verification button and password field' do
    user = User.create!(login: 'user', password: 'password', email: 'theuser@example.com')

    visit '/'
    log_in_as('user', 'password')

    visit '/user'

    click_button 'Request deleting account'

    # Yay, you got mail!

    token = user.verification_tokens.delete_user[0]

    visit"/users/#{user.id}/destroy/#{token.token}"

    expect(page).to have_content("Deleting the account #{user.login}")

    expect(page).to have_button('Destroy my account permanently', disabled: true)

    check "I've read the above and i'm sure i understand the consequences"

    expect(page).to have_button('Destroy my account permanently', disabled: false)
    expect(User.find_by(login: user.login) == user)
    expect(page).to have_content('Your password')
  end

  it 'pressing verification button destroys user' do
    user = User.create!(login: 'user', password: 'password', email: 'theuser@example.com')
    username = user.login

    visit '/'
    log_in_as('user', 'password')

    visit '/user'

    click_button 'Request deleting account'

    # Yay, you got mail!

    token = user.verification_tokens.delete_user[0]

    visit"/users/#{user.id}/destroy/#{token.token}"

    check "I've read the above and i'm sure i understand the consequences"

    fill_in 'user[password]', with: user.password

    click_button 'Destroy my account permanently'

    page.accept_alert

    expect { User.find_by!(login: username) }.to raise_error ActiveRecord::RecordNotFound
    expect(page).to have_content("The account #{username} has been permanently destroyed")
  end

  it 'will not destroy user if password incorrect' do
    user = User.create!(login: 'user', password: 'password', email: 'theuser@example.com')

    visit '/'
    log_in_as('user', 'password')

    visit '/user'

    click_button 'Request deleting account'

    # Yay, you got mail!

    token = user.verification_tokens.delete_user[0]

    visit"/users/#{user.id}/destroy/#{token.token}"

    check "I've read the above and i'm sure i understand the consequences"

    fill_in 'user[password]', with: 'thisiswrongpassword'

    click_button 'Destroy my account permanently'

    page.accept_alert

    expect(User.find_by(login: user.login) == user)
    expect(page).to have_content('The password was incorrect')
  end

  it 'cannot be verified by another user' do
    user1 = User.create!(login: 'user1', password: 'password1', email: 'user1@example.com')
    user2 = User.create!(login: 'user2', password: 'password2', email: 'user2@example.com')

    visit '/'
    log_in_as('user1', 'password1')

    visit '/user'

    click_button 'Request deleting account'

    log_out

    log_in_as('user2', 'password2')

    token = user1.verification_tokens.delete_user[0]

    visit "/users/#{user1.id}/destroy/#{token.token}"

    expect(page).to have_content("Access denied")
  end

end
