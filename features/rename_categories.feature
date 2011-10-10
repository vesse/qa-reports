Feature:
  As a Meego QA engineer
  I want to be able to rename testsets and products
  So that I can better reorganize and manage reports

  Background:
    Given I am logged in
    And I have uploaded reports with profile "Core" having testset "foo" and product "N900"
    And I have uploaded reports with profile "Handset" having testset "foo" and product "N900"
    And I have uploaded reports with profile "Handset" having testset "foo" and product "Pinetrail"
    And I am on the front page

  Scenario: Hide edit button when not logged in
    When I log out
    And I am on the front page

    Then I should not see the edit button

  @selenium
  Scenario: Rename testset
    When I click on the edit button
    And I edit the testset name "foo" to "bar" for profile "Core"
    And I press enter key

    When I press done button
    And I reload the front page

    Then I should see testset "bar" for profile "Core"
    And I should see testset "foo" for profile "Handset"

  @selenium
  Scenario: Cancel testset renaming
    When I click on the edit button
    And I edit the testset name "foo" to "bar" for profile "Core"
    And I press escape key

    When I press done button
    And I reload the front page

    Then I should see testset "foo" for profile "Core"
    And I should see testset "foo" for profile "Handset"

  @selenium
  Scenario: Automatic renaming of report titles when testset is renamed
    When I rename the testset "foo" under profile "Core" to "bar"
    And I view the group report for "Core/bar"
    And I scroll down the page

    Then I should see "bar" in test reports titles
    But I should not see "foo" in test reports titles

    When I view the group report for "Handset/foo"

    Then I should see "foo" in test reports titles
    But I should not see "bar" in test reports titles

  @selenium
  Scenario: Rename product
    When I rename the product "N900" to "N950"
    And I reload the front page

    Then I should see "N950"
    But I should not see "N900"
