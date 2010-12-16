require File.join(File.dirname(__FILE__), 'spec_helper')

include ActsAsRDF

describe 'ActsAsRDF' do
  before do
    class Person
      acts_as_rdf
    end
  end

  it "should create" do
    Person.new.should be_true
  end
end
