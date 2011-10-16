# -*- coding: utf-8 -*-
require File.join(File.dirname(__FILE__), 'spec_helper')

describe 'ActsAsRDF::ResourceにおけるValication' do
  before(:each) do
    @alice_uri = RDF::URI.new('http://ali.ce')
    @alice_name = RDF::Literal.new('Alice')
    @context = RDF::URI.new('http://context.com')

    ActsAsRDF.repository = RDF::Repository.new{|r|
      r << [@alice_uri, RDF::FOAF.name, @alice_name, @context]
      r << [@alice_uri, RDF.type, RDF::FOAF['Person'], @context]
    }
  end

  describe "direct validation" do
    before do
      class PersonCallbacksValidation
        include ActsAsRDF::Resource      
        define_type RDF::FOAF['Person']
        has_object :name, RDF::FOAF['names'], String
        validates_each :name do |record, attr, value|
          record.errors.add attr, 'starts with b.' if value.to_s[0] == ?b
        end
        init_attribute_methods
      end
    end

    subject { PersonCallbacksValidation.find(@alice_uri, @context) }

    it "should be valid" do
      subject.valid?.should be_true
      subject.invalid?.should be_false
    end

    it "should be invalid" do
      subject.name = 'bad name'
      subject.valid?.should be_false
      subject.invalid?.should be_true
    end
  end
end
