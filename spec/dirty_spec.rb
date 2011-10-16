# -*- coding: utf-8 -*-
require File.join(File.dirname(__FILE__), 'spec_helper')

describe 'ActsAsRDF::ResourceにおけるDirty' do
  before(:all) do
    class PersonDirty
      include ActsAsRDF::Resource
      
      define_type RDF::FOAF['Person']
      has_objects :names, RDF::FOAF['names'], String
      has_subject :homepage, RDF::FOAF['homepage']
      
      init_attribute_methods
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
  end

  describe "#attribute_change" do
    subject { PersonDirty.find(@alice_uri, @context) }

    context "when attribute changed" do
      it "should return true" do
        subject.names = ["bob"]
        subject.names_changed?.should be_true
        subject.changed?.should be_true
      end
      
      it "should return true" do
        subject.homepage = @alice_uri
        subject.homepage_changed?.should be_true
        subject.changed?.should be_true
      end
    end

    context "when attribute not changed" do
      it "should return false" do
        subject.changed?.should be_false
        subject.names_changed?.should be_false
        subject.homepage_changed?.should be_false
      end
    end
  end
end
