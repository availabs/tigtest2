Feature: Show Users for Admin
  In order to administer users
  Administrators will need to see a list of users
  
  Scenario: User is not Admin
    Given I am logged in
    When I view the Admin page
    Then I should land on the dashboard
     And I see a not authorized message
    
  Scenario: User is Admin
    Given I am logged in as admin
    When I view the Admin page
    Then I should be sent to Users
     And I should see my name
     And I should see role admin


    




