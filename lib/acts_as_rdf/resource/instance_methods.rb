module ActsAsRDF
  module Resource
    module InstanceMethods
      attr_accessor :uri, :context
      # RDFのリソースであるクラスを生成する
      #  project = RDF::URI.new('http://project.com/')
      #  RDFModel.new(RDF::URI.new('http://project.com/one_page'), project.context)
      #
      # === 引数
      # +uri+::
      #  RDF::URI
      # +context+::
      #  RDF::URI (通常は Project#context の値)
      #
      # === 返り値
      # RDFModel
      def initialize(uri, context)
        raise unless uri && context
        @uri = uri
        @context = context
      end
      
      # URIを16進文字列で表現した文字列を返す
      #
      # === 返り値
      #  String
      def encode_uri
        self.class.encode_uri(uri)
      end
      
      def repository
        self.class.repository
      end

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
      
      def get_objects(property, type=nil, opt={:single=>false})
        obj = repository.query([uri, property, nil, {:context => context}]).map{|s|
          build_value(s.object, type)
        }
        opt[:single] ? obj.first : obj
      end
       
      def set_objects(property, objects, method_name, type=nil, opt={:single=>false})
        delete_objects(property)
        if opt[:single]
          object = build_rdf_value(objects, type)
          repository.insert([uri, property, object, {:context => context}])
        else
          objects.each do |object|
            object = build_rdf_value(object, type)
            repository.insert([uri, property, object, {:context => context}])
          end
        end
      end

      def delete_objects(property)
        repository.delete([uri, property, nil, {:context => context}])
      end

      def get_subjects(property, type=nil, opt={:single=>false})
        subj = repository.query([nil, property, uri, {:context => context}]).map{|s|
          build_value(s.subject, type)
        }
        opt[:single] ? subj.first : subj
      end
      
      def set_subjects(property, resources, method_name, type=nil, opt={:single=>false})  
        delete_subjects(property)
#        send(method_name).each do |resource|
#          resource = build_rdf_value(resource, type)
#          repository.delete([resource, property, uri, {:context => context}])
#        end
        if opt[:single]
          resource = build_rdf_value(resources, type)
          repository.insert([resource, property, uri, {:context => context}])
        else
          resources.each do |resource|
            resource = build_rdf_value(resource, type)
            repository.insert([resource, property, uri, {:context => context}])
          end
        end
      end

      def delete_subjects(property)
        repository.delete([nil, property, uri, {:context => context}])
      end
    end
  end
end

