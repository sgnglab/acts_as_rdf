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
      
      def get_objects(property, class_name=nil)
        repository.query([uri, property, nil, {:context => context}]).map{|s|
          if class_name
            eval "#{class_name}.new(s.object, context)"
          else
            s.object
            end
        }
      end
       
      def set_objects(property, objects, method_name, class_name=nil) 
        send(method_name).each do |object|
          object = object.uri if class_name
          repository.delete([uri, property, object, {:context => context}])
        end
        objects.each do |object|
          repository.insert([uri, property, object, {:context => context}])
        end
      end
      
      def get_subjects(property, class_name=nil)
        repository.query([nil, property, uri, {:context => context}]).map{|s|
          if class_name
            eval "#{class_name}.new(s.subject, context)"
          else
            s.subject
          end
        }
      end
      
      def set_subjects(property, resources, method_name, class_name=nil)  
        send(method_name).each do |resource|
          resource = resource.uri if class_name
          repository.delete([resource, property, uri, {:context => context}])
        end
        resources.each do |resource|
          repository.insert([resource, property, uri, {:context => context}])
        end
      end
    end
  end
end

