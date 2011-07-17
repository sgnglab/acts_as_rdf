# -*- coding: utf-8 -*-
module ActsAsRDF

  ##
  # 実際に利用する時はこのモジュールを組み込んで使用する
  #     class Person
  #       include ActsAsRDF::Resource
  #       has_objects :friends, RDF::FOAF[:Person]
  #     end
  module Resource
    extend ActiveSupport::Concern

    included do
      self.instance_eval do
        class << self
          attr_accessor :relations
          @@relations = []
        end
        @relations = []

        # このクラスのURI
        attr_accessor :uri

        # このクラスのContext
        attr_accessor :context
      end
    end

    include ::RDF
    include AttributeMethods
    include ActiveModel::AttributeMethods
    include ActiveModel::Dirty
    include ProcURI
    include Type
    include Spira::Types
    include Callbacks

    module ClassMethods
      ##
      # 
      # @return [RDF::URI]
      def type
        raise ActsAsRDF::NoTypeError unless ActsAsRDF.all_type[self]
        ActsAsRDF.all_type[self]
      end
      
      ##
      # 
      # @param [RDF::URI] new_type
      def define_type(new_type)
        ActsAsRDF.add_type(self, new_type)
      end

      # このクラスのインスタンスをレポジトリから検索する
      #
      # @param [RDF::URI] uri
      # @param [RDF::URI] context
      # @param [self, nil]
      def find(uri, context)
        res = ActsAsRDF.repository.query([uri, RDF.type, type, context]).map do |x| end
        res.empty? ? nil : self.new(uri, context)
      end
      
      # このクラスのインスタンスをレポジトリに登録する
      # URIはユニークなものが自動で与えられる
      #
      # @param [RDF::URI] context
      # @param [self]
      def create(context)
        uri = ActsAsRDF.uniq_uri
        new = self.new(uri,context)
        new.run_callbacks(:save) do
          new.run_callbacks(:create) do
            ActsAsRDF.repository.insert([uri, RDF.type, self.type, context])
            new._save
          end
        end
        new
      end
    end
    
    module InstanceMethods
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
        @attr = {}
        @loaded = false
        @new_record = true
      end

      # このインスタンスが保存されたものであるかを返す
      #
      # @return [True | False]
      def new_record?
        @new_record
      end

      # このクラスの識別子を返す
      # 識別子は、URIを16進文字列で表現した文字列である
      #
      # @return [String]
      def id
        encode_uri
      end

      # 関連のデータを読み込む
      #
      def load
        self.class.relations.each{|rel|
          self.send(self.class._relation_method_names(rel)[:load])
        }
        @loaded = true
        @new_record = false
        true
      end

      # 関連のデータを保存する
      #
      def save
        run_callbacks(:save) do
          call_type = persisted? ? :update : :create
          run_callbacks(call_type) do
            _save
          end
        end
      end

      #
      # @return [RDF::Repository]
      def repository
        ActsAsRDF.repository
      end
      
      # 永続するデータかどうかの確認
      # 
      # @return [true]
      # @see http://api.rubyonrails.org/classes/ActiveModel/Conversion.html
      def persisted?
        ! new_record?
      end

      # 関連のデータを実際に保存する
      #
      def _save
        uri = @uri || ActsAsRDF.uniq_uri
        repository.insert([uri, RDF.type, self.class.type, context])
            
        self.class.relations.each{|rel|
          self.send(self.class._relation_method_names(rel)[:save])
        }
        load
        @new_record = false
        true
      end
    end
  end
end

