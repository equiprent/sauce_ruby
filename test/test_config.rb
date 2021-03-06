require File.expand_path("../helper", __FILE__)

class TestConfig < Test::Unit::TestCase
  def test_generates_reasonable_browser_string_from_envrionment
    preserved_env = {}
    Sauce::Config::ENVIRONMENT_VARIABLES.each do |key|
      preserved_env[key] = ENV[key] if ENV[key]
    end
    begin

      ENV['SAUCE_USERNAME'] = "test_user"
      ENV['SAUCE_ACCESS_KEY'] = "test_access"
      ENV['SAUCE_OS'] = "Linux"
      ENV['SAUCE_BROWSER'] = "firefox"
      ENV['SAUCE_BROWSER_VERSION'] = "3."

      config = Sauce::Config.new
      assert_equal "{\"name\":\"Unnamed Ruby job\",\"access-key\":\"test_access\",\"os\":\"Linux\",\"username\":\"test_user\",\"browser-version\":\"3.\",\"browser\":\"firefox\"}", config.to_browser_string
    ensure
      Sauce::Config::ENVIRONMENT_VARIABLES.each do |key|
        ENV[key] = preserved_env[key]
      end
    end
  end

  def test_generates_browser_string_from_parameters
    config = Sauce::Config.new(:username => "test_user", :access_key => "test_access",
                               :os => "Linux", :browser => "firefox", :browser_version => "3.")
    assert_equal "{\"name\":\"Unnamed Ruby job\",\"access-key\":\"test_access\",\"os\":\"Linux\",\"username\":\"test_user\",\"browser-version\":\"3.\",\"browser\":\"firefox\"}", config.to_browser_string
  end

  def test_generates_optional_parameters
    # dashes need to work for backward compatibility
    config = Sauce::Config.new(:username => "test_user", :access_key => "test_access",
                               :os => "Linux", :browser => "firefox", :browser_version => "3.",
                               :"user-extensions-url" => "testing")
    assert_equal "{\"name\":\"Unnamed Ruby job\",\"access-key\":\"test_access\",\"user-extensions-url\":\"testing\",\"os\":\"Linux\",\"username\":\"test_user\",\"browser-version\":\"3.\",\"browser\":\"firefox\"}", config.to_browser_string

    # underscores are more natural
    config = Sauce::Config.new(:username => "test_user", :access_key => "test_access",
                               :os => "Linux", :browser => "firefox", :browser_version => "3.",
                               :user_extensions_url => "testing")
    assert_equal "{\"name\":\"Unnamed Ruby job\",\"access-key\":\"test_access\",\"user-extensions-url\":\"testing\",\"os\":\"Linux\",\"username\":\"test_user\",\"browser-version\":\"3.\",\"browser\":\"firefox\"}", config.to_browser_string
  end

  def test_convenience_accessors
    config = Sauce::Config.new
    assert_equal "ondemand.saucelabs.com", config.host
  end

  def test_gracefully_degrades_browsers_field
    Sauce.config {|c|}
    config = Sauce::Config.new
    config.os = "A"
    config.browser = "B"
    config.browser_version = "C"

    assert_equal [["A", "B", "C"]], config.browsers
  end

  def test_default_to_first_item_in_browsers
    Sauce.config {|c| c.browsers = [["OS_FOO", "BROWSER_FOO", "VERSION_FOO"]] }
    config = Sauce::Config.new
    assert_equal "OS_FOO", config.os
    assert_equal "BROWSER_FOO", config.browser
    assert_equal "VERSION_FOO", config.browser_version
  end

  def test_boolean_flags
    config = Sauce::Config.new
    config.foo = true
    assert config.foo?
  end

  def test_sauce_config_default_os
    Sauce.config {|c| c.os = "TEST_OS" }
    begin
      config = Sauce::Config.new
      assert_equal "TEST_OS", config.os
    ensure
      Sauce.config {|c|}
    end
  end

  def test_can_call_sauce_config_twice
    Sauce.config {|c| c.os = "A"}
    assert_equal "A", Sauce::Config.new.os
    Sauce.config {|c|}
    assert_not_equal "A", Sauce::Config.new.os
  end

  def test_override
    Sauce.config {|c| c.browsers = [["OS_FOO", "BROWSER_FOO", "VERSION_FOO"]] }
    config = Sauce::Config.new(:os => "OS_BAR", :browser => "BROWSER_BAR", :browser_version => "VERSION_BAR")
    assert_equal "OS_BAR", config.os
    assert_equal "BROWSER_BAR", config.browser
    assert_equal "VERSION_BAR", config.browser_version
  end

  def test_clears_config
    Sauce.config {|c|}
    assert_equal [["Windows 2003", "firefox", "3.6."]], Sauce::Config.new.browsers
  end

  def test_platforms
    config = Sauce::Config.new(:os => "Windows 2003")
    assert_equal "WINDOWS", config.to_desired_capabilities[:platform]

    config = Sauce::Config.new(:os => "Windows 2008")
    assert_equal "VISTA", config.to_desired_capabilities[:platform]
  end
end
