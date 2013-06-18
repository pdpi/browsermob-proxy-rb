require 'spec_helper'

describe "Proxy + WebDriver" do
  let(:driver)  { Selenium::WebDriver.for :firefox, :profile => profile }
  let(:proxy) { new_proxy }

  let(:profile) {
    pr = Selenium::WebDriver::Firefox::Profile.new
    pr.proxy = proxy.selenium_proxy

    pr
  }

  after {
    driver.quit
    proxy.close
  }

  it "should fetch a HAR" do
    proxy.new_har("1")
    driver.get url_for("1.html")

    proxy.new_page "2"
    driver.get url_for("2.html")

    har = proxy.har

    har.should be_kind_of(HAR::Archive)
    har.pages.size.should == 2
  end

  it "should fetch a HAR and capture headers" do
    proxy.new_har("2", :capture_headers => true)

    driver.get url_for("2.html")

    entry = proxy.har.entries.first
    entry.should_not be_nil

    entry.request.headers.should_not be_empty
  end

  it "should set whitelist and blacklist" do
    proxy.whitelist(/example\.com/, 201)
    proxy.blacklist(/bad\.com/, 404)
  end

  it "should set headers" do
    proxy.headers('Content-Type' => "text/html")
  end

  it "should set limits" do
    proxy.limit(:downstream_kbps => 100, :upstream_kbps => 100, :latency => 2)
  end

  it "should replace domain name lookups" do
    proxy.add_host('www.example.com', '0.0.0.0')
    port = BrowserMob::Proxy::SpecHelper.httpd.port
    driver.get "www.example.com:#{port}/1.html"
    p driver.find_element(:xpath => '//body').text
    driver.find_element(:id,"header").text.should == "BrowserMob-Proxy test page"
  end

  it "should replace domain name lookups" do
    proxy.rewrite(/(.*)\/1.html/, "$1/2.html")
    port = BrowserMob::Proxy::SpecHelper.httpd.port
    driver.get url_for("1.html")
    p driver.find_element(:xpath => '//body').text
    driver.find_element(:id,"header").text.should == "A second test"
  end

end
