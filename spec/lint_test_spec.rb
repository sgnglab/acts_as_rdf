# -*- coding: utf-8 -*-
require 'spec_helper'
require 'test/unit/assertions'
require 'active_model/lint'

# 参照
# http://library.edgecase.com/Rails/2010/10/30/activemodel-lint-test-for-rspec.html
shared_examples_for "ActiveModel" do
  include Test::Unit::Assertions
  include ActiveModel::Lint::Tests

  # to_s is to support ruby-1.9
  ActiveModel::Lint::Tests.public_instance_methods.map{|m| m.to_s}.grep(/^test/).each do |m|
    example m.gsub('_',' ') do
      send m
    end
  end

  def model
    @model = Person.find(@alice_uri, @context)
  end
end

class Person
  include ActsAsRDF::Resource
  define_type RDF::FOAF['Person']
  has_object :name, RDF::FOAF[:name], String
  has_subjects :known_to, RDF::FOAF[:knows], Person
end

describe Person do
  before do
    @alice_uri = RDF::URI.new('http://ali.ce')
    @alice_name = RDF::Literal.new('Alice')
    
    @context = RDF::URI.new('http://context.com')
    
    ActsAsRDF.repository = RDF::Repository.new{|r|
      r << [@alice_uri, RDF::FOAF.name, 'wrong_name']
      r << [@alice_uri, RDF::FOAF.name, @alice_name, @context]
      r << [@alice_uri, RDF.type, RDF::FOAF['Person'], @context]
    }
   
  end

  pending do
    it_should_behave_like "ActiveModel"
  end
end

