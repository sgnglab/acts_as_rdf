module ActsAsRDF
  module ActiveModel
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
end

