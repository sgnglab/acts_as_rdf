module ActsAsRDF
  module Resource
    module ActiveModel
      # このクラスの識別子を返す
      # 識別子は、URIを16進文字列で表現した文字列である
      #
      # @return [String]
      def id
        encode_uri
      end
      
      private
      
      # 永続するデータかどうかの確認
      # このクラスのものはRDF::Repositoryに保存されるはずなので
      # trueを返す
      # 
      # @return [true]
      # @see http://api.rubyonrails.org/classes/ActiveModel/Conversion.html
      def persisted?
        true
      end
    end
  end
end

