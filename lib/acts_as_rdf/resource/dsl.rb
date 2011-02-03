module ActsAsRDF
  module Resource
    module DSL
      def has_objects(method_name, property, type=nil)
        _has_objects(method_name, property, type, {:single => false})
      end

      def has_object(method_name, property, type=nil)
        _has_objects(method_name, property, type, {:single => true})
      end

      def _has_objects(method_name, property, type=nil, opt={:single => false})
        self.send(:define_method, method_name.to_s+'=') do |arg|
          set_objects(property, arg, method_name, type)
        end
        self.send(:define_method, method_name) do
          get_objects(property, type, opt)
        end
      end

      def has_subjects(method_name, property, type=nil)
        _has_subjects(method_name, property, type, {:single => false})
      end

      def has_subject(method_name, property, type=nil)
        _has_subjects(method_name, property, type, {:single => true})
      end

      def _has_subjects(method_name, property, type=nil, opt={:single => false})
        self.send(:define_method, method_name.to_s+'=') do |arg|
          set_subjects(property, arg, method_name, type)
        end
        self.send(:define_method, method_name) do
          get_subjects(property, type, opt)
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

