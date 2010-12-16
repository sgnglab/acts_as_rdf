require File.join(File.dirname(__FILE__), 'spec_helper')

include ActsAsRDF

describe 'ActsAsRDF' do
  before do
    class Person
      acts_as_rdf
    end
    @uri = RDF::URI.new('http://example.com')
  end

  it "should convert uri" do
    Person.encode_uri(@uri).should be_true
  end
  
  it "should be not created" do
    lambda{ Person.new }.should raise_error(ArgumentError)
  end

  it "should be created" do
    Person.new(@uri, @uri).should be_true
  end
end
