module ActsAsRDF

  def self.included(base)
    base.extend ClassMethods
    base.class_eval do
      include InstanceMethods
    end
  end

  @@rand_place = 10000 # ユニークURIの最大値
  @@repository = nil
  @@all_type = {} # このライブラリを使用するRubyクラスのRDFクラスを格納する

  def repository
    @@repository
  end

  def repository=(repository)
    raise unless repository.kind_of?(RDF::Repository)
    @@repository = repository
  end

  # Rubyクラスとそれに紐づけられたRDFクラスをすべて返す
  #
  # === 返り値
  # Hash
  def all_type
    @@all_type
  end

  # RubyクラスにRDFクラスを紐づける
  #
  # === 引数
  # +class_name+::
  #  クラス名
  # +new_type+::
  #  RDF::URI (クラスに紐づけるURI)
  #
  # === 返り値
  # Hash
  def add_type(class_name,new_type)
    @@all_type[class_name] = new_type
  end

  # repositoryに登録されていないURIを返す
  # このURIはrepositoryの全contextを通してuniqである
  #
  # === 返り値
  # RDF::URI
  def uniq_uri
    uri = RDF::URI.new("http://iris.slis.tsukuba.ac.jp/" + rand(@@rand_place).to_s)
    res =
      [[uri, nil, nil],
       [nil, uri, nil],
       [nil, nil, uri]].inject([]){|sum, q|
      sum |= repository.query(q).map
    }
    if res.empty?
      uri
    else
      @@rand_place += 10
      uniq_uri
    end
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
      # このクラスのインスタンス
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
    # このクラスのインスタンス
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
     
      define_method("#{method_name}=") do |objects|
        send(method_name).each do |object|
          object = object.uri if class_name
          repository.delete([uri, property, object, {:context => context}])
        end
        objects.each do |object|
          repository.insert([uri, property, object, {:context => context}])
        end
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

      define_method("#{method_name}=") do |resources|
        send(method_name).each do |resource|
          resource = resource.uri if class_name
          repository.delete([resource, property, uri, {:context => context}])
        end
        resources.each do |resource|
          repository.insert([resource, property, uri, {:context => context}])
        end
      end
    end

    def find(uri, context)
      res = repository.query([uri, RDF.type, type, {:context => context}]).map do |x| end
      res.empty? ? nil : self.new(uri, context)
    end

    def create(context)
      uri = uniq_uri
      repository.insert([uri, RDF.type, self.type, {:context => context}])
      self.new(uri,context)
    end

    def type
      raise ActsAsRDF::NoTypeError unless all_type[self]
      all_type[self]
    end

    def define_type(new_type)
      add_type(self, new_type)
    end
  end 

  module InstanceMethods    
    # URIを16進文字列で表現した文字列を返す
    #
    # === 返り値
    #  String
    def encode_uri
      self.class.encode_uri(uri)
    end

    # このクラスの識別子を返す
    # 識別子は、URIを16進文字列で表現した文字列である
    #
    # === 返り値
    #  String
    def id
      encode_uri
    end

    private
    
    # 永続するデータかどうかの確認
    # このクラスのものはRDF::Repositoryに保存されるはずなので
    # trueを返す
    #
    # === 返り値
    # true
    def persisted?
      true
    end
  end

  class NoTypeError < StandardError; end
end

