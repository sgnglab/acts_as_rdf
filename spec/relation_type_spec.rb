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
    @alice_age = RDF::Literal.new('20', :datatype => RDF::XSD.integer)
    
    @bob_uri = RDF::URI.new('http://bob.com')

    @context = RDF::URI.new('http://context.com')

    ActsAsRDF.repository = RDF::Repository.new{|r|
      r << [@alice_uri, RDF::FOAF.name, 'wrong_name']
      r << [@alice_uri, RDF::FOAF.name, @alice_name, @context]
      r << [@alice_uri, RDF::FOAF.homepage, @alice_blog, @context]
      r << [@alice_uri, RDF::FOAF.age, @alice_age, @context]
      r << [@alice_uri, RDF.type, RDF::FOAF['Person'], @context]
      r << [@bob_uri, RDF.type, RDF::FOAF['Person'], @context]
    }
  end

  context 'with relation type' do
    before { @alice = PersonT.find(@alice_uri, @context) }

    describe Spira::Types::String do
      subject { @alice.name }

      it { should be_instance_of(String) }
      it { should == @alice_name.to_s }
        
      context "update" do
        subject do
          @alice.name = "AAA"
          @alice.name
        end

        it { should be_instance_of(String) }
        it { should == "AAA" }
      end
    end

    describe Spira::Types::Integer do
      subject { @alice.age }

      it { should be_instance_of(Fixnum) }
      it { should == @alice_age.to_s.to_i }

      context "update" do
        subject do
          @alice.age = 40
          @alice.age
        end

        it { should be_instance_of(Fixnum) }
        it { should == 40 }
      end
    end
  end
end
