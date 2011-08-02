# -*- coding: utf-8 -*-
module ActsAsRDF
  module Resource
    module Type
      extend ActiveSupport::Concern
      module InstanceMethods
        # @param [Object] value
        # @param [String, Spira::Type] type
        # @param [Boolean] persisted 
        # @return [Object]
        def build_value(value, type, persisted=false)
          case
          when type.respond_to?(:unserialize)
            type.unserialize(value)
          when type.is_a?(String)
            t = eval " #{type}.new(value, context)"
            t._persisted! if persisted
            t
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
      end
    end
  end
end
