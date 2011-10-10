focused_input = ""

def category_url(*category)
  "/#{Release.in_sort_order.first.name}/#{category.join('/')}"
end

def category_selector(*category)
  "#report_navigation a.name[href='#{category_url(category)}']"
end

When /^I have uploaded reports with profile "([^"]*)" having testset "([^"]*)" and product "([^"]*)"$/ do |profile, testset, product|
#  FactoryGirl.create(:profile, :label => profile, :normalized => profile.downcase) if TargetLabel.find_by_label(profile).nil?
  FactoryGirl.create_list(:test_report, 2,
    :release => Release.in_sort_order.first,
    :target  => profile.downcase,
    :testset => testset,
    :product => product,
    :title => "#{testset} Test Report: N900 Basic Feature 2011-09-29")
end

When /^I click on the edit button$/ do
  When "I press \"home_edit_link\""
end

When /^I edit the testset name "([^"]*)" to "([^"]*)" for profile "([^"]*)"$/ do |orig_name, new_name, profile|
  testset   = find category_selector(profile, orig_name)
  testset.click

  url = category_url(profile, orig_name)
  focused_input = find("#report_navigation input[data-url='#{url}']")
  focused_input.set new_name
end

When /^I press enter key$/ do
  focused_input.native.send_key("\n")
end

Then /^I should see testset "([^"]*)" for profile "([^"]*)"$/ do |testset, profile|
  url = category_url(profile,testset)
  sel = "#report_navigation a.name[href='#{url}']"
  Then %{I should see "#{testset}" within "#{sel}"}
end

When /^I press done button$/ do
  click_on("home_edit_done_link")
end

When /^I reload the front page$/ do
  visit('/')
end

When /^I press escape key$/ do
  focused_input.native.send_key("\e")
end

When /^I rename the testset "([^"]*)" under profile "([^"]*)" to "([^"]*)"$/ do |orig_name, profile, new_name|
  Then %{I click on the edit button}
  And %{I edit the testset name "#{orig_name}" to "#{new_name}" for profile "#{profile}"}
  And %{I press enter key}
  And %{I press done button}
end

When /^I view the group report for "([^"]*)"$/ do |path|
  visit("/#{Release.in_sort_order.first.name}/#{path}")
end

Then /^I should see "([^"]*)" in test reports titles$/ do |title|
  Then %{I should see "#{title}" within "#report_filtered_navigation .report_name"}
end

Then /^I should not see "([^"]*)" in test reports titles$/ do |title|
  Then %{I should not see "#{title}" within "#report_filtered_navigation .report_name"}
end

Then /^I should not see the edit button$/ do
  page.should have_no_link("home_edit_link")
end

When /^I edit the product name "([^"]*)" to "([^"]*)"$/ do |old_name, new_name|
  product = first("#report_navigation .products a", :text => old_name)
  product.click
  focused_input = product.find(:xpath, "../input")
  focused_input.set new_name
end

When /^I rename the product "([^"]*)" to "([^"]*)"$/ do |old_name, new_name|
  Then %{I click on the edit button}
  And %{I edit the product name "#{old_name}" to "#{new_name}"}
  And %{I press enter key}
  And %{I press done button}
end