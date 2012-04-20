# -*- coding: utf-8 -*-
module ActsAsRDF
  module Resource
    module Persistence
      extend ActiveSupport::Concern
      module ClassMethods
        # このクラスのインスタンスをレポジトリに登録する
        # URIはユニークなものが自動で与えられる
        #
        # @param [RDF::URI] context
        # @param [self]
        def create(context=nil)
          uri = ActsAsRDF.uniq_uri
          new = self.new(uri,context)
          new.run_callbacks(:save) do
            new.run_callbacks(:create) do
              ActsAsRDF.repository.insert([uri, RDF.type, self.type, context])
              new._save
            end
          end
          new
        end
        # このクラスのオブジェクトをレポジトリから削除する
        # ただし、deleteではこのオブジェクトのrdf:typeに結びつけられた
        # トリプルを削除するだけなので、これ以外のトリプルは削除されない
        # 
        # @param [RDF::URI] uri
        # @param [RDF::URI] context
        def delete(uri, context=nil)
          ActsAsRDF.repository.delete([uri, RDF.type, self.type, context])
        end
      end

      #module InstanceMethods
        # 永続するデータかどうかの確認
        # 
        # @return [true]
        # @see http://api.rubyonrails.org/classes/ActiveModel/Conversion.html
        def persisted?
          ! (@new_record || @destroyed)
        end

#      private
        # このデータが永続データであることを宣言する
        # 
        # @return [true]
        def _persisted!
          @new_record = false
        end

        # 関連のデータを保存する
        #
        def save
          run_callbacks(:save) do
            call_type = persisted? ? :update : :create
            run_callbacks(call_type) do
              _save
            end
          end
        end

        # 関連のデータを実際に保存する
        #
        def _save
          @uri ||= ActsAsRDF.uniq_uri
          repository.insert([@uri, RDF.type, self.class.type, @context])
          
          self.class.relations.each{|rel|
            self.send(self.class._relation_method_names(rel)[:save])
          }   
          
          load
          _persisted!
          true
        end
        
        def delete
          self.class.delete(@uri, @context) if persisted?
          @destroyed = true
        end
        
        # このオブジェクトを削除する
        # 現状ではdeleteとの違いはあまりない。
        # ただし、destoryの場合は:destoryのコールバックが発生する点が異なる
        # 
        def destroy
          run_callbacks(:destroy) do
            delete
          end
        end

        # 関連のデータを読み込む
        #
        def load
          ResourceNotFound if id.empty?
          self.class.relations.each{|rel|
            self.send(self.class._relation_method_names(rel)[:load])
          }
          @loaded = true
          _persisted!
          true
        end

        # 各属性値を更新し、このオブジェクトの値をレポジトリ側にも反映する
        # 
        # @param [Hash{Symbol => Object}] attributes
        # @return [Boolean] true, false
        def update_attributes(attributes)
          attributes.each{ |rel,v|
            send(self.class._relation_method_names(rel)[:set],v)
          }
          save
        end

      #end
    end
  end
end
