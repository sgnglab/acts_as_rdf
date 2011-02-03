module ActsAsRDF

  ##
  # 実際に利用する時はこのモジュールを組み込んで使用する
  #     class Person
  #       include ActsAsRDF::Resource
  #       has_objects :friends, RDF::FOAF[:Person]
  #     end
  module Resource
    autoload :DSL,              'acts_as_rdf/resource/dsl'
    autoload :ClassMethods,     'acts_as_rdf/resource/class_methods'
    autoload :InstanceMethods,  'acts_as_rdf/resource/instance_methods'
    autoload :ActiveModel,  'acts_as_rdf/resource/active_model'
    
    def self.included(base)
      base.extend DSL
      base.extend ClassMethods
    end

    include Spira::Types
    include ::RDF
    include InstanceMethods
    include ActiveModel
  end
end

