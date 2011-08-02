# -*- coding: utf-8 -*-

# -*- coding: utf-8 -*-
require File.join(File.dirname(__FILE__), 'spec_helper')

# 値の更新機能のテスト
describe 'ActsAsRDF' do
  before(:all) do
    class PersonUpdate
      include ActsAsRDF::Resource
      
      define_type RDF::FOAF['Person']
      has_object :name, RDF::FOAF[:name], String
      has_subjects :known_to, RDF::FOAF[:knows], "PersonUpdate"
      
      init_attribute_methods
    end
  end

  before(:each) do
    @alice_uri = RDF::URI.new('http://ali.ce')
    @alice_name = RDF::Literal.new('Alice')

    @bob_uri = RDF::URI.new('http://bo.b')
    @bob_name = RDF::Literal.new('Bob')

    @context = RDF::URI.new('http://context.com')

    ActsAsRDF.repository = RDF::Repository.new{|r|
      r << [@alice_uri, RDF.type, RDF::FOAF['Person'], @context]
      r << [@alice_uri, RDF::FOAF.name, @alice_name, @context]
      r << [@bob_uri, RDF.type, RDF::FOAF['Person'], @context]
      r << [@bob_uri, RDF::FOAF.name, @bob_name, @context]
      r << [@bob_uri, RDF::FOAF.knows, @alice_uri, @context]
      r << [@alice_uri, RDF::FOAF.knows, @bob_uri, @context]
    }
  end

  it "should not change persisted?" do
    bob = PersonUpdate.new(ActsAsRDF.uniq_uri, @context)
    bob.persisted?.should be_false
    bob.name = 'bob'
    bob.persisted?.should be_false
  end
  
  it "should be return cache" do
    alice = PersonUpdate.find(@alice_uri, @context)
    name = alice.name
    ActsAsRDF.repository = RDF::Repository.new
    alice.name.should == name
  end

  context "load" do
    it "should not return cache if reloaded" do
      alice = PersonUpdate.find(@alice_uri, @context)
      name = alice.name
      alice.name = "a"
      alice.name.should == "a"
      alice.load
      alice.name.should == name
    end
    
    it "should update" do
      alice = PersonUpdate.find(@alice_uri, @context)
      name = alice.name
      alice.name = "a"
      alice.save
      alice.name = "b"
      alice.name.should == "b"
      alice.load
      alice.name.should == "a"
    end

    it "can call load when it is not persised" do
      alice = PersonUpdate.new(@alice_uri, @context)
      alice.load
      alice.name.should be_equal(@alice_name.to_s)
      alice.known_to.first.uri.to_s.should be_equal(@bob_uri.to_s)
      alice.known_to.first.name.to_s.should be_equal(@bob_name.to_s)
    end

    it "can call load when it is accessed its attribute" do
      alice = PersonUpdate.new(@alice_uri, @context)
      alice.name.should be_nil
      alice.known_to.should be_empty
      alice._persisted!
      alice.name.should be_equal(@alice_name.to_s)
      alice.known_to.first.uri.should be_equal(@bob_uri)
    end

    it "can call load when it is accessed its attribute" do
      PersonUpdate.find(@alice_uri, @context).known_to.first.uri.to_s.should be_equal(@bob_uri.to_s);
      PersonUpdate.find(@alice_uri, @context).known_to.first.name.should be_equal(@bob_name.to_s);
      PersonUpdate.find(@alice_uri, @context).known_to.first.known_to.first.
        name.should be_equal(@alice_name.to_s);
    end
  end

  it "should return nil" do
    bob_uri = RDF::URI.new('http://bob.com')
    bob = PersonUpdate.find(bob_uri, @context)
    bob.should === nil
  end

  it "should save resource" do
    bob_uri = RDF::URI.new('http://bob.com')
    bob = PersonUpdate.new(bob_uri, @context)
    bob.save
    bob_ = PersonUpdate.find(bob_uri, @context)
    bob_.should be_instance_of(PersonUpdate)
    bob_.uri.should === bob_uri
    bob_.context.should == @context
  end

  it "should save resource" do
    bob_uri = RDF::URI.new('http://bob.com')
    bob = PersonUpdate.new(bob_uri, @context)
    bob.name = 'bob'
    bob.save
    bob_ = PersonUpdate.find(bob_uri, @context)
    bob_.should be_instance_of(PersonUpdate)
    bob_.name.should == 'bob'
  end
end
