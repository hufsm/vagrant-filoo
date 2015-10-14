require "vagrant_filoo/action/show_job_result"
require "vagrant_filoo/config"
require 'rspec/its'
require 'rspec/mocks'
require 'rest-client'


describe VagrantPlugins::Filoo::ShowJobResult do
  RSpec::Mocks::setup(self)
  app = nil
  env = nil
  showJobResult = nil
  #env = {:machine => double("Machine", :provider_config => VagrantPlugins::Filoo::Config.new())}
  #let(:instance) { described_class.new(env) }
  
  before :each do
    ENV.stub(:[] => nil)   
  end
  
  describe "call a jobstatus with environment set without errors from api response" do
    
    #context "with Filoo credential and entry point environment variables" do
    #  before :each do
    #    ENV.stub(:[]).with("FILOO_API_KEY").and_return("filoo_api_key")
    #    ENV.stub(:[]).with("FILOO_API_ENTRY_POINT").and_return("filoo_api_entry_point")
    #  end
    #end
    jobUuid = "job_uuid"
    #Mock the http request

      
    bodyNewState =  {"status"=>{"code"=>200, "message"=>"success"}, "return"=>{"jobid"=>jobUuid, "job_status" => "new", "apistatus"=>"OK"}}
    respNewState = double("Response", :code => 200, :body => bodyNewState.to_json)
    
    bodyNewState =  {"status"=>{"code"=>200, "message"=>"success"}, "return"=>{"jobid"=>jobUuid, "job_status" => "new", "apistatus"=>"OK"}}
    respNewState = double("Response", :code => 200, :body => bodyNewState.to_json)
    
    bodyProcessingState = {"status"=>{"code"=>200, "message"=>"success"}, "return"=>{"jobid"=>jobUuid, "job_status" => "processing", "apistatus"=>"OK"}}
    respProcessingState = double("Response", :code => 200, :body => bodyProcessingState.to_json)
    
   
    bodyFinishedState =  {"status"=>{"code"=>200, "message"=>"success"}, "return"=>{"jobid"=>jobUuid, "job_status" => "processing", "apistatus"=>"OK"}}
    
    respFinishedState = double("Response", :code => 200, :body => bodyFinishedState.to_json)
    puts(respFinishedState.body)
    expect(RestClient::Request).to receive(:execute).and_return( respFinishedState)
    
    #expect(RestClient::Request).to receive(:execute).and_return(1, 2, 
    #  3, 4, 5, 6, 7)
    

      
    ENV.stub(:[]).with("FILOO_API_KEY").and_return("filoo_api_key")
    ENV.stub(:[]).with("FILOO_API_ENTRY_POINT").and_return("filoo_api_entry_point")
      
    app = double("app")
    allow(app).to receive(:call)
    ENV.stub(:[]).with("FILOO_API_KEY").and_return("filoo_api_key")
    ENV.stub(:[]).with("FILOO_API_ENTRY_POINT").and_return("http://example.com")
    providerConfig = VagrantPlugins::Filoo::Config.new
    providerConfig.finalize!
    machine = double("Machine", :provider_config => providerConfig)
    env = {:machine => machine , :job_id => jobUuid}
    showJobResult = VagrantPlugins::Filoo::ShowJobResult.new(app, env)
    showJobResult.call(env)    
  end 
end