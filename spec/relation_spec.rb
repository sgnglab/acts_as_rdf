# -*- coding: utf-8 -*-
require File.join(File.dirname(__FILE__), 'spec_helper')

# 関連に関する機能のテスト
describe 'ActsAsRDF' do
  before do
    @alice_uri = RDF::URI.new('http://ali.ce')
    @alice_name = RDF::Literal.new('Alice')
    @alice_blog = RDF::URI.new('htt://alice.blog.com')
    
    @bob_uri = RDF::URI.new('http://bob.com')

    @context = RDF::URI.new('http://context.com')

    ActsAsRDF.repository = RDF::Repository.new{|r|
      r << [@alice_uri, RDF::FOAF.name, 'wrong_name']
      r << [@alice_uri, RDF::FOAF.name, @alice_name, @context]
      r << [@alice_uri, RDF::FOAF.homepage, @alice_blog, @context]
      r << [@alice_uri, RDF::FOAF.knows, @bob_uri, @context]
      r << [@alice_uri, RDF.type, RDF::FOAF['Person'], @context]
      r << [@bob_uri, RDF.type, RDF::FOAF['Person'], @context]
      r << [@alice_blog, RDF.type, RDF::FOAF['Document'], @context]
    }
  end

  context 'use has_objects' do
    before do
      class PersonHOS
        include ActsAsRDF::Resource
        define_type RDF::FOAF['Person']
        has_objects :homepages, RDF::FOAF.homepage
        has_objects :names, RDF::FOAF.name, String
        has_objects :people, RDF::FOAF.knows, 'PersonHOS'
      end
      @alice = PersonHOS.find(@alice_uri, @context)
    end

    context 'when getting objects' do
      it "should return array" do
        @alice.names.should  be_instance_of(Array)
        @alice.homepages.should be_instance_of(Array)
        @alice.people.should be_instance_of(Array)
      end
      
      it "should return correct resoueces" do  
        @alice.homepages.size.should be_equal(1)
        @alice.homepages.first.should be_equal(@alice_blog)
      end

      it "should return correct literals" do  
        @alice.names.size.should be_equal(1)
        @alice.names.first.should be_equal(@alice_name.to_s)
      end
      
      it "should return correct resoueces with class" do  
        @alice.people.size.should be_equal(1)
        bob = @alice.people.first
        bob.should be_instance_of(PersonHOS)
        bob.uri.should be_equal(@bob_uri)
        bob.context.should be_equal(@context)
      end
    end

    context 'when setting objects' do
      it 'should update resources' do
        @alice.homepages = [@alice_uri, @bob_uri]
        @alice.homepages.size.should == 2
        @alice.homepages.should include @alice_uri
        @alice.homepages.should include @bob_uri
      end

      it 'should update literals' do
        @alice.names = ['Alice', 'Alice Pleasance Liddell']
        @alice.names.size.should == 2
        @alice.names.should include 'Alice'
        @alice.names.should include 'Alice Pleasance Liddell'
      end

      it 'should update zero-literal' do
        @alice.names = []
        @alice.names.should be_empty
      end

      it 'should update object via Ruby Class' do
        @alice.people = [@alice_uri, @bob_uri].map{|u| Person.new(u ,@context) }
        @alice.people.size.should == 2
        @alice.people.first.should be_instance_of(PersonHOS)
        uris = @alice.people.map{|s| s.uri }
        uris.should include @alice_uri
        uris.should include @bob_uri
      end
    end

    it "should return relations" do
      class PersonHOS2
        include ActsAsRDF::Resource
        define_type RDF::FOAF['Person']
        has_objects :homepages, RDF::FOAF.homepage
      end
      PersonHOS2.relations.should == [:homepages]
      PersonHOS.relations.should == [:homepages, :names, :people]
    end
  end

  context 'use has_object' do
    before do
      class PersonHO
        include ActsAsRDF::Resource
        define_type RDF::FOAF['Person']
        has_object :name, RDF::FOAF.name, String
        has_object :homepage, RDF::FOAF.homepage
        has_object :person, RDF::FOAF.knows, 'PersonHO'
      end
      @alice = PersonHO.find(@alice_uri, @context)
    end

    context 'when getting object' do
      it "should return a correct literal" do  
        @alice.name.should be_instance_of(String)
        @alice.name.should be_equal(@alice_name.to_s)
      end
      
      it "should return correct resoueces" do
        @alice.homepage.should be_instance_of(RDF::URI)
        @alice.homepage.should be_equal(@alice_blog)
      end
      
      it "should return correct resoueces with class" do  
        bob = @alice.person
        bob.should be_instance_of(PersonHO)
        bob.uri.should be_equal(@bob_uri)
        bob.context.should be_equal(@context)
      end
    end

    context 'when setting object' do
      it 'should update object' do
        @alice.homepage = @bob_uri
        @alice.homepage.should == @bob_uri
      end

      it 'should update literals' do
        @alice.name = 'Alice Pleasance Liddell'
        @alice.name.should == 'Alice Pleasance Liddell'
      end

      it 'should update object via Ruby Class' do
        @alice.person = PersonHO.new(@alice_uri ,@context)
        @alice.person.should be_instance_of(PersonHO)
        @alice.person.uri.should == @alice_uri
        @alice.person.context.should == @context
      end
    end
  end

  context 'use has_subjects' do
    before do
      class PersonHSS
        include ActsAsRDF::Resource
        define_type RDF::FOAF['Person']
        has_subjects :people, RDF::FOAF[:knows]
      end
      class BlogHSS
        include ActsAsRDF::Resource
        define_type RDF::FOAF['Document']
        has_subjects :authors, RDF::FOAF[:homepage]
        has_subjects :authors2, RDF::FOAF[:homepage], "PersonHSS"
      end
      @blog = BlogHSS.find(@alice_blog, @context)
    end

    context 'when getting subjects' do
      it "should return array" do
        @blog.authors.should  be_instance_of(Array)
        @blog.authors2.should be_instance_of(Array)
      end

      it "should return correct resources" do
        @blog.authors.size.should be_equal(1)
        @blog.authors.first.should be_equal(@alice_uri)
      end
      
      it "should return correct resoueces with class" do  
        alice = @blog.authors2.first
        alice.should be_instance_of(PersonHSS)
        alice.uri.should be_equal(@alice_uri)
        alice.context.should be_equal(@context)
      end
    end

    context 'when setting subjects' do
      it 'should update resources' do
        @blog.authors = [@alice_uri, @bob_uri]
        @blog.authors.size.should == 2
        @blog.authors.should include @alice_uri
        @blog.authors.should include @bob_uri
      end

      it 'should update object via Ruby Class' do
        @blog.authors2 = [@alice_uri, @bob_uri].map{|u| PersonHSS.new(u, @context) }
        @blog.authors2.size.should == 2
        @blog.authors2.first.should be_instance_of(PersonHSS)
        uris = @blog.authors2.map{|s| s.uri }
        uris.should include @alice_uri
        uris.should include @bob_uri
      end
    end

    it "should return relations" do
      PersonHSS.relations.should == [:people]
      BlogHSS.relations.should == [:authors, :authors2]
    end
  end

  context 'use has_subject' do  
    before do
      class PersonHS
        include ActsAsRDF::Resource
        define_type RDF::FOAF['Person']
        has_subject :person, RDF::FOAF[:knows]
      end
      class BlogHS
        include ActsAsRDF::Resource
        define_type RDF::FOAF['Document']
        has_subject :author, RDF::FOAF.homepage, "PersonHS"
      end
      @bob = PersonHS.find(@bob_uri, @context)
      @blog = BlogHS.find(@alice_blog, @context)
    end
    
    context 'when getting subject' do
      it "should return correct suject" do     
        @bob.person.should be_equal(@alice_uri)
      end
      
      it "should return correct resouece with class" do        
        alice = @blog.author
        alice.should be_instance_of(PersonHS)
        alice.uri.should be_equal(@alice_uri)
        alice.context.should be_equal(@context)
      end
    end

    context 'when setting subject' do
      it 'should update subject' do
        @bob.person = @bob_uri
        @bob.person.should == @bob_uri
      end

      it 'should update subject via Ruby Class' do
        @blog.author = PersonHS.new(@bob_uri, @context)
        @blog.author.should be_instance_of(PersonHS)
        @blog.author.uri.should == @bob_uri
        @blog.author.context.should == @context
      end
    end
  end
  
  context "use has_object and has_subjects" do
    before do
      class PersonHOHSS
        include ActsAsRDF::Resource
        define_type RDF::FOAF['Person']
        has_object :name, RDF::FOAF[:name], String
        has_subjects :known_to, RDF::FOAF[:knows], PersonHOHSS
      end
    end

    it "should return relations" do
      PersonHOHSS.relations.should == [:name, :known_to]
    end
  end
end
