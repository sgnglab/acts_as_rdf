# -*- coding: utf-8 -*-
require File.join(File.dirname(__FILE__), 'spec_helper')

# 関連の型変換に関するテスト
describe 'ActsAsRDF' do
  before(:all) do
    class PersonT
      include ActsAsRDF::Resource
      
      define_type RDF::FOAF['Person']
      has_object :name, RDF::FOAF[:name], Spira::Types::String
      has_object :age, RDF::FOAF[:age], Spira::Types::Integer
      
      init_attribute_methods
    end
  end
  
  before(:each) do
    @alice_uri = RDF::URI.new('http://ali.ce')
    @alice_name = RDF::Literal.new('Alice')
    @alice_blog = RDF::URI.new('htt://alice.blog.com')
    
    @bob_uri = RDF::URI.new('http://bob.com')

    @context = RDF::URI.new('http://context.com')

    ActsAsRDF.repository = RDF::Repository.new{|r|
      r << [@alice_uri, RDF::FOAF.name, 'wrong_name']
      r << [@alice_uri, RDF::FOAF.name, @alice_name, @context]
      r << [@alice_uri, RDF::FOAF.homepage, @alice_blog, @context]
      r << [@alice_uri, RDF::FOAF.knows, @bob_uri, @context]
      r << [@alice_uri, RDF.type, RDF::FOAF['Person'], @context]
      r << [@bob_uri, RDF.type, RDF::FOAF['Person'], @context]
      r << [@alice_blog, RDF.type, RDF::FOAF['Document'], @context]
    }
  end

  context 'with relation type' do
    before do
      @alice = PersonT.find(@alice_uri, @context)
    end

    it 'should return string' do
      @alice.name.should be_instance_of(String)
      @alice.name.should == @alice_name.to_s
    end

    it 'should update' do
      new_name = 'AAALLIICCE'
      @alice.name = new_name
      @alice.name.should be_instance_of(String)
      @alice.name.should == new_name
    end

    it 'should update' do
      new_name = 'AAALLIICCE'
      @alice.name = new_name
      @alice.name.should be_instance_of(String)
      @alice.name.should == new_name

#      @alice.age = 20
#      @alice.age.should be_instance_of(Integer)
#      @alice.age.should == 20
    end
  end
end
