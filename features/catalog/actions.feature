Feature: A User can select a view and see a list of available actions
  In order to provide the user with a choice of actions for a view
  Any User will need to be able to select a view and see a list of available actons

  Scenario: User has no view selected
    Given I have a catalog with multiple sources and views
    And Actions exist
    And I have opened the Catalog
    Then I should see the Actions Menu
    And I should not see any available actions

@javascript
  Scenario: User selects a view
    Given I have a catalog with multiple sources and views
    And Actions exist
    And I have opened the Catalog
    And I open source Source A
    When I choose View a
    Then View a should be selected

@javascript
  Scenario: User selects a view with no available actions
    Given I have a catalog with multiple sources and views
    And Actions exist
    And I have opened the Catalog
    And I open source Source A
    And I choose View a
    Then I should see the Actions Menu
    And I should see the Metadata action available

@javascript
  Scenario: User selects a view with available actions
    Given I have a catalog with multiple sources and views
    And Actions exist
    And I have opened the Catalog
    And I open source Source A
    And I open source Source B
    When I choose View b
    Then I should see the Actions Menu
    And I should see the Table action available
    When I choose View c
    Then I should see the Map action available
    
