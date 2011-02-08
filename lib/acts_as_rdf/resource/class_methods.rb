# -*- coding: utf-8 -*-
module ActsAsRDF
  module Resource
    module ClassMethods
      
      # RDFのリソースであるクラスを生成する
      #
      # @param [String] id_str URIを16進文字列で表現した文字列
      # @param [RDF::URI] context (メタデータシステムの場合、通常は Project#context の値)
      # @return [self] このクラスのインスタンス
      def parse(id_str, context)
        self.new(self.decode_uri(id_str), context)
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

      # このクラスのインスタンスをレポジトリから検索する
      #
      # @param [RDF::URI] uri
      # @param [RDF::URI] context
      # @param [self, nil]
      def find(uri, context)
        res = repository.query([uri, RDF.type, type, context]).map do |x| end
        res.empty? ? nil : self.new(uri, context)
      end
      
      # このクラスのインスタンスをレポジトリに登録する
      # URIはユニークなものが自動で与えられる
      #
      # @param [RDF::URI] context
      # @param [self]
      def create(context)
        uri = ActsAsRDF.uniq_uri
        repository.insert([uri, RDF.type, self.type, context])
        self.new(uri,context)
      end

      # このクラスが利用するレポジトリを返す
      #
      # @return [RDF::Repository]
      def repository
        ActsAsRDF.repository
      end
    end
  end
end

