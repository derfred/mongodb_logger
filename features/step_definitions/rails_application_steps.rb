require 'active_support/core_ext/string/inflections'

Given /^I have built and installed the "([^\"]*)" gem$/ do |gem_name|
  if 'java' == RUBY_PLATFORM
    @terminal.build_and_install_gem(File.join(PROJECT_ROOT, "#{gem_name}.java.gemspec"))
  else
    @terminal.build_and_install_gem(File.join(PROJECT_ROOT, "#{gem_name}.gemspec"))
  end
end

When /^I generate a new Rails application$/ do
  @terminal.cd(TEMP_DIR)
  version_string = ENV['RAILS_VERSION']
  rails_create_command = 'new'
  
  rails_dir_search = (version_string =~ /^3.(0|1)/) ? "rails" : "railties"
  
  load_rails = <<-RUBY
    gem "rails", "#{version_string}"; \
    load Gem.bin_path("#{rails_dir_search}", "rails", "#{version_string}")
  RUBY

  @terminal.run(%{ruby -rrubygems -rthread -e "#{load_rails.gsub("\"", "\\\"").strip!}" #{rails_create_command} rails_root})
  if rails_root_exists?
    @terminal.echo("Generated a Rails #{version_string} application")
  else
    raise "Unable to generate a Rails application:\n#{@terminal.output}"
  end
  #require_thread if rails30?
end

When /^I configure my application to require the "([^\"]*)" gem(?: with version "(.+)")?$/ do |gem_name, version|
  bundle_gem(gem_name, version)
end

When /^I setup mongodb_logger tests$/ do
  copy_tests
  add_routes
end

When /^I setup all gems for rails$/ do
  if !rails30?
    if 'java' == RUBY_PLATFORM
      bundle_gem("therubyrhino", nil)
      bundle_gem("jruby-openssl", nil)
    else
      bundle_gem("therubyracer", nil)
    end
  end
  step %{I run "bundle install"}
  @terminal.status.exitstatus.should == 0
end

When /^I prepare rails environment for testing$/ do
  step %{I run "rake db:create db:migrate RAILS_ENV=test --trace"}
  @terminal.status.exitstatus.should == 0
end


Then /^the tests should have run successfully$/ do
  step %{I run "rake test RAILS_ENV=test --trace"}
  @terminal.status.exitstatus.should == 0
  # show errors
  output_log = @terminal.output
  is_pass = false
  # TODO: fix regexp later, because can PASS in 10 or 100 failures
  is_pass = true if ((1 == output_log.scan(/([.*]?)fail: 0(\D+)error: 0([\D+]?)/i).size) || (1 == output_log.scan(/(.*)0 failures(.*)0 errors(.*)/i).size))
  puts @terminal.output unless is_pass
  # check if have errors
  is_pass.should == true
end

When /^I run "([^\"]*)"$/ do |command|
  @terminal.cd(rails_root)
  @terminal.run(command)
end
