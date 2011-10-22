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

  describe '.delete' do
    before do
      class PersonDeleteClass
        include ActsAsRDF::Resource
        define_type RDF::FOAF['Person']
        
        init_attribute_methods
      end
    end

    it "should delete object" do
      PersonDeleteClass.delete(@alice_uri, @context)
      PersonDeleteClass.find(@alice_uri, @context).should be_nil
    end
  end

  describe '#delete' do
    before do
      class PersonDeleteInstance
        include ActsAsRDF::Resource
        define_type RDF::FOAF['Person']
        
        init_attribute_methods
      end
    end

    context "resouce is in the repository" do
      subject {
        alice = PersonDeleteClass.find(@alice_uri, @context)
        alice.delete
        alice
      }

      its(:persisted?) {should be_false }

      it "cannnot be found" do
        PersonDeleteClass.find(subject.uri, @context).should be_nil
      end
    end

    context "resouce is in the repository with another context" do
      before do
        another_context = RDF::URI('http://ano.ther/')
        @another_alice = PersonDeleteClass.new(@alice_uri, another_context)
        @another_alice.save
        @alice = PersonDeleteClass.find(@alice_uri, @context)
        @alice.delete
      end
      subject { @alice }

      its(:persisted?) {should be_false }

      it "cannnot be found" do
        PersonDeleteClass.find( subject.uri, subject.context).should be_nil
      end

      context "resouce is in the another context" do
        subject { @another_alice }
        
        its(:persisted?) { should be_true }
        
        it "can be found" do
          PersonDeleteClass.find(subject.uri, subject.context).should be_true
        end
      end
    end

    context "resouce is not in the repository" do
      subject do
        bob = PersonDeleteClass.new(RDF::URI.new('http://bo.b/'), @context)
        bob.delete
        bob
      end

      its(:persisted?) { should be_false }
      
      it "cannot be found" do
        PersonDeleteClass.find(subject.uri, subject.context).should be_nil
      end
    end
  end
end
