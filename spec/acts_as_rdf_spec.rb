require File.join(File.dirname(__FILE__), 'spec_helper')

include ActsAsRDF

describe 'ActsAsRDF' do
  before do
    @uri = RDF::URI.new('http://example.com')
    @context = RDF::URI.new('http://context.com')
    @literal = RDF::Literal.new('obj')
    @literal2 = RDF::Literal.new('context2')
    @resource = RDF::URI.new('http://hoge.com')

    repository = RDF::Repository.new 
    repository << RDF::Statement.new(@uri, RDF::FOAF["name"], @literal)
    repository << RDF::Statement.new(@uri, RDF::FOAF["name"], @literal2, :context => @context)
    repository << RDF::Statement.new(@uri, RDF::FOAF["knows"], @resource, :context => @context)
    ActsAsRDF.repository = repository

    class Person
      acts_as_rdf
    end

  end

  it "should convert uri" do
    Person.encode_uri(@uri).should be_true
  end
  
  it "should be not created" do
    lambda{ Person.new }.should raise_error(ArgumentError)
  end

  it "should be created" do
    Person.new(@uri, @context).should be_true
  end

  it "should use has_literals" do
    class Person2
      acts_as_rdf
      has_objects :names, RDF::FOAF[:name]
    end
    Person2.new(@uri,@context).names.should be_instance_of(Array)
  end

  it "should return correct literals" do  
    class Person2
      acts_as_rdf
      has_objects :names, RDF::FOAF[:name]
    end

    person2 = Person2.new(@uri,@context)
    person2.names.first.should be_equal(@literal2)
    person2.names.size.should be_equal(1)
  end

  it "should use has_resources" do
    class Person3
      acts_as_rdf
      has_objects :people, RDF::FOAF[:knows]
    end
    Person3.new(@uri,@context).people.should be_instance_of(Array)
  end

  it "should return correct resoueces" do  
    class Person3
      acts_as_rdf
      has_objects :people, RDF::FOAF[:knows]
    end

    person3 = Person3.new(@uri,@context)
    person3.people.first.should be_equal(@resource)
    person3.people.size.should be_equal(1)
  end

  it "should return correct resoueces with class" do  
    class Person3
      acts_as_rdf
      has_objects :people, RDF::FOAF[:knows], "Person"
    end
    person3 = Person3.new(@uri, @context)
    person = person3.people.first
    person.should be_instance_of(Person)
    person.uri.should be_equal(@resource)
    person.context.should be_equal(@context)
  end

  it "should return correct sujects" do  
    class Person3
      acts_as_rdf
      has_subjects :people, RDF::FOAF[:knows]
    end

    person3 = Person3.new(@resource,@context)
    person3.people.first.should be_equal(@uri)
    person3.people.size.should be_equal(1)
  end

  it "should return correct resoueces with class" do  
    class Person3
      acts_as_rdf
      has_subjects :people, RDF::FOAF[:knows], "Person"
    end
    person3 = Person3.new(@resource, @context)
    person = person3.people.first
    person.should be_instance_of(Person)
    person.uri.should be_equal(@uri)
    person.context.should be_equal(@context)
  end

  it "should has repository" do
    Person.repository.should be_instance_of RDF::Repository
    Person.repository.has_statement?(RDF::Statement.new(RDF::URI.new('http://example.com'), RDF::FOAF["name"], "obj")).should be_true

    class Person2
      acts_as_rdf
    end
    Person.repository.should == Person2.repository
  end

end
