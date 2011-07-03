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

      init_attributes_methods
    end
  end

  it "should be return serialized uri" do
    alice = PersonA.find(@alice_uri, @context)
    alice.id.should == PersonA.encode_uri(@alice_uri)
    alice.id.should == alice.encode_uri
  end

  context 'setting repository' do
    it "should has repository" do
      rep = ActsAsRDF.repository
      rep.should be_instance_of RDF::Repository
      rep.has_statement?(
        RDF::Statement.new(@alice_uri, RDF::FOAF.name, @alice_name, :context => @context)).should be_true

      rep.should == ActsAsRDF.repository
    end
    
    it "should has kind of repository" do
      class MyRepository < RDF::Repository; end
      ActsAsRDF.repository = MyRepository.new
    end
  end

  context 'set type' do
    context "if it didn't define type"do
      it "raises error" do
        class NoType
          include ActsAsRDF::Resource
        end
        lambda{ NoType.type }.should raise_error(ActsAsRDF::NoTypeError)
      end
    end

    it "can set type" do
#      Person.find(@alice_uri, @context).type.should be_instance_of RDF::URI
      class Person3
        include ActsAsRDF::Resource
        define_type RDF::FOAF['Person3']
      end
      class Person2
        include ActsAsRDF::Resource
        define_type RDF::FOAF['Person2']
      end
      Person3.type.should == RDF::FOAF['Person3']
    end
  end

  context 'find' do
    before do
      class PersonFind
        include ActsAsRDF::Resource
        define_type RDF::FOAF['Person'] 
      end
    end
    
    it "can call find method" do
      PersonFind.find(@alice_uri, @context).should be_instance_of PersonFind
      PersonFind.find(RDF::FOAF.name, @context).should be_instance_of NilClass
    end
    
    it "cannot call find method" do
      lambda{ PersonFind.find }.should raise_error(ArgumentError)
      lambda{ PersonFind.find(@alice_uri) }.should raise_error(ArgumentError)
    end   
  end
  
  context 'create resource' do
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

  context '#persisted' do
    it { PersonA.create(@context).persisted?.should be_true }
    it { PersonA.new(@context,@context).persisted?.should be_false }
  end

  context 'generate uniq_uri' do
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
