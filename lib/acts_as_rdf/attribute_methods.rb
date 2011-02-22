# -*- coding: utf-8 -*-
module ActsAsRDF
  module Resource
    module AttributeMethods
      extend ActiveSupport::Concern
      module ClassMethods
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
            load unless @loaded
            set_objects(property, method_name, type, opt)
          end
          self.send(:define_method, m_names[:set]) do |arg|
            load unless @loaded
            _set_attr(method_name, arg)
            __send__("#{method_name}_will_change!")
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
            load unless @loaded
            set_subjects(property, method_name, type, opt)
          end
          self.send(:define_method, m_names[:set]) do |arg|
            load unless @loaded
            _set_attr(method_name, arg)
            __send__("#{method_name}_will_change!")
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
      end

      module InstanceMethods
        # 属性(関連)名の一覧を返す
        # 
        # @param [Array<Symbol>] 属性名の一覧
        def attributes
          self.class.relations
        end

        private
        # @param [RDF::URI] property
        # @param [String, Spira::Type] type
        # @param [Hash] opt
        # @return [Object]
        def get_objects(method_name, property, type=nil, opt={:single=>false})
          obj = repository.query([uri, property, nil, context]).map{|s|
            build_value(s.object, type)
          }
          @attr[method_name] = opt[:single] ? obj.first : obj
        end
        
        # @param [RDF::URI] property
        # @param [Object] objects
        # @param [String, Spira::Type] type
        # @param [Hash] opt
        def set_objects(property, method_name, type=nil, opt={:single=>false})
          delete_objects(property)
          if opt[:single]
            object = build_rdf_value(@attr[method_name], type)
            repository.insert([uri, property, object, context])
          else
            @attr[method_name].each do |object|
              object = build_rdf_value(object, type)
              repository.insert([uri, property, object, context])
            end
          end
        end
        
        # @param [RDF::URI] property
        def delete_objects(property)
          repository.delete([uri, property, nil, context])
        end
        
        # @param [RDF::URI] property
        # @param [String, Spira::Type] type
        # @param [Hash] opt
        # @return [Object]
        def get_subjects(method_name, property, type=nil, opt={:single=>false})
          subj = repository.query([nil, property, uri, context]).map{|s|
            build_value(s.subject, type)
        }
          @attr[method_name] = opt[:single] ? subj.first : subj
        end
        
        # @param [RDF::URI] property
        # @param [Object] resouces
        # @param [String, Spira::Type] type
        # @param [Hash] opt
        def set_subjects(property, method_name, type=nil, opt={:single=>false})  
          delete_subjects(property)
          if opt[:single]
            resource = build_rdf_value(@attr[method_name], type)
            repository.insert([resource, property, uri, context])
          else
            @attr[method_name].each do |resource|
              resource = build_rdf_value(resource, type)
              repository.insert([resource, property, uri, context])
            end
          end
        end
        
        # @param [RDF::URI] property
        def delete_subjects(property)
          repository.delete([nil, property, uri, context])
        end

        # 関連の値を保存する
        #
        # @param [Symbol] attr_name
        # @param [Object] arg
        def _set_attr(attr_name, arg)
          @attr[attr_name] = arg
        end
      end
    end
  end
end

