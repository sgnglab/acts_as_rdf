# ActsAsRdf

ActiveModelのクラスにRDFの入出力機能を加えるライブラリ

---

### 概要
以下のようにして利用します。

    ActsAsRDF.repository = RDF::Repository
    
    class Person
      include ActsAsRDF
      define_type RDF::FOAF[:Person]
      has_objects :friends, RDF::FOAF[:knows]
    end
    
    alice = Person.find(RDF::URI.new('http://ali.ce/'), RDF::URI.new('http://context.com'))
    alice.friends

#### define_type
このRubyクラスのURIが、RDFクラスのインスタンスかを定義します。

#### has\_object(s), has_subject(s)
このRubyクラスのURIと結び付けられているノードと関連を定義します。

### 関連
対象のクラスのインスタンスを起点とした関連を定義可能です。

#### has_object(s)
このクラスのURIを主語として、任意のプロパティの目的語を取得/更新するメソッドを定義します。

    class Person
      include ActsAsRDF
      define_type RDF::FOAF[:Person]
      has_object  :homepage, RDF::FOAF[:homepage]
      has_object  :name,     RDF::FOAF[:name],  String
      has_objects :friends,  RDF::FOAF[:knows], 'Person'
    end

    # 一つの値と結び付けられている
    person.homepage # RDF::URIを一つ返す
    person.homepage = RDF::URI.new('http://person.com/')

    # こちらも一つの値と結び付けられている
    person.name     # Stringを一つ返す
    person.name = 'My Name'

    # 複数の値と結び付けられる
    person.friends  # Personの配列を返す
    person.friends = [person2, person3]

has_object(s)の引数は以下のようになっています:
    has_object(s) 'メソッド名', 'プロパティ名', '型'
- メソッド名: ここで指定された値がメソッド名になります。
- プロパティ名: このプロパティを関連をはります。
- 型: 目的語の型を指定します。

#### has_subject(s)
このクラスを目的語として、任意のプロパティの主語の主語を取得/更新します。インタフェースなどはhas_object(s)と同じです。

### 型
関連の値の型を指定することができます。また、ActsAsRDFを組み込んだRubyクラスも指定に使うことができます。

    has_object  :homepage, RDF::FOAF[:homepage]        # デフォルトではRDF::URI
    has_object  :name,     RDF::FOAF[:name],  String   # Spira::Type::String
    has_objects :friends,  RDF::FOAF[:knows], 'Person' # ActsAsRDFを組み込んだPerson

Spira <https://github.com/datagraph/spira>
  
### 'License'
Copyright (c) 2010 [name of plugin creator], released under the MIT license
