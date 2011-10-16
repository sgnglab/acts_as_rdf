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
    subject do
      class PersonCallbacks
        include ActsAsRDF::Resource
        attr_accessor :logger
        
        define_type RDF::FOAF['Person']
        has_object :name, RDF::FOAF['names'], String
        
        init_attribute_methods
      end
      PersonCallbacks
    end

    [:before_create, :around_create, :after_create].each do |callbacks|
      it { should respond_to(callbacks) }
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
      PersonCallbacksBeforeCreate
    end
    
    context "it should be called" do
      context "create" do
        subject { PersonCallbacksBeforeCreate.create(@context) }
        
        its(:logger) { should eq '+before_create' }
        its(:persisted?) { should be_true }
      end
      
      context "save" do
        subject do
          person = PersonCallbacksBeforeCreate.new(ActsAsRDF.uniq_uri,@context)
          person.save
          person
        end
        
        its(:logger) { should eq '+before_create' }
        its(:persisted?) { should be_true }
      end
    end
    
    context "it should not be called" do
      context "change attributes" do
        subject do
          person = PersonCallbacksBeforeCreate.find(@alice_uri,@context)
          person.name = "new_name"
          person
        end
        
        its(:logger) { should be_nil }
      end
      
      context "new" do
        subject do
          person = PersonCallbacksBeforeCreate.new(ActsAsRDF.uniq_uri,@context)
          person.name = "new_name"
          person
        end
        
        its(:logger) { should be_nil }
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
    
    context "it should be called" do
      context "create" do
        subject { PersonCallbacksBeforeSave.create(@context) }
        
        its(:logger) { should == '+before_save' }
        its(:persisted?) { should == true }
      end
      
      context "save" do
        subject do
          person = PersonCallbacksBeforeSave.new(ActsAsRDF.uniq_uri,@context)
          person.save
          person
        end
        
        its(:logger) { should eq '+before_save' }
        its(:persisted?) { should be_true }
      end
    end
    
    context "it should not be called" do
      context "change attributes" do
        subject do
          alice = PersonCallbacksBeforeSave.find(@alice_uri,@context)
          alice.name = "new_name"
          alice
        end
      
        its(:logger) { should be_nil }
      end
    end
  end
  
  describe ".before_update" do
    before do
      class PersonCallbacksBeforeUpdate
        include ActsAsRDF::Resource
        attr_accessor :logger
   
        has_object :name, RDF::FOAF['names'], String     
        define_type RDF::FOAF['Person']
        
        before_update :action_before_update
        def action_before_update
          @logger = "" unless @logger
          @logger += '+before_update'
        end
        
        init_attribute_methods
      end
    end

    context "it should not be called" do
      context "create" do
        subject { PersonCallbacksBeforeUpdate.create(@context) }
        
        its(:logger) { should be_nil }
      end

      context "save" do
        subject do
          person = PersonCallbacksBeforeUpdate.new(ActsAsRDF.uniq_uri,@context)
          person.save
          person
        end

        its(:logger) { should be_nil }
      end
    end

    context "it should be called" do
      context "update" do
        subject do
          alice = PersonCallbacksBeforeUpdate.find(@alice_uri,@context)
          alice.name = 'new_name'
          alice.save
          alice
        end
        
        its(:logger) { should eq '+before_update' }
      end
    end
  end
  
  describe ".before_initialize" do
    before do
      class PersonCallbacksBeforeInitialize
        include ActsAsRDF::Resource
        attr_accessor :logger
        
        define_type RDF::FOAF['Person']
        
        before_initialize :action_before_initialize
        def action_before_initialize
          @logger = "" unless @logger
          @logger += '+before_initialize'
        end
        
        init_attribute_methods
      end
    end
    
    context "it should be called" do
      context "new" do
        subject { PersonCallbacksBeforeInitialize.new(ActsAsRDF.uniq_uri,@context) }
        its(:logger) { should == '+before_initialize' }
      end

      context "create" do
        subject { PersonCallbacksBeforeInitialize.create(@context) }
        
        its(:logger) { should == '+before_initialize' }
      end
    end

    context "update" do
      subject do
        person = PersonCallbacksBeforeInitialize.find(@alice_uri,@context)
        person.save
        person
      end
      
      its(:logger) { should == '+before_initialize' }
    end

    context "it should not be called" do    
      context "save" do
        subject do
          person = PersonCallbacksBeforeInitialize.new(ActsAsRDF.uniq_uri,@context)
          person.logger = nil
          person.save
          person
        end
        
        its(:logger) { should be_nil }
      end
    end
  end
end
