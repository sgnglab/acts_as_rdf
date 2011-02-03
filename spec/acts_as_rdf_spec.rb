require File.join(File.dirname(__FILE__), 'spec_helper')

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
      r << [@alice_uri, RDF.type, RDF::FOAF['Person'], {:context => @context}]
      r << [@bob_uri, RDF.type, RDF::FOAF['Person'], {:context => @context}]
      r << [@alice_blog, RDF.type, RDF::FOAF['Document'], {:context => @context}]
    }
    
    class Person
      include ActsAsRDF::Resource
      define_type RDF::FOAF['Person']
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

  context 'type' do
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
    Person.find(@alice_uri, @context).should be_true
  end

  it "should be not created" do
    lambda{ Person.find }.should raise_error(ArgumentError)
    lambda{ Person.find(@alice_uri) }.should raise_error(ArgumentError)
  end

  it "should be return serialized uri" do
    alice = Person.find(@alice_uri, @context)
    alice.id.should == Person.encode_uri(@alice_uri)
    alice.id.should == alice.encode_uri
  end

  context 'use has_objects' do
    before do
      class Person2
        include ActsAsRDF::Resource
        define_type RDF::FOAF['Person']
        has_objects :names, RDF::FOAF.name
        has_objects :homepages, RDF::FOAF.homepage
        has_objects :people, RDF::FOAF.knows, 'Person'
      end
      @alice = Person2.find(@alice_uri, @context)
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

  context 'use has_object' do
    before do
      class Person2
        include ActsAsRDF::Resource
        define_type RDF::FOAF['Person']
        has_object :name, RDF::FOAF.name
        has_object :homepage, RDF::FOAF.homepage
        has_object :person, RDF::FOAF.knows, 'Person'
      end
      @alice = Person2.find(@alice_uri, @context)
    end

    it "should return correct literals" do  
      @alice.name.should be_instance_of(RDF::Literal)
      @alice.name.should be_equal(@alice_name)
    end
    
    it "should return correct resoueces" do
      @alice.homepage.should be_instance_of(RDF::URI)
      @alice.homepage.should be_equal(@alice_blog)
    end
    
    it "should return correct resoueces with class" do  
      bob = @alice.person
      bob.should be_instance_of(Person)
      bob.uri.should be_equal(@bob_uri)
      bob.context.should be_equal(@context)
    end
  end

  context 'use has_subjects' do  
    it "should return correct sujects" do  
      class Person3
        include ActsAsRDF::Resource
        define_type RDF::FOAF['Person']
        has_subjects :people, RDF::FOAF[:knows]
      end

      bob = Person3.find(@bob_uri, @context)
      bob.people.first.should be_equal(@alice_uri)
      bob.people.size.should be_equal(1)
    end
    
    it "should return correct resoueces with class" do  
      class Blog
        include ActsAsRDF::Resource
        define_type RDF::FOAF['Document']
        has_subjects :authors, RDF::FOAF.homepage, "Person"
      end

      blog = Blog.find(@alice_blog, @context)
      alice = blog.authors.first
      alice.should be_instance_of(Person)
      alice.uri.should be_equal(@alice_uri)
      alice.context.should be_equal(@context)
    end
  end

  context 'use has_subject' do  
    it "should return correct suject" do  
      class Person3
        include ActsAsRDF::Resource
        define_type RDF::FOAF['Person']
        has_subject :person, RDF::FOAF[:knows]
      end

      bob = Person3.find(@bob_uri, @context)
      bob.person.should be_equal(@alice_uri)
    end
    
    it "should return correct resouece with class" do  
      class Blog
        include ActsAsRDF::Resource
        define_type RDF::FOAF['Document']
        has_subject :author, RDF::FOAF.homepage, "Person"
      end

      blog = Blog.find(@alice_blog, @context)
      alice = blog.author
      alice.should be_instance_of(Person)
      alice.uri.should be_equal(@alice_uri)
      alice.context.should be_equal(@context)
    end
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

  context 'create resource' do
    it 'should create resource' do
      person = Person.create(@context)
      person.should be_instance_of Person
      res = Person.find(person.uri, @context)
      res.should be_true
    end
    it 'should not create resource' do
      lambda{ PersonFind.create }.should raise_error(ArgumentError)
    end
  end

  context 'update resource' do
    before do
      class Person
        include ActsAsRDF::Resource
        define_type RDF::FOAF['Person']
        has_objects :people, RDF::FOAF[:knows]
      end
      class Blog
        include ActsAsRDF::Resource
        define_type RDF::FOAF['Document']
        has_subjects :authors, RDF::FOAF[:homepage]
      end
    end
    it 'should update subject' do
      alice = Person.find(@alice_uri,@context)
      alice_people = alice.people
      alice.people = [@alice_uri, @bob_uri]
      alice.people.size.should == 2
      alice.people.should include @alice_uri
      alice.people.should include @bob_uri
    end
    it 'should update subject' do
      blog = Blog.find(@alice_blog,@context)
      blog.authors = [@alice_uri, @bob_uri]
      blog.authors.size.should == 2
      blog.authors.should include @alice_uri
      blog.authors.should include @bob_uri
    end
  end
end
