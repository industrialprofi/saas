require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  # Register headless Chromium driver for Capybara
  Capybara.register_driver :headless_chromium do |app|
    options = Selenium::WebDriver::Chrome::Options.new
    # Headless & stability flags for CI/containers
    options.add_argument "--headless=new"
    options.add_argument "--disable-gpu"
    options.add_argument "--no-sandbox"
    options.add_argument "--disable-dev-shm-usage"
    options.add_argument "--window-size=1400,1400"

    # Prefer explicit env-provided binary
    bin = ENV["CHROME_BIN"] || ENV["CHROMIUM_BIN"]
    # Fallback common paths
    bin ||= "/usr/bin/chromium"
    bin = "/usr/bin/chromium-browser" unless File.exist?(bin)
    bin = "/usr/bin/google-chrome" unless File.exist?(bin)
    options.binary = bin if File.exist?(bin)

    Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
  end

  driven_by :headless_chromium

  # Enable Warden test helpers for Devise login in system tests
  include Warden::Test::Helpers

  setup { Warden.test_mode! }
  teardown { Warden.test_reset! }
end
