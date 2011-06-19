# -*- coding: utf-8 -*-
require File.join(File.dirname(__FILE__), 'spec_helper')

describe 'ActsAsRDF::ResourceにおけるDirty' do
  before(:all) do
    class PersonCallbacks
      include ActsAsRDF::Resource
      attr_accessor :logger
      
      define_type RDF::FOAF['Person']
      has_objects :names, RDF::FOAF['names'], String

      before_create :action_before_create
      def action_before_create
        @logger = 'action_before_create'
      end
      
      define_attribute_methods [:names]
    end
  end
  
  before(:each) do
    @alice_uri = RDF::URI.new('http://ali.ce')
    @alice_name = RDF::Literal.new('Alice')
    @alice_blog = RDF::URI.new('htt://alice.blog.com')

    @context = RDF::URI.new('http://context.com')

    ActsAsRDF.repository = RDF::Repository.new{|r|
      r << [@alice_uri, RDF::FOAF.name, 'wrong_name']
      r << [@alice_uri, RDF::FOAF.name, @alice_name, @context]
      r << [@alice_uri, RDF::FOAF.homepage, @alice_blog, @context]
      r << [@alice_uri, RDF.type, RDF::FOAF['Person'], @context]
      r << [@alice_blog, RDF.type, RDF::FOAF['Document'], @context]
    }
    @alice = PersonCallbacks.find(@alice_uri, @context)
  end

  describe ".included" do
    before do
      @class = PersonCallbacks
    end
    it "includes the before_create callback" do
      @class.should respond_to(:before_create)
    end
    it "includes the around_create callback" do
      @class.should respond_to(:around_create)
    end
    it "includes the after_create callback" do
      @class.should respond_to(:after_create)
    end
  end

  describe ".before_create" do
    context "callback returns true" do
      it "should get saved" do
        @person = PersonCallbacks.create(@context)
        
        @person.logger.should == 'action_before_create'
        @person.save.should == true
        @person.persisted?.should == true
      end
    end
  end
end
