require 'rdf'
require 'acts_as_rdf/exceptions'
require 'spira'

module ActsAsRDF

  @@rand_place = 10000 # ユニークURIの最大値

  def self.included(base)
    base.extend ClassMethods
    base.class_eval do
      include InstanceMethods
    end
  end

  def settings
    Thread.current[:acts_as_rdf] ||= {}
  end
  module_function :settings

  def repository
    settings[:repository]
  end
  module_function :repository

  def repository=(repository)
    raise unless repository.kind_of?(RDF::Repository)
    settings[:repository] = repository
  end
  module_function :repository=

  # Rubyクラスとそれに紐づけられたRDFクラスをすべて返す
  #
  # === 返り値
  # Hash
  def all_type
    settings[:types] || {}
  end
  module_function :all_type

  # RubyクラスにRDFクラスを紐づける
  #
  # === 引数
  # +class_name+::
  #  クラス名
  # +new_type+::
  #  RDF::URI (クラスに紐づけるURI)
  #
  # === 返り値
  # Hash
  def add_type(class_name,new_type)
    settings[:types] ||= {}
    settings[:types][class_name] = new_type
  end
  module_function :add_type

  # repositoryに登録されていないURIを返す
  # このURIはrepositoryの全contextを通してuniqである
  #
  # === 返り値
  # RDF::URI
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
