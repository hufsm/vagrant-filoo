require "vagrant_filoo/config"
require 'rspec/its'

describe VagrantPlugins::Filoo::Config do
  let(:instance) { described_class.new }

  # Ensure tests are not affected by Filoo credential environment variables
  before :each do
    ENV.stub(:[] => nil)
  end
  
  describe "defaults" do
    subject do
      instance.tap do |o|
        puts(o.inspect)
        o.finalize!
      end
    end
    its("filoo_api_key")     { should be_nil }
    its("filoo_api_entry_point")     { should be_nil }
  end

  
  describe "overriding defaults" do
    # I typically don't meta-program in tests, but this is a very
    # simple boilerplate test, so I cut corners here. It just sets
    # each of these attributes to "foo" in isolation, and reads the value
    # and asserts the proper result comes back out.
    [:filoo_api_key].each do |attribute|

      it "should not default #{attribute} if overridden" do
        instance.send("#{attribute}=".to_sym, "foo")
        instance.finalize!
        instance.send(attribute).should == "foo"
      end
    end
  end
  
  describe "getting credentials from environment" do
    context "without FILOO credential environment variables" do
      subject do
        instance.tap do |o|
          o.finalize!
        end
      end

      its("filoo_api_key")     { should be_nil }

    end

    context "with Filoo credential and entry point environment variables" do
      before :each do
        ENV.stub(:[]).with("FILOO_API_KEY").and_return("filoo_api_key")
        ENV.stub(:[]).with("FILOO_API_ENTRY_POINT").and_return("http://example.com")
      end

      subject do
        instance.tap do |o|
          o.finalize!
        end
      end

      its("filoo_api_key")     { should == "filoo_api_key" }
      its("filoo_api_entry_point") { should == "filoo_api_entry_point" }
    end
  end
  
  
  
end