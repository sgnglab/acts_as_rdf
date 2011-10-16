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

  describe '#find' do
    subject do
      class PersonFind
        include ActsAsRDF::Resource
        define_type RDF::FOAF['Person'] 
      end
      PersonFind
    end
    
    it "can call find method" do
      subject.find(@alice_uri, @context).should be_instance_of subject
      subject.find(RDF::FOAF.name, @context).should be_instance_of NilClass
    end
    
    it "cannot call find method" do
      lambda{ subject.find }.should raise_error(ArgumentError)
      lambda{ subject.find(@alice_uri) }.should raise_error(ArgumentError)
    end
  end

  context 'find_by_id' do
    before do
      class PersonFindByID
        include ActsAsRDF::Resource
        define_type RDF::FOAF['Person'] 
      end
      @alice_encode_uri = PersonFindByID.encode_uri(@alice_uri)
    end

    subject { PersonFindByID }

    it "can call find method" do
      subject.find_by_id(@alice_encode_uri, @context).should be_instance_of PersonFindByID
      subject.find_by_id(PersonFindByID.encode_uri(RDF::FOAF.name), @context).should be_instance_of NilClass
    end

    it "cannot call find method" do
      lambda{ subject.find_by_id }.should raise_error(ArgumentError)
      lambda{ subject.find_by_id(@alice_encode_uri) }.should raise_error(ArgumentError)
    end
  end
  
  describe '.create' do
    it 'should create resource' do
      person = PersonA.create(@context)
      person.should be_instance_of PersonA
      res = PersonA.find(person.uri, @context)
      res.should be_true
    end
    it 'should not create resource' do
      lambda{ PersonFind.create }.should raise_error(ArgumentError)
    end
  end

  describe '#persisted' do
    it { PersonA.create(@context).persisted?.should be_true }
    it { PersonA.new(@context,@context).persisted?.should be_false }
    it { PersonA.find(@alice_uri,@context).persisted?.should be_true }
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
