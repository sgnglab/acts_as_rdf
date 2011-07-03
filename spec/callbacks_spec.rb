# -*- coding: utf-8 -*-
require File.join(File.dirname(__FILE__), 'spec_helper')

describe 'ActsAsRDF::ResourceにおけるDirty' do
  before(:all) do
    class PersonCallbacks
      include ActsAsRDF::Resource
      attr_accessor :logger
      
      define_type RDF::FOAF['Person']
      has_object :name, RDF::FOAF['names'], String

      ini_attribute_methods
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
    before do
      class PersonCallbacks
        before_create :action_before_create
        def action_before_create
          @logger = "" unless @logger
          @logger += '+before_create'
        end
      end
    end

    context "create" do
      it "should be called" do
        @person = PersonCallbacks.create(@context)
        
        @person.logger.should == '+before_create'
        @person.save.should == true
        @person.persisted?.should == true
      end
    end

    context "update" do
      it "should not be called" do
        @alice.name = "new_name"
        @alice.save.should == true
        @alice.logger.should == nil
      end
    end
  end
end
