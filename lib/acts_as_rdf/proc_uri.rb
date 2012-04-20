# -*- coding: utf-8 -*-
module ActsAsRDF
  module Resource
    module ProcURI
      extend ActiveSupport::Concern
      module ClassMethods      
        # RDFのリソースであるクラスを生成する
        #
        # @param [String] id_str URIを16進文字列で表現した文字列
        # @param [RDF::URI] context (メタデータシステムの場合、通常は Project#context の値)
        # @return [self] このクラスのインスタンス
        def parse(id_str, context)
          self.new(decode_uri(id_str), context)
        end
        
        # RDF::URIをこのクラスの識別子表現に変換する。
        #
        # @param [RDF::URI] uri
        # @return [String]
        def encode_uri(uri)
          uri.to_s.unpack("H*").to_s
        end
        
        # このクラスの識別子表現をRDF::URIに変換する。
        #
        # @param [String] id_str
        # @return [RDF::URI]
        def decode_uri(id_str)
          RDF::URI.new(Array.new([id_str]).pack("H*"))
        end
      end

      #module InstanceMethods
        # URIを16進文字列で表現した文字列を返す
        #
        # @return [String]
        def encode_uri
          self.class.encode_uri(uri)
        end
      #end
    end
  end
end
