require 'rdf'
require 'acts_as_rdf/exceptions'
require 'spira'

##
# ActsAsRDFはRubyの中でRDFデータを簡単に扱うためのライブラリです。
# 特にRuby on Railsの中で利用されることを想定しています。
# @see http://rdf.rubyforge.org
# @see http://github.com/bhuga/spira
module ActsAsRDF

  @@rand_place = 10000 # ユニークURIを生成する際の最大値

  def self.included(base)
    base.extend ClassMethods
    base.class_eval do
      include InstanceMethods
    end
  end

  # システム内部で使用する変数を格納するハッシュを返す
  #
  # @param [Hash]
  def settings
    Thread.current[:acts_as_rdf] ||= {}
  end
  module_function :settings

  # 現在ActsAsRDFに結びつけられているRDF::Repository
  #
  # @return [RDF::Repository]
  def repository
    settings[:repository]
  end
  module_function :repository

  # RDF::Repositoryを登録する
  #
  # @param [RDF::Repository] repository
  def repository=(repository)
    raise unless repository.kind_of?(RDF::Repository)
    settings[:repository] = repository
  end
  module_function :repository=

  # Rubyクラスとそれに紐づけられたRDFクラスをすべて返す
  #
  # @return [Hash] Rubyクラスとそれに紐づけられたRDFクラスをすべて返す
  def all_type
    settings[:types] || {}
  end
  module_function :all_type

  # RubyクラスにRDFクラスを紐づける
  #
  # @param [Const] class_name クラス名
  # @param [RDF::URI] new_type クラスに紐づけるURI
  # @return [Hash]
  def add_type(class_name,new_type)
    settings[:types] ||= {}
    settings[:types][class_name] = new_type
  end
  module_function :add_type

  # repositoryに登録されていないURIを返す.
  # このURIはrepositoryの全contextを通してuniqである.
  # 現在名前空間は以下のURLに固定してある.
  # "http://iris.slis.tsukuba.ac.jp/"
  #
  # @return [RDF::URI]
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
  module_function :uniq_uri

  autoload :Resource, 'acts_as_rdf/resource'
end
