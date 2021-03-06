require 'gamefic-sdk'
require 'tmpdir'

describe "Restaurant (Web)", :type => :feature, :js => true do
  before :each do
    @dir = Dir.mktmpdir
  end
  after :each do
    FileUtils.remove_entry @dir
  end
  it "concludes web game with test me" do
    config = Gamefic::Sdk::Config.new('examples/restaurant', { 'release_path' => "#{@dir}/release", 'build_path' => "#{@dir}/build" })
    web = Gamefic::Sdk::Platform::Web.new(config: config)
    web.build
    Capybara.app.root = @dir
    Capybara.app.run_test page
    expect(page.evaluate_script("document.getElementById('gamefic_console').getAttribute('class').indexOf('concluded') != -1")).to eq(true)
  end
end
