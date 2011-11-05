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
  
  it "should return nil" do
    bob_uri = RDF::URI.new('http://bob.com')
    bob = PersonUpdate.find(bob_uri, @context)
    bob.should === nil
  end
end
