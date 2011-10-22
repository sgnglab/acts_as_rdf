# -*- coding: utf-8 -*-
require File.join(File.dirname(__FILE__), 'spec_helper')

# 検索機能のテスト
describe 'ActsAsRDF' do
  before(:all) do
    class PersonFind
      include ActsAsRDF::Resource
      
      define_type RDF::FOAF['Person']
      has_object :name, RDF::FOAF[:name], String
      has_subjects :known_to, RDF::FOAF[:knows], "PersonFind"
      
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


  describe '#find' do
    subject { PersonFind }
    
    it "can call find method" do
      subject.find(@alice_uri, @context).should be_instance_of subject
      subject.find(RDF::FOAF.name, @context).should be_nil
    end
    
    it "cannot call find method" do
      expect{ subject.find }.to raise_error(ArgumentError)
      expect{ subject.find(@alice_uri) }.to raise_error(ArgumentError)
    end
  end

  context 'find_by_id' do
    before do
      @alice_encode_uri = PersonFind.encode_uri(@alice_uri)
    end
    subject { PersonFind }

    it "can call find method" do
      subject.find_by_id(@alice_encode_uri, @context).should be_instance_of subject
      subject.find_by_id(subject.encode_uri(RDF::FOAF.name), @context).should be_nil
    end

    it "cannot call find method" do
      expect{ subject.find_by_id }.to raise_error(ArgumentError)
      expect{ subject.find_by_id(@alice_encode_uri) }.to raise_error(ArgumentError)
    end
  end

end
