# -*- coding: utf-8 -*-
module ActsAsRDF
  module Resource
    module InstanceMethods
      # このクラスのURI
      attr_accessor :uri
      # このクラスのContext
      attr_accessor :context

      # RDFのリソースであるクラスを生成する
      #      project = RDF::URI.new('http://project.com/')
      #      ActsAsRDF.new(RDF::URI.new('http://project.com/one_page'), project.context)
      #
      # @param [RDF::URI] uri
      # @param [RDF::URI] context (メタデータシステムの場合、通常は Project#context の値)
      # @return [self]
      def initialize(uri, context)
        raise unless uri && context
        @uri = uri
        @context = context
      end

      # URIを16進文字列で表現した文字列を返す
      #
      # @return [String]
      def encode_uri
        self.class.encode_uri(uri)
      end

      #
      # @return [RDF::Repository]
      def repository
        self.class.repository
      end

      # @param [Object] value
      # @param [String, Spira::Type] type
      # @return [Object]
      def build_value(value, type)
        case
        when type.respond_to?(:unserialize)
          type.unserialize(value)
        when type.is_a?(String)
          eval "#{type}.new(value, context)"
        else
          value
        end
      end

      # @param [Object] value
      # @param [String, Spira::Type] type
      # @return [RDF::URI, RDF::Literal]
      def build_rdf_value(value, type)
        case
        when type.respond_to?(:serialize)
          type.serialize(value)
        when type.is_a?(String)
          value.uri
        else
          value
        end
      end

      # @param [RDF::URI] property
      # @param [String, Spira::Type] type
      # @param [Hash] opt
      # @return [Object]
      def get_objects(property, type=nil, opt={:single=>false})
        obj = repository.query([uri, property, nil, context]).map{|s|
          build_value(s.object, type)
        }
        opt[:single] ? obj.first : obj
      end
       
      # @param [RDF::URI] property
      # @param [Object] objects
      # @param [String, Spira::Type] type
      # @param [Hash] opt
      def set_objects(property, objects, method_name, type=nil, opt={:single=>false})
        delete_objects(property)
        if opt[:single]
          object = build_rdf_value(objects, type)
          repository.insert([uri, property, object, context])
        else
          objects.each do |object|
            object = build_rdf_value(object, type)
            repository.insert([uri, property, object, context])
          end
        end
      end

      # @param [RDF::URI] property
      def delete_objects(property)
        repository.delete([uri, property, nil, context])
      end

      # @param [RDF::URI] property
      # @param [String, Spira::Type] type
      # @param [Hash] opt
      # @return [Object]
      def get_subjects(property, type=nil, opt={:single=>false})
        subj = repository.query([nil, property, uri, context]).map{|s|
          build_value(s.subject, type)
        }
        opt[:single] ? subj.first : subj
      end
 
      # @param [RDF::URI] property
      # @param [Object] resouces
      # @param [String, Spira::Type] type
      # @param [Hash] opt
      def set_subjects(property, resources, method_name, type=nil, opt={:single=>false})  
        delete_subjects(property)
        if opt[:single]
          resource = build_rdf_value(resources, type)
          repository.insert([resource, property, uri, context])
        else
          resources.each do |resource|
            resource = build_rdf_value(resource, type)
            repository.insert([resource, property, uri, context])
          end
        end
      end

      # @param [RDF::URI] property
      def delete_subjects(property)
        repository.delete([nil, property, uri, context])
      end
    end
  end
end

