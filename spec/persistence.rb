# -*- coding: utf-8 -*-
require File.join(File.dirname(__FILE__), 'spec_helper')

# 永続化に関するテスト
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

    class PersonUpdate
      include ActsAsRDF::Resource
      
      define_type RDF::FOAF['Person']
      has_object :name, RDF::FOAF[:name], String
      has_subjects :known_to, RDF::FOAF[:knows], "PersonUpdate"
      
      init_attribute_methods
    end
  end

  describe '.create' do
    it 'should create resource' do
      person = PersonA.create(@context)
      person.should be_instance_of PersonA
      res = PersonA.find(person.uri, @context)
      res.should be_true
    end
    it 'should create resource' do
      person = PersonA.create
      person.uri.should be_instance_of RDF::URI
      person.context.should be_nil
    end
  end

  describe '#persisted' do
    context "only create instance" do
      it { PersonA.create(@context).persisted?.should be_true }
      it { PersonA.new(@context,@context).persisted?.should be_false }
      it { PersonA.find(@alice_uri,@context).persisted?.should be_true }
    end

    context "create instance and change property" do
      it "should not change persisted?" do
        bob = PersonA.new(ActsAsRDF.uniq_uri, @context)
        bob.persisted?.should be_false
        bob.uri = RDF::URI("http://a.com")
        bob.persisted?.should be_false
      end
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

  describe '#save' do
    before do
      @bob_uri = RDF::URI.new('http://bob.com')
    end

    context 'if you specify a uri' do
      it "should save resource" do
        bob = PersonUpdate.new(@bob_uri, @context)
        bob.save
        bob_ = PersonUpdate.find(@bob_uri, @context)
        bob_.should be_instance_of PersonUpdate
        bob_.uri.should === @bob_uri
        bob_.context.should == @context
      end
      
      it "should save resource" do
        bob = PersonUpdate.new(@bob_uri, @context)
        bob.name = 'bob'
        bob.save
        bob_ = PersonUpdate.find(@bob_uri, @context)
        bob_.should be_instance_of PersonUpdate
        bob.context.should be_equal @context
        bob_.name.should == 'bob'
      end
    end

    context 'if you do not specify a uri' do
      it "is set uniq uri" do
        bob = PersonUpdate.new
        bob.save
        bob.uri.should be_instance_of RDF::URI
        bob.context.should be_nil
      end
    end
  end

  context "load" do
    it "should not return cache if reloaded" do
      alice = PersonUpdate.find(@alice_uri, @context)
      name = alice.name
      alice.name = "a"
      alice.name.should == "a"
      alice.load
      alice.name.should == name
    end
    
    it "should update" do
      alice = PersonUpdate.find(@alice_uri, @context)
      name = alice.name
      alice.name = "a"
      alice.save
      alice.name = "b"
      alice.name.should == "b"
      alice.load
      alice.name.should == "a"
    end

    it "can call load when it is not persised" do
      alice = PersonUpdate.new(@alice_uri, @context)
      alice.load
      alice.name.should be_equal(@alice_name.to_s)
      alice.known_to.first.uri.to_s.should be_equal(@bob_uri.to_s)
      alice.known_to.first.name.to_s.should be_equal(@bob_name.to_s)
    end

    it "can call load when it is accessed its attribute" do
      alice = PersonUpdate.new(@alice_uri, @context)
      alice.name.should be_nil
      alice.known_to.should be_empty
      alice._persisted!
      alice.name.should be_equal(@alice_name.to_s)
      alice.known_to.first.uri.should be_equal(@bob_uri)
    end

    it "can call load when it is accessed its attribute" do
      PersonUpdate.find(@alice_uri, @context).known_to.first.uri.to_s.should be_equal(@bob_uri.to_s);
      PersonUpdate.find(@alice_uri, @context).known_to.first.name.should be_equal(@bob_name.to_s);
      PersonUpdate.find(@alice_uri, @context).known_to.first.known_to.first.
        name.should be_equal(@alice_name.to_s);
    end
  end

  describe "#update_attributes" do
    before do
      class PersonUpdateAttributes
        include ActsAsRDF::Resource
        define_type RDF::FOAF['Person']
        
        has_object :name, RDF::FOAF[:name], String
        has_subjects :knows, RDF::FOAF[:knows]
        
        init_attribute_methods
      end
    end
    it "should update attributes" do
      person = PersonUpdateAttributes.new(@alice_uri, @context)
      person.save
      person.update_attributes(:name => "Alice").should be_true
      get = PersonUpdateAttributes.find(@alice_uri, @context)
      get.name.should eq "Alice"
    end
  end

end
