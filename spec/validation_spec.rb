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
          record.errors.add attr, 'starts with a.' if value.to_s[0] == ?a
        end
        init_attribute_methods
      end
      @alice = PersonCallbacksValidation.find(@alice_uri, @context)
    end

    it "should call valid?" do
      @alice.valid?
    end

    it "should be valid" do
      @alice.valid?.should be_true
      @alice.invalid?.should be_false
    end

    it "should be invalid" do
      @alice.name = 'alice'
      @alice.valid?.should be_false
      @alice.invalid?.should be_true
    end
  end
end
