module ActsAsRDF
  module Resource
    module ClassMethods
      
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
      
      def find(uri, context)
        res = repository.query([uri, RDF.type, type, {:context => context}]).map do |x| end
        res.empty? ? nil : self.new(uri, context)
      end
      
      def create(context)
        uri = ActsAsRDF.uniq_uri
        repository.insert([uri, RDF.type, self.type, {:context => context}])
        self.new(uri,context)
      end

      def repository
        ActsAsRDF.repository
      end
    end
  end
end

