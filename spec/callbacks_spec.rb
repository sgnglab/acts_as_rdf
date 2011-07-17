# -*- coding: utf-8 -*-
require File.join(File.dirname(__FILE__), 'spec_helper')

describe 'ActsAsRDF::ResourceにおけるDirty' do
  before(:each) do
    @alice_uri = RDF::URI.new('http://ali.ce')
    @alice_name = RDF::Literal.new('Alice')
    @context = RDF::URI.new('http://context.com')

    ActsAsRDF.repository = RDF::Repository.new{|r|
      r << [@alice_uri, RDF::FOAF.name, @alice_name, @context]
      r << [@alice_uri, RDF.type, RDF::FOAF['Person'], @context]
    }
  end

  describe ".included" do
    before do
      class PersonCallbacks
        include ActsAsRDF::Resource
        attr_accessor :logger
        
        define_type RDF::FOAF['Person']
        has_object :name, RDF::FOAF['names'], String
        
        init_attribute_methods
      end
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
      class PersonCallbacksBeforeCreate
        include ActsAsRDF::Resource
        attr_accessor :logger
        
        define_type RDF::FOAF['Person']
        has_object :name, RDF::FOAF['names'], String

        before_create :action_before_create
        def action_before_create
          @logger = "" unless @logger
          @logger += '+before_create'
        end
        init_attribute_methods
      end
    end

    context "create" do
      it "should be called" do
        @person = PersonCallbacksBeforeCreate.create(@context)
        
        @person.logger.should == '+before_create'
        @person.save.should == true
        @person.persisted?.should == true
      end
    end

    context "update" do
      it "should not be called" do
        @person = PersonCallbacksBeforeCreate.find(@alice_uri,@context)
        @person.name = "new_name"
        @person.save.should == true
        @person.logger.should == nil
      end
    end

    context "save" do
      it "should be called" do
        @person = PersonCallbacksBeforeCreate.new(ActsAsRDF.uniq_uri,@context)
        @person.name = "new_name"
        @person.persisted?.should be_false
        @person.save.should be_true
        @person.logger.should == '+before_create'
        @person.persisted?.should be_true
      end
    end
  end

  describe ".before_save" do
    before do
      class PersonCallbacksBeforeSave
        include ActsAsRDF::Resource
        attr_accessor :logger
        
        define_type RDF::FOAF['Person']
        has_object :name, RDF::FOAF['names'], String
        
        before_save :action_before_save
        def action_before_save
          @logger = "" unless @logger
          @logger += '+before_save'
        end

        init_attribute_methods
      end
    end

    context "create" do
      it "should be called" do
        @person = PersonCallbacksBeforeSave.create(@context)
        
        @person.logger.should == '+before_save'
        @person.save.should == true
        @person.persisted?.should == true
      end
    end

    context "save" do
      it "should be called" do
        person = PersonCallbacksBeforeSave.new(ActsAsRDF.uniq_uri,@context)

        person.save.should == true        
        person.logger.should == '+before_save'
        person.persisted?.should == true
      end
    end

    context "update" do
      it "should be called" do
        alice = PersonCallbacksBeforeSave.find(@alice_uri,@context)

        alice.save.should == true
        alice.logger.should == '+before_save'
      end
    end
  end

  describe ".before_update" do
    before do
      class PersonCallbacksBeforeUpdate
        include ActsAsRDF::Resource
        attr_accessor :logger
        
        define_type RDF::FOAF['Person']
        
        before_update :action_before_update
        def action_before_update
          @logger = "" unless @logger
          @logger += '+before_update'
        end

        init_attribute_methods
      end
    end

    context "create" do
      it "should not be called" do
        @person = PersonCallbacksBeforeUpdate.create(@context)
        
        @person.logger.should == nil
      end
    end

    context "save" do
      it "should not be called" do
        person = PersonCallbacksBeforeUpdate.new(ActsAsRDF.uniq_uri,@context)
        
        person.save.should == true
        person.logger.should == nil
      end
    end

    context "update" do
      it "should be called" do
        alice = PersonCallbacksBeforeUpdate.find(@alice_uri,@context)

        alice.save.should == true
        alice.logger.should == '+before_update'
      end
    end
  end
end
