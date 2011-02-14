# -*- coding: utf-8 -*-
module ActsAsRDF
  module Resource
    module DSL
      # このクラスに関連を追加する.
      # この場合は複数の値と関連づけられる
      # 
      # @param [Symbol] method_name
      # @param [RDF::URI] property
      # @param [String, Spira::Type] type
      def has_objects(method_name, property, type=nil)
        _has_objects(method_name, property, type, {:single => false})
      end

      # このクラスに関連を追加する.
      # この場合は一つ値と関連づけられる
      # 
      # @param (see #has_objects)
      def has_object(method_name, property, type=nil)
        _has_objects(method_name, property, type, {:single => true})
      end

      # @param (see #has_objects)
      # @param [Hash] opt
      def _has_objects(method_name, property, type=nil, opt={:single => false})
        m_names = _relation_method_names(method_name)
        register_relation method_name
        self.send(:define_method, m_names[:save]) do
          set_objects(property, method_name, type, opt)
        end
        self.send(:define_method, m_names[:set]) do |arg|
          load unless @loaded
          _set_attr(method_name, arg)
        end
        self.send(:define_method, m_names[:load]) do
          get_objects(method_name, property, type, opt)
        end
        self.send(:define_method, m_names[:get]) do
          load unless @loaded
          @attr[method_name]
        end
      end
      
      #
      # @param (see #has_objects)
      def has_subjects(method_name, property, type=nil)
        _has_subjects(method_name, property, type, {:single => false})
      end

      #
      # @param (see #has_objects)
      def has_subject(method_name, property, type=nil)
        _has_subjects(method_name, property, type, {:single => true})
      end

      # @param (see #_has_objects)
      def _has_subjects(method_name, property, type=nil, opt={:single => false})
        m_names = _relation_method_names(method_name)
        register_relation method_name
        self.send(:define_method, m_names[:save]) do
          set_subjects(property, method_name, type, opt)
        end
        self.send(:define_method, m_names[:set]) do |arg|
          load unless @loaded
          _set_attr(method_name, arg)
        end
        self.send(:define_method, m_names[:load]) do
          get_subjects(method_name, property, type, opt)
        end
        self.send(:define_method, m_names[:get]) do
          load unless @loaded
          @attr[method_name]
        end
      end

      # 関連のデータの入出力のためのメソッド名を返す
      # 返り値のキーが用途で、その値がメソッド名
      #
      # @param [Symbol] base_name      
      def _relation_method_names(base_name)
        base_name = base_name.to_s
        {
          # 非破壊的
          :get => base_name,       # 取得
          :set => base_name + '=', # 更新
          # 破壊的
          :load => '_load_' + base_name, # 取得
          :save => '_save_' + base_name  # 更新
        }
      end

      # 関連名を追加する
      #
      # @param [Symbol] relation_name
      def register_relation(relation_name)
        @relations << relation_name
      end
      
      ##
      # 
      # @return [RDF::URI]
      def type
        raise ActsAsRDF::NoTypeError unless ActsAsRDF.all_type[self]
        ActsAsRDF.all_type[self]
      end

      ##
      # 
      # @param [RDF::URI] new_type
      def define_type(new_type)
        ActsAsRDF.add_type(self, new_type)
      end
    end
  end
end

