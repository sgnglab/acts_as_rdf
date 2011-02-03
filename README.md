# ActsAsRdf

ActiveModelのクラスにRDFのゲッターを加えるライブラリ

---

### Synopsis
以下のようにして利用します。

    ActsAsRDF.repository = RDF::Repository
    
    class Person
      include ActsAsRDF
      define_type RDF::FOAF[:Person]
      has_objects :friends, RDF::FOAF[:knows]
    end
    
    alice = Person.find(RDF::URI.new('http://ali.ce/', 'http://context.com')
    alice.friends
  
### 'License'
Copyright (c) 2010 [name of plugin creator], released under the MIT license
