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

  describe '.find_by_query' do
    context "pass correct RDF::Query" do
      it "should find" do
        q = RDF::Query.new({:self => {RDF.type => RDF::FOAF.Person}} , {:context => @context})
        r = PersonFind.find_by_query(q)
        r.should have(2).items
        r.each{|s| 
          s.should be_an_instance_of(PersonFind)
          s.context.should be_equal(@context)
        }
      end

      it "should not find with noexists context" do
        no_context = ActsAsRDF.uniq_uri
        q = RDF::Query.new({:self => {RDF.type => RDF::FOAF.Person}} , {:context => no_context})
        r = PersonFind.find_by_query(q)
        r.should have(0).items
      end

      it "should find with nested query" do
        q = RDF::Query.new({:bob => {RDF::FOAF.name => @bob_name, RDF::FOAF.knows => :self}} , {:context => @context})
        r = PersonFind.find_by_query(q)
        r.should have(1).items
        r.first.uri.should == @alice_uri
      end

      it "find resource only RDF::type of Class" do
        ActsAsRDF.repository << [RDF::URI.new('http://i.am.a.cat/'), RDF::FOAF.name, @alice_name, @context]
        q = RDF::Query.new({:self => {RDF::FOAF.name => @alice_name}} , {:context => @context})
        r = PersonFind.find_by_query(q)
        r.should have(1).items
        r.first.uri.should == @alice_uri
      end
    end

    context "pass incorrect RDF::Query" do
      it "has empty query" do
        q = RDF::Query.new()
        expect{ PersonFind.find_by_query(q) }.to raise_error
      end

      it "does not have :self" do
        q = RDF::Query.new({ :foo => {RDF::FOAF.name => "Alice"}} , {:context => @context})
        expect{ PersonFind.find_by_query(q) }.to raise_error
      end
    end
  end
end
