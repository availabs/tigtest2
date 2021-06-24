Feature: A User can view the Catalog
  In order to present the user with a tree of sources and views
  Any User will need to view the Catalog and drill down sources to views
@javascript
  Scenario: User opens Catalog
    Given I return to the site
     And I have a catalog with multiple sources and views
    When I select the Catalog Summary 
    Then I should land on the catalog
    And I should see the Catalog tree
@javascript
  Scenario: User drills into Source
    Given I have a catalog with multiple sources and views
    And I have opened the Catalog
    When I open source Source A
    Then I should see view View a
    And I should see view View b
@javascript
  Scenario: User drills into View and returns
    Given I have a catalog with multiple sources and views
    And I have opened the Catalog
    And I open source Source A
    When I select Metadata for View a
    Then I should land on the show view page
    When I go Back
    Then I should land on the catalog
