module ActsAsRDF
  class NoTypeError < StandardError; end

  # 指定された条件で検索したとき、リソースが存在しないとき
  class ResourceNotFound < StandardError; end
end

