Feature: A User can view the Dashboard
  In order to present a user with an overview of available data
  Any User will need to view the Dashboard, which contains primary 
  controls and multiple subwindows of data.

  Scenario: Public User
    Given I am not logged in
    When I return to the site
    Then I should be signed out
    And I see item Catalog Summary
    And I see item Recent Activity
    And I do not see My Snapshots
  
  Scenario: Logged In User
    Given I am logged in
    When I return to the site
    Then I should be signed in
    And I see item Catalog
    And I see item Recent Activity
    And I see item My Snapshots




  



  
