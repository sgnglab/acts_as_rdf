# -*- coding: utf-8 -*-

# -*- coding: utf-8 -*-
require File.join(File.dirname(__FILE__), 'spec_helper')

# 値の更新機能のテスト
describe 'ActsAsRDF' do
  before do
    @alice_uri = RDF::URI.new('http://ali.ce')
    @alice_name = RDF::Literal.new('Alice')

    @context = RDF::URI.new('http://context.com')

    ActsAsRDF.repository = RDF::Repository.new{|r|
      r << [@alice_uri, RDF::FOAF.name, @alice_name, @context]
      r << [@alice_uri, RDF.type, RDF::FOAF['Person'], @context]
    }

    class Person
      include ActsAsRDF::Resource
      define_type RDF::FOAF['Person']
      has_object :name, RDF::FOAF[:name], String
      has_subjects :known_to, RDF::FOAF[:knows], Person
    end
  end
  
  it "should be return cache" do
    alice = Person.find(@alice_uri, @context)
    name = alice.name
    ActsAsRDF.repository = RDF::Repository.new
    alice.name.should == name
  end

  it "should not return cache if reloaded" do
    alice = Person.find(@alice_uri, @context)
    name = alice.name
    alice.name = "a"
    alice.name.should == "a"
    alice.load
    alice.name.should == name
  end

  it "should update" do
    alice = Person.find(@alice_uri, @context)
    name = alice.name
    alice.name = "a"
    alice.save
    alice.name = "b"
    alice.name.should == "b"
    alice.load
    alice.name.should == "a"
  end
end
