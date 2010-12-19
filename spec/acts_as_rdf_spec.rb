require File.join(File.dirname(__FILE__), 'spec_helper')

include ActsAsRDF

describe 'ActsAsRDF' do
  before do
    @alice_uri = RDF::URI.new('http://ali.ce')
    @alice_name = RDF::Literal.new('Alice')
    @alice_blog = RDF::URI.new('htt://alice.blog.com')
    
    @bob_uri = RDF::URI.new('http://bob.com')

    @context = RDF::URI.new('http://context.com')

    ActsAsRDF.repository = RDF::Repository.new{|r|
      r << [@alice_uri, RDF::FOAF.name, 'wrong_name']
      r << [@alice_uri, RDF::FOAF.name, @alice_name, {:context => @context}]
      r << [@alice_uri, RDF::FOAF.homepage, @alice_blog, {:context => @context}]
      r << [@alice_uri, RDF::FOAF.knows, @bob_uri, {:context => @context}]
    }
    
    class Person
      acts_as_rdf
    end

  end

  it "should has repository" do
    rep = ActsAsRDF.repository
    rep.should be_instance_of RDF::Repository
    rep.has_statement?(
      RDF::Statement.new(@alice_uri, RDF::FOAF.name, @alice_name, :context => @context)).should be_true

    rep.should == Person.repository
  end

  it "should has kind of repository" do
    class MyRepository < RDF::Repository; end
    ActsAsRDF.repository = MyRepository.new
  end

  it "should be created" do
    Person.new(@alice_uri, @context).should be_true
  end

  it "should be not created" do
    lambda{ Person.new }.should raise_error(ArgumentError)
    lambda{ Person.new(@alice_uri) }.should raise_error(ArgumentError)
  end

  it "should be return serialized uri" do
    alice = Person.new(@alice_uri, @context)
    alice.id.should == Person.encode_uri(@alice_uri)
    alice.id.should == alice.encode_uri
  end

  context 'not only repository' do
    before do
      class Person1
        acts_as_rdf :only_repository => false
      end
      @alice = Person1.new
      @alice.uri = @alice_uri
      @alice.context = @context
    end

    it 'return object_id' do
      @alice.id.should_not == Person1.encode_uri(@alice_uri)
      @alice.id.should_not == @alice.encode_uri
    end
  end
  
  context 'use has_objects' do
    before do
      class Person2
        acts_as_rdf
        has_objects :names, RDF::FOAF.name
        has_objects :homepages, RDF::FOAF.homepage
        has_objects :people, RDF::FOAF.knows, 'Person'
      end
      @alice = Person2.new(@alice_uri, @context)
    end

    it "should return array" do
      @alice.names.should  be_instance_of(Array)
      @alice.homepages.should be_instance_of(Array)
      @alice.people.should be_instance_of(Array)
    end
    
    it "should return correct literals" do  
      @alice.names.size.should be_equal(1)
      @alice.names.first.should be_equal(@alice_name)
    end
    
    it "should return correct resoueces" do  
      @alice.homepages.size.should be_equal(1)
      @alice.homepages.first.should be_equal(@alice_blog)
    end
    
    it "should return correct resoueces with class" do  
      bob = @alice.people.first
      bob.should be_instance_of(Person)
      bob.uri.should be_equal(@bob_uri)
      bob.context.should be_equal(@context)
    end
  end

  context 'use has_subjects' do  
    it "should return correct sujects" do  
      class Person3
        acts_as_rdf
        has_subjects :people, RDF::FOAF[:knows]
      end

      bob = Person3.new(@bob_uri, @context)
      bob.people.first.should be_equal(@alice_uri)
      bob.people.size.should be_equal(1)
    end
    
    it "should return correct resoueces with class" do  
      class Blog
        acts_as_rdf
        has_subjects :authors, RDF::FOAF.homepage, "Person"
      end

      blog = Blog.new(@alice_blog, @context)
      alice = blog.authors.first
      alice.should be_instance_of(Person)
      alice.uri.should be_equal(@alice_uri)
      alice.context.should be_equal(@context)
    end
  end
end
