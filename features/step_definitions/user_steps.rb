### UTILITY METHODS ###

@@welcome_message = "Welcome, "

def create_visitor
  @visitor ||= { :display_name => "Testy McUserton", :email => "example@example.com",
    :password => "changeme", :password_confirmation => "changeme" }
end

def find_user
  @user ||= User.where(email: @visitor[:email]).first
end

def create_unconfirmed_user
  create_visitor
  delete_user
  sign_up
  visit '/users/sign_out'
end

def create_user(options={})
  create_visitor
  delete_user
  @user = FactoryGirl.create(:user, email: @visitor[:email])
  @user.add_role(options[:role]) if options[:role]
  return @user
end

def delete_user
  @user ||= User.where(email: @visitor[:email]).first
  @user.destroy unless @user.nil?
end

def sign_up
  delete_user
  visit '/users/sign_up'
  fill_in "Name", :with => @visitor[:display_name]
  fill_in "Email", :with => @visitor[:email]
  fill_in "user_password", :with => @visitor[:password]
  fill_in "user_password_confirmation", :with => @visitor[:password_confirmation]
  click_button "Sign up"
  find_user
end

def sign_in
  visit '/users/sign_in'
  fill_in "Email", :with => @visitor[:email]
  fill_in "Password", :with => @visitor[:password]
  click_button "Sign In"
end

### GIVEN ###
Given /^I am not logged in$/ do
  visit '/users/sign_out'
end

Given /^I am logged in$/ do
  create_user
  sign_in
end

Given /^I am logged in as (.*)$/ do |role|
  create_user :role => role
  sign_in
end

Given /^I exist as a user$/ do
  create_user
end

Given /^I do not exist as a user$/ do
  create_visitor
  delete_user
end

Given /^I exist as an unconfirmed user$/ do
  create_unconfirmed_user
end

### WHEN ###
When /^I sign in with valid credentials$/ do
  create_visitor
  sign_in
end

When /^I sign out$/ do
  visit '/users/sign_out'
end

When /^I sign up with valid user data$/ do
  create_visitor
  sign_up
end

When /^I sign up with an invalid email$/ do
  create_visitor
  @visitor = @visitor.merge(:email => "notanemail")
  sign_up
end

When /^I sign up without a password confirmation$/ do
  create_visitor
  @visitor = @visitor.merge(:password_confirmation => "")
  sign_up
end

When /^I sign up without a password$/ do
  create_visitor
  @visitor = @visitor.merge(:password => "")
  sign_up
end

When /^I sign up with a mismatched password confirmation$/ do
  create_visitor
  @visitor = @visitor.merge(:password_confirmation => "changeme123")
  sign_up
end

When /^I return to the site$/ do
  visit '/'
end

When /^I sign in with a wrong email$/ do
  @visitor = @visitor.merge(:email => "wrong@example.com")
  sign_in
end

When /^I sign in with a wrong password$/ do
  @visitor = @visitor.merge(:password => "wrongpass")
  sign_in
end

When /^I edit my account details$/ do
  click_button @@welcome_message + "Public User - " + @user[:display_name]
  click_link 'My Settings'
  fill_in "Name", :with => "newname"
  fill_in "user_current_password", :with => @visitor[:password]
  click_button "Save"
end

When /^I look at the list of users$/ do
  visit '/'
end

When(/^I view the Admin page$/) do
  visit '/users'
end

### THEN ###
Then /^I should be signed in$/ do
  expect(page).to have_content @@welcome_message
  expect(page).to have_content @user[:display_name]
  expect(page).to have_content "Logout"
  expect(page).to_not have_content "Sign up"
  expect(page).to_not have_content "Login"
end

Then /^I should be signed out$/ do
  expect(page).to_not have_content @@welcome_message
  expect(page).to have_content "Sign up"
  expect(page).to have_content "Login"
  expect(page).to_not have_content "Logout"
end

Then /^I see an unconfirmed account message$/ do
  expect(page).to have_content "You have to confirm your account before continuing."
end

Then /^I see a successful sign in message$/ do
  expect(page).to have_content "Signed in successfully."
end

Then /^I should see a successful sign up message$/ do
  expect(page).to have_content "Welcome! You have signed up successfully."
end

Then /^I should see an invalid email message$/ do
  expect(page).to have_content "Emailis invalid"
end

Then /^I should see a missing password message$/ do
  expect(page).to have_content "Passwordcan't be blank"
end

Then /^I should see a missing password confirmation message$/ do
  expect(page).to have_content "Password confirmationdoesn't match"
end

Then /^I should see a mismatched password message$/ do
  expect(page).to have_content "Password confirmationdoesn't match"
end

Then /^I should see a signed out message$/ do
  expect(page).to have_content "Signed out successfully."
end

Then /^I see an invalid login message$/ do
  expect(page).to have_content "Invalid email or password."
end

Then /^I should see an account edited message$/ do
  expect(page).to have_content "You updated your account successfully."
end

Then /^I should see my name$/ do
  create_user
  expect(page).to have_content @user[:display_name]
end

Then /^I should see role (.*)$/ do |role|
  expect(page).to have_content role.titleize
end

Then /I should be sent to (.*)/ do |title|
  expect(page).to have_content title
end

Then /^I see a not authorized message$/ do
  expect(page).to have_content "Not authorized"
end

Then /^I see item (.*)$/ do |item|
  expect(page).to have_content item
end

Then /^I do not see (.*)$/ do |item|
  expect(page).to_not have_content item
end
