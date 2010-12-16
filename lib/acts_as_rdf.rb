module ActsAsRDF

  def self.included(base)
    base.extend ClassMethods
    base.class_eval do
      include InstanceMethods
    end
  end

  @@repository = nil

  def repository
    @@repository
  end

  def repository=(repository)
    raise unless repository.instance_of?(RDF::Repository)
    @@repository = repository
  end

  module ClassMethods
    def acts_as_rdf
      class_eval <<-STUFF
      attr_reader :uri, :context
      
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
    STUFF
    end

    # RDFのリソースであるクラスを生成する
    #
    # === 引数
    # +id_str+::
    #  String (URIを16進文字列で表現した文字列)
    # +context+::
    #  RDF::URI (通常は Project#context の値)
    #
    # === 返り値
    # RDFModel
    def parse(id_str, context)
      self.new(self.decode_uri(id_str), context)
    end
    
    # RDF::URIをこのクラスの識別子表現に変換する。
    #
    # === 引数
    # +uri+::
    #  RDF::URI
    #
    # === 返り値
    # String
    def encode_uri(uri)
      uri.to_s.unpack("H*").to_s
    end
    
    # このクラスの識別子表現をRDF::URIに変換する。
    #
    # === 引数
    # +id_str+::
    #  String
    #
    # === 返り値
    # RDF::URI
    def decode_uri(id_str)
      RDF::URI.new(Array.new([id_str]).pack("H*"))
    end

    def has_objects(method_name, property, class_name=nil)
      define_method(method_name) do
        repository.query([uri, property, nil, {:context => context}]).map{|s|
          if class_name
            eval "#{class_name}.new(s.object, context)"
          else
            s.object
          end
        }
      end
    end

    def has_subjects(method_name, property, class_name=nil)
      define_method(method_name) do
        repository.query([nil, property, uri, {:context => context}]).map{|s|
          if class_name
            eval "#{class_name}.new(s.subject, context)"
          else
            s.subject
          end
        }
      end
    end
  end 

  module InstanceMethods    
    # このクラスの識別子を返す。
    # 識別子は、URIを16進文字列で表現した文字列である。
    #
    # === 返り値
    #  String
    def id
      self.class.encode_uri(uri)
    end
    
    private
    
    # このクラスの識別子を返す
    # 識別子は、URIを16進文字列で表現した文字列である
    #
    # === 返り値
    # true
    def persisted?
      true
    end

  end
end

