require 'spec_helper'

module BrowserMob
  module Proxy

    describe Client do
      let(:resource)      { mock(RestClient::Resource) }
      let(:client)        { Client.new(resource, "localhost", 9091) }

      before do
        {
          "har"         => mock("resource[har]"),
          "har/pageRef" => mock("resource[har/pageRef]"),
          "whitelist"   => mock("resource[whitelist]"),
          "blacklist"   => mock("resource[blacklist]"),
          "limit"       => mock("resource[limit]"),
          "headers"     => mock("resource[headers]"),
          "hosts"       => mock("rescource[hosts]"),
          "rewrite"     => mock("resource[rewrite]")
        }.each do |path, mock|
          resource.stub!(:[]).with(path).and_return(mock)
        end
      end

      it "creates a named har" do
        resource['har'].should_receive(:put).
                        with(:initialPageRef => "foo").
                        and_return('')

        client.new_har("foo").should be_nil
      end

      it "creates a new har with no name" do
        resource['har'].should_receive(:put).
                        with({}).
                        and_return('')

        client.new_har.should be_nil
      end

      it "returns the previous archive if one exists" do
        resource['har'].should_receive(:put).
                        with(:initialPageRef => "foo").
                        and_return(fixture("google.har"))

        client.new_har("foo").should be_kind_of(HAR::Archive)
      end

      it "turns on header capture when given a name" do
        resource['har'].should_receive(:put).
                        with(:initialPageRef => "foo", :captureHeaders => true).
                        and_return('')

        client.new_har("foo", :capture_headers => true).should be_nil
      end

      it "turns on header capture when not given a name" do
        resource['har'].should_receive(:put).
                        with(:captureHeaders => true).
                        and_return('')

        client.new_har(:capture_headers => true).should be_nil
      end

      it "gets the current har" do
        resource['har'].should_receive(:get).
                        and_return(fixture("google.har"))

        client.har.should be_kind_of(HAR::Archive)
      end

      it "creates a new page" do
        resource['har/pageRef'].should_receive(:put).
                                with :pageRef => "foo"

        client.new_page "foo"
      end

      it "sets the blacklist" do
        resource['blacklist'].should_receive(:put).
                              with(:regex => "http://example.com", :status => 401)

        client.blacklist(%r[http://example.com], 401)
      end

      it "sets the whitelist" do
        resource['whitelist'].should_receive(:put).
                              with(:regex => "http://example.com", :status => 401)

        client.whitelist(%r[http://example.com], 401)
      end

      it "sets the hosts list when adding new hosts" do
        resource['hosts'].should_receive(:post).
                          with('{"www.example.com":"127.0.0.1"}',
                              :content_type => "application/json")

        client.add_host('www.example.com', '127.0.0.1')
      end

      it "sets the hosts list when deleting hosts" do
        resource['hosts'].should_receive(:post)
        client.add_host('www.example.com', '127.0.0.1')
        resource['hosts'].should_receive(:post)
        client.add_host('subdomain.example.com', '192.168.1.1')

        resource['hosts'].should_receive(:post).
                          with('{"subdomain.example.com":"192.168.1.1"}',
                              :content_type => "application/json")

        client.remove_host('www.example.com')
      end

      it "sets the :downstream_kbps limit" do
        resource['limit'].should_receive(:put).
                          with('downstreamKbps' => 100)

        client.limit(:downstream_kbps => 100)
      end

      it "sets the :upstream_kbps limit" do
        resource['limit'].should_receive(:put).
                          with('upstreamKbps' => 100)

        client.limit(:upstream_kbps => 100)
      end

      it "sets the :latency limit" do
        resource['limit'].should_receive(:put).
                          with('latency' => 100)

        client.limit(:latency => 100)
      end

      it "sets all limits" do
        resource['limit'].should_receive(:put).
                          with('latency' => 100, 'downstreamKbps' => 200, 'upstreamKbps' => 300)

        client.limit(:latency => 100, :downstream_kbps => 200, :upstream_kbps => 300)
      end

      it "raises ArgumentError on invalid options" do
        lambda { client.limit(:foo => 1) }.should raise_error(ArgumentError)
        lambda { client.limit({})        }.should raise_error(ArgumentError)
      end

      it "sets headers" do
        resource['headers'].should_receive(:post).with('{"foo":"bar"}', :content_type => "application/json")

        client.headers(:foo => "bar")
      end

      it "rewrites URLs" do
        resource['rewrite'].should_receive(:put).with(:matchRegex => "foo.*", :replace => "bar")

        client.rewrite(/foo.*/, "bar")
      end

      context "#selenium_proxy" do
        it "defaults to HTTP proxy only" do
          proxy = client.selenium_proxy

          proxy.http.should == "#{client.host}:#{client.port}"
          proxy.ssl.should be_nil
          proxy.ftp.should be_nil
        end

        it "allows multiple protocols" do
          proxy = client.selenium_proxy(:http, :ssl)

          proxy.http.should == "#{client.host}:#{client.port}"
          proxy.ssl.should == "#{client.host}:#{client.port}"
          proxy.ftp.should be_nil
        end

        it "allows disabling HTTP proxy" do
          proxy = client.selenium_proxy(:ssl)

          proxy.ssl.should == "#{client.host}:#{client.port}"
          proxy.http.should be_nil
          proxy.ftp.should be_nil
        end

        it "raises an error when a bad protocol is used" do
          lambda {
            client.selenium_proxy(:htp)
          }.should raise_error
        end
      end
    end

  end
end
