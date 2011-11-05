# -*- coding: utf-8 -*-
require File.join(File.dirname(__FILE__), 'spec_helper')

# 基本的な機能のテスト
describe 'ActsAsRDF' do
  before do
    @alice_uri = RDF::URI.new('http://ali.ce')
    @alice_name = RDF::Literal.new('Alice')

    @context = RDF::URI.new('http://context.com')

    ActsAsRDF.repository = RDF::Repository.new{|r|
      r << [@alice_uri, RDF::FOAF.name, 'wrong_name']
      r << [@alice_uri, RDF::FOAF.name, @alice_name, @context]
      r << [@alice_uri, RDF.type, RDF::FOAF['Person'], @context]
    }

    class PersonA
      include ActsAsRDF::Resource
      define_type RDF::FOAF['Person']

      init_attribute_methods
    end
  end

  describe "#id" do
    context "it saved" do
      before do
        @alice = PersonA.find(@alice_uri, @context)
      end
      subject { @alice.id }
      
      it { should_not be_empty }
      it { should eq PersonA.encode_uri(@alice_uri) }
      it { should eq @alice.encode_uri }
    end

    context "it didn't save" do
      before do
        @alice = PersonA.new(@alice_uri, @context)
      end
      subject { @alice.id }

      it { should_not be_empty }
      it { should eq PersonA.encode_uri(@alice_uri) }
      it { should eq @alice.encode_uri }
    end
  end

  describe "#new" do
    before do
      class PersonNew
        include ActsAsRDF::Resource
        define_type RDF::FOAF['Person']

        has_object :name, RDF::FOAF[:name], String
        
        init_attribute_methods
      end
    end

    context "Argument => ()" do
      subject { PersonNew.new() }

      its(:id) { should be_nil }
      its(:uri) { should be_nil }
      its(:context) { should be_nil }
      its(:name) { should be_nil }
    end

    context "Argument => (URI)" do
      subject { PersonNew.new(@alice_uri) }

      its(:id) { should eq Person.encode_uri(@alice_uri) }
      its(:uri) { should be(@alice_uri) }
      its(:context) { should be_nil }
      its(:name) { should be_nil }
    end

    context "Argument => (URI, URI)" do
      subject { PersonNew.new(@alice_uri, @context) }

      its(:id) { should eq PersonNew.encode_uri(@alice_uri) }
      its(:uri) { should be(@alice_uri) }
      its(:context) { should be(@context) }
      its(:name) { should be_nil }
    end

    context "Argument => (Hash{})" do
      subject { PersonNew.new({}) }

      its(:id) { should be_nil }
      its(:uri) { should be_nil }
      its(:context) { should be_nil }
      its(:name) { should be_nil }
    end

    context "Argument => (Hash{uri, context})" do
      subject { PersonNew.new({:uri => @alice_uri, :context => @context}) }

      its(:id) { should eq PersonNew.encode_uri(@alice_uri) }
      its(:uri) { should be(@alice_uri) }
      its(:context) { should be(@context) }
      its(:name) { should be_nil }
    end

    context "Argument => (Hash{uri, name})" do
      subject { PersonNew.new({:uri => @alice_uri, :name => "alice"}) }

      its(:id) { should eq PersonNew.encode_uri(@alice_uri) }
      its(:uri) { should be(@alice_uri) }
      its(:context) { should be_nil }
      its(:name) { should eq "alice" }
    end

    context "Argument => (Hash{uri, invalid_name})" do
      it "should raise Error" do
        expect{
          PersonNew.new(:uri => @alice_uri, :invalid_name => "ii")
        }.to raise_error(NoMethodError)
      end
    end
  end

  describe '.repository' do
    it "should has repository" do
      rep = ActsAsRDF.repository
      rep.should be_instance_of RDF::Repository
      rep.has_statement?(
        RDF::Statement.new(@alice_uri, RDF::FOAF.name, @alice_name, :context => @context)).should be_true

      rep.should == ActsAsRDF.repository
    end
    
    it "should have kind of repository" do
      class MyRepository < RDF::Repository; end
      ActsAsRDF.repository = MyRepository.new
    end

    it "should not have kind of non-repository" do
      class NotRepository ; end
      expect { ActsAsRDF.repository = NotRepository.new }.to raise_error
    end

    it "cant change repository" do
      alice = PersonA.find(@alice_uri, @context)
      ActsAsRDF.repository = RDF::Repository.new
      alice.uri.should == @alice_uri
      alice.context.should == @context
    end
  end

  describe '#type' do
    context "if it didn't define the type"do
      subject do
        class NoType
          include ActsAsRDF::Resource
        end
      end

      it "raises error" do
        expect { subject.type }.to raise_error(ActsAsRDF::NoTypeError)
      end
    end
    
    context "if it defined the type"do
      before do
        class Person3
          include ActsAsRDF::Resource
          define_type RDF::FOAF['Person3']
        end
      end

      it "get type" do
        Person3.type.should == RDF::FOAF['Person3']
      end
    end
  end

  describe '#uniq_uri' do
    it "should return RDF:URI" do
      ActsAsRDF.uniq_uri.should be_instance_of(RDF::URI)
    end

    it "should return new uniq uri if uri confricted" do
      module ActsAsRDF
        @@rand_place = 1
      end
      uri1 = ActsAsRDF.uniq_uri
      ActsAsRDF.repository.insert([uri1, RDF.type, RDF::FOAF['Document']])
      ActsAsRDF.uniq_uri.should_not == uri1
    end
  end
end
