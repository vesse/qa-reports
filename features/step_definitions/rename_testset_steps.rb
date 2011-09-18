Given /^I have no target labels$/ do
  TargetLabel.delete_all
end

When /^I have uploaded reports with profile "([^"]*)" having testset "([^"]*)"$/ do |profile, testset|
#  FactoryGirl.create(:profile, :label => profile, :normalized => profile.downcase) if TargetLabel.find_by_label(profile).nil?
  FactoryGirl.create_list(:test_report, 2,
    :release => Release.in_sort_order.first,
    :target  => profile.downcase,
    :testset => testset)
end

When /^I click on the edit button$/ do
  When "I press \"home_edit_link\""
end

When /^I edit the testset name "([^"]*)" to "([^"]*)" for profile "([^"]*)"$/ do |orig_name, new_name, profile|
  testset_id = "#{Release.in_sort_order.first.name}-#{profile}-#{orig_name}"
  click_on(testset_id)
  fill_in "input-#{testset_id}", :with => new_name
end

When /^I press enter$/ do
  pending # express the regexp above with the code you wish you had
end

Then /^I should see testset "([^"]*)" for profile "([^"]*)"$/ do |arg1, arg2|
  pending # express the regexp above with the code you wish you had
end

When /^I press done button$/ do
  pending # express the regexp above with the code you wish you had
end

When /^I reload the front page$/ do
  pending # express the regexp above with the code you wish you had
end

When /^I press escape button$/ do
  pending # express the regexp above with the code you wish you had
end

When /^I rename the testset "([^"]*)" under profile "([^"]*)" to "([^"]*)"$/ do |arg1, arg2, arg3|
  pending # express the regexp above with the code you wish you had
end

When /^I view the group report for "([^"]*)"$/ do |arg1|
  pending # express the regexp above with the code you wish you had
end

Then /^I should see "([^"]*)" in test reports titles$/ do |arg1|
  pending # express the regexp above with the code you wish you had
end

Then /^I should not see "([^"]*)" in test reports titles$/ do |arg1|
  pending # express the regexp above with the code you wish you had
end
