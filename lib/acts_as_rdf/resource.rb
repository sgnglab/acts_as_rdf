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
    include ProcURI
    include Type
    include Validations
    include Spira::Types
    include Callbacks
    include ActiveModel::AttributeMethods
    include ActiveModel::Dirty
    include ActiveModel::Naming
    include ActiveModel::Conversion

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
      def find(uri, context=nil)
        res = ActsAsRDF.repository.query([uri, RDF.type, type, context]).map do |x| end
        if res.empty?
          nil
        else
          found = self.new(uri, context)
          found.load
          found
        end
      end

      # このクラスのインスタンスをレポジトリから検索する
      # URIをエンコードしたIDをもとに検索を行う
      #
      # @param [String] id URIをエンコードした文字列
      # @param [RDF::URI] context
      # @param [self, nil]
      def find_by_id(id, context=nil)
        self.find(self.decode_uri(id), context)
      end

      # このクラスのインスタンスをすべて返す
      #
      # @param [RDF::URI] context
      # @return [Array<Object>]
      def all(context=nil)
        ActsAsRDF.repository.query([nil, RDF.type, type, context]).map do |x| 
          found = self.new(x.subject, context)
          found.load
          found
        end
      end
      
      # このクラスのインスタンスをレポジトリに登録する
      # URIはユニークなものが自動で与えられる
      #
      # @param [RDF::URI] context
      # @param [self]
      def create(context=nil)
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

      # このクラスのオブジェクトをレポジトリから削除する
      # ただし、deleteではこのオブジェクトのrdf:typeに結びつけられた
      # トリプルを削除するだけなので、これ以外のトリプルは削除されない
      # 
      # @param [RDF::URI] uri
      # @param [RDF::URI] context
      def delete(uri, context=nil)
        ActsAsRDF.repository.delete([uri, RDF.type, self.type, context])
      end
    end
    
    module InstanceMethods
      # インスタンスを生成する
      #      project_one = RDF::URI.new('http://project.com/one')
      #      context = RDF::URI.new('http://project.com/)
      #      # URIとコンテキストだけを指定
      #      pro = Project.new(project_one, context)
      #      pro.name = "MyProject"
      #      # まとめて指定
      #      Project.new({:uri => project_one, :context => context, :name => 'MyProject'})
      #
      # @overload initialize(uri = nil, context = nil)
      #   @param [RDF::URI] uri
      #   @param [RDF::URI] context (メタデータシステムの場合、通常は Project#context の値)
      #   @return [self]
      #
      # @overload initialize(attributes = {})
      #   @param [Hash{Symbol => Object}] attributes
      #   @param [Hash{Symbol => Object}] attributes
      #   @option attributes [RDF::URI] :uri
      #     :defaults nil
      #   @option attributes [RDF::URI] :context
      #     :defaults nil
      #   @return [self]
      def initialize(arg1=nil, arg2=nil)
        run_callbacks(:initialize) do
          @attr = {}
          @loaded = false
          @new_record = true
          @destroyed = false

          if arg1.kind_of?(Hash)
            arg1.each{ |k, v|
              self.send("#{k}=", v)
            }
          elsif arg1.kind_of?(RDF::URI)
            @uri = arg1
            @context = arg2
          end
        end
      end

      # このクラスの識別子を返す
      # 識別子は、URIを16進文字列で表現した文字列である
      #
      # @return [String]
      def id
        encode_uri if @uri
      end

      # 関連のデータを読み込む
      #
      def load
        ResourceNotFound if id.empty?
        self.class.relations.each{|rel|
          self.send(self.class._relation_method_names(rel)[:load])
        }
        @loaded = true
        _persisted!
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

      def delete
        self.class.delete(@uri, @context) if persisted?
        @destroyed = true
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
        ! (@new_record || @destroyed)
      end

      # 関連のデータを実際に保存する
      #
      def _save
        @uri ||= ActsAsRDF.uniq_uri
        repository.insert([@uri, RDF.type, self.class.type, @context])
            
        self.class.relations.each{|rel|
          self.send(self.class._relation_method_names(rel)[:save])
        }
        load
        _persisted!
        true
      end

      # 各属性値を更新し、このオブジェクトの値をレポジトリ側にも反映する
      # 
      # @param [Hash{Symbol => Object}] attributes
      # @return [Boolean] true, false
      def update_attributes(attributes)
        attributes.each{ |k,v|
          send("#{k}=", v)
        }
        save
      end

#      private
      # このデータが永続データであることを宣言する
      # 
      # @return [true]
      def _persisted!
        @new_record = false
      end
    end
  end
end

