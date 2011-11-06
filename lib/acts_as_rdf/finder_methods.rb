# -*- coding: utf-8 -*-
module ActsAsRDF
  module Resource
    module FinderMethods
      extend ActiveSupport::Concern
      
      module ClassMethods
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
      end
      
      module InstanceMethods
      end
    end
  end
end

