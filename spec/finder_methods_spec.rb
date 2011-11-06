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


  describe '.find' do
    subject { PersonFind }
    
    it "can call find method" do
      subject.find(@alice_uri, @context).should be_instance_of subject
      subject.find(RDF::FOAF.name, @context).should be_nil
      subject.find(@alice_uri)
    end
    
    it "cannot call find method" do
      expect{ subject.find }.to raise_error(ArgumentError)
    end

    context "it does not have result" do
      it "should return nil" do
        bob_uri = RDF::URI.new('http://bob.com')
        bob = subject.find(bob_uri, @context)
        bob.should === nil
      end
    end
  end

  context '.find_by_id' do
    before do
      @alice_encode_uri = PersonFind.encode_uri(@alice_uri)
    end
    subject { PersonFind }

    it "can call find method" do
      subject.find_by_id(@alice_encode_uri, @context).should be_instance_of subject
      subject.find_by_id(subject.encode_uri(RDF::FOAF.name), @context).should be_nil
      subject.find_by_id(@alice_encode_uri) # not raise error
    end

    it "cannot call find method" do
      expect{ subject.find_by_id }.to raise_error(ArgumentError)
    end
  end

  describe '.all' do
    context 'resouces exsist in the context' do
      subject { PersonFind.all(@context) }
      
      it "returns alice and bob" do
        [@alice_uri, @bob_uri].each{ |uri|
          subject.map{|x| x.uri.to_s }.should include uri.to_s
        }
      end
      it "returns two resouces" do
        subject.should have(2).items
      end
    end
    context 'resouces do not exsist in the context' do
      subject { PersonFind.all(RDF::URI("http://no.exists/")) }
      
      it "returns alice and bob" do
        [@alice_uri, @bob_uri].each{ |uri|
          subject.map{|x| x.uri.to_s }.should_not include uri.to_s
        }
      end
      it "returns two resouces" do
        subject.should be_empty
      end
    end
  end
end
