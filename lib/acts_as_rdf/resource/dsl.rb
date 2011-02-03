module ActsAsRDF
  module Resource
    module DSL
      def has_objects(method_name, property, class_name=nil)
        _has_objects(method_name, property, class_name, {:single => false})
      end

      def has_object(method_name, property, class_name=nil)
        _has_objects(method_name, property, class_name, {:single => true})
      end

      def _has_objects(method_name, property, class_name=nil, opt={:single => false})
        self.send(:define_method, method_name.to_s+'=') do |arg|
          set_objects(property, arg, method_name, class_name)
        end
        self.send(:define_method, method_name) do
          get_objects(property, class_name, opt)
        end
      end

      def has_subjects(method_name, property, class_name=nil)
        self.send(:define_method, method_name.to_s+'=') do |arg|
          set_subjects(property, arg, method_name, class_name)
        end
        self.send(:define_method, method_name) do
          get_subjects(property, class_name)
        end
      end
      
      def type
        raise ActsAsRDF::NoTypeError unless ActsAsRDF.all_type[self]
        ActsAsRDF.all_type[self]
      end
      
      def define_type(new_type)
        ActsAsRDF.add_type(self, new_type)
      end
    end
  end
end

