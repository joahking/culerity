require File.expand_path(File.join(File.dirname(__FILE__), "..", "support", "paths"))

# we are trying to achieve common webrat and culerity steps
# and then have webrat only steps at one side and culerity only ones at another
# then provide a means to define with wich runner (webrat or culerity) should
# cucumber run a given scenario, maybe with something like this:
# :only => :webrat
# Scenario: running webrat only steps in scenario
#

#TODO moved this culerity setting outta here and into env.rb somehow
# like webrat setup happening there
Before do
  @server = Culerity::run_server
  @browser = Culerity::RemoteBrowserProxy.new @server, {:browser => :firefox}
  @host = 'http://localhost'
end

After do
  @browser.close
  @browser.exit
  @server.close
  kill_orfan_jruby
end
# until here should be moved into env.rb somehow

# now we are rewriting the steps to follow same API as webrat
# and defining (e.g) visit method down bellow
# this could allow the swapping between webrat and culerity easily by having
# only one step definition for common steps and leaving the unique internal
# like visit method out of here
When /^I go to (.+)$/ do |page_name|
  visit path_to(page_name)
end

When /^I press "(.*)"$/ do |button|
  click_button(button)
end

When /I follow "(.*)"/ do |link|
  click_link(link)
end

When /I fill in "(.*)" for "(.*)"/ do |value, field|
  fill_in(field, :with => value)
end

When /I check "(.*)"/ do |field|
  check(field)
end

When /^I uncheck "(.*)"$/ do |field|
  uncheck(field)
end

When /I choose "(.*)"/ do |field|
  choose(field)
end

# this here have no webrat counterpart so would belong into culerity only steps
When "I wait for the AJAX call to finish" do
  @browser.page.getEnclosingWindow().getThreadManager().joinAll(10000)
end

#this two here are left as is until we know the problem better
Then /I should see "(.*)"/ do |text|
  @browser.html.should  =~ /#{text}/m
end

Then /I should not see "(.*)"/ do |text|
  @browser.html.should_not  =~ /#{text}/m
end

Then /^I should not navigate away from (.+)$/ do |page_name|
  @browser.url.should == full_url(path_to(page_name))
end

def find_label(text)
  @browser.label :text, text
end

# and these are the methods to comply with webrat API
#TODO move them out of steps and into some sort of unique internal implemmentation
def visit(path)
  @browser.goto full_url(path)
  assert_successful_response
end

def click_button(button)
  @browser.button(:text, button).click
  assert_successful_response
end

def click_link(link)
  @browser.link(:text, /#{link}/).click
  assert_successful_response
end

def fill_in(field, with_options = { })
  value = with_options[:with]
  @browser.text_field(:id, find_label(field).for).set(value)
end

def check(field)
  @browser.check_box(:id, find_label(field).for).set(true)
end

def uncheck(field)
  @browser.check_box(:id, find_label(field).for).set(false)
end

def choose(field)
  @browser.radio(:id, find_label(field).for).set(true)
end

# this here are culerity support
def full_url(path)
  "#{@host}#{path}"
end

def assert_successful_response
  status = @browser.page.web_response.status_code
  if(status == 302 || status == 301)
    location = @browser.page.web_response.get_response_header_value('Location')
    puts "Being redirected to #{location}"
    @browser.goto location
  elsif status != 200
    raise "Brower returned Response Code #{@browser.page.web_response.status_code}"
  end
end

# some java processes are remaining in memory when exceptions occur
def kill_orfan_jruby
  pid = `cat tmp/pids/celerity_jruby.pid`.gsub(/[^0-9]/,'')
  unless pid.blank?
    # is it the process still alive?
    remained = `ps #{pid} | grep #{pid} | awk '{ print $1 }'`
    unless remained.blank?
      # we are silencing output because of annoying message
      `kill TERM #{pid} &> /dev/null`
      puts "killed orfan jruby process #{pid}"
    end
    `rm tmp/pids/celerity_jruby.pid`
  end
end

# or you prefer the bash version
# #!/bin/bash
# PID=`cat tmp/pids/celerity_jruby.pid`
# if [ -n $PID ]; then
#   # is it the process still alive?
#   REMAINED_PID=`ps $PID | grep $PID | awk '{ print $1 }'`
#   if [ -n $REMAINED_PID ]; then
#     # we are silencing output because of annoying message
#     kill TERM $PID &> /dev/null
#     echo "killed jruby process $PID"
#   fi
# rm tmp/pids/celerity_jruby.pid
# fi
