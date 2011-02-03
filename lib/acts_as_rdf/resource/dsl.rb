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
        self.send(:define_method, method_name.to_s+'=') do |arg|
          set_objects(property, arg, method_name, type, opt)
        end
        self.send(:define_method, method_name) do
          get_objects(property, type, opt)
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
        self.send(:define_method, method_name.to_s+'=') do |arg|
          set_subjects(property, arg, method_name, type, opt)
        end
        self.send(:define_method, method_name) do
          get_subjects(property, type, opt)
        end
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

