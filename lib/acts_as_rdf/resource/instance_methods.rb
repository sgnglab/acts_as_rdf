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
        if type.is_a?(String)
          eval "#{type}.new(value, context)"
        else
          value
        end
      end

      def build_rdf_value(value, type)
        if type.is_a?(String)
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
       
      def set_objects(property, objects, method_name, type=nil) 
        send(method_name).each do |object|
          object = build_rdf_value(object, type)
          repository.delete([uri, property, object, {:context => context}])
        end
        objects.each do |object|
          object = build_rdf_value(object, type)
          repository.insert([uri, property, object, {:context => context}])
        end
      end
      
      def get_subjects(property, type=nil, opt={:single=>false})
        subj = repository.query([nil, property, uri, {:context => context}]).map{|s|
          build_value(s.subject, type)
        }
        opt[:single] ? subj.first : subj
      end
      
      def set_subjects(property, resources, method_name, type=nil)  
        send(method_name).each do |resource|
          resource = build_rdf_value(resource, type)
          repository.delete([resource, property, uri, {:context => context}])
        end
        resources.each do |resource|
          resource = build_rdf_value(resource, type)
          repository.insert([resource, property, uri, {:context => context}])
        end
      end
    end
  end
end

