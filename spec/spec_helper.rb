require 'rubygems'
require 'bundler/setup'
require 'capybara/rspec'
#require 'capybara/poltergeist'
require 'simplecov'
require 'gamefic'
require 'gamefic-sdk'
require 'sinatra/base'

include Gamefic

#Capybara.javascript_driver = :poltergeist
#Capybara.javascript_driver = :selenium
SimpleCov.start

class TestFileServer < Rack::File
  attr_writer :root
  def initialize
  end
  def run_test page
    page.visit '/release/index.html'
    sleep(0.1) while page.evaluate_script("document.getElementById('gamefic_controls').getAttribute('class').indexOf('working') != -1")
    page.fill_in 'command', with: 'test me'
    page.click_button 'gamefic_submit'
    sleep(0.1) while page.evaluate_script("document.getElementById('gamefic_controls').getAttribute('class').indexOf('working') != -1")
  end
end

Capybara.app = TestFileServer.new
