require_relative "plugin_repository"
require_relative "base_runtime"
require_relative "plugins"

module SmartProperties
	class Property
    # Runtime = PluginRepository.build_runtime(
    #   RequiredCheck,
    #   Conversion,
    #   RequiredCheck,
    #   AcceptanceCheck,
    # )

    Runtime = Struct.new(:required, :converts, :accepts, :default, :instance_variable_name, :property, keyword_init: true) do
      def missing?(scope)
        required?(scope) && !present?(scope)
      end

      def present?(scope)
        !null_object?(get(scope))
      end

      def optional?(scope)
        !required?(scope)
      end

      def required?(scope)
        RequiredCheck.new(property, required).enabled?(scope)
      end

      def convert(scope, value)
        Conversion.new(property, converts).call(scope, value)
      end

      def default(scope)
        self[:default].kind_of?(Proc) ? scope.instance_exec(&self[:default]) : self[:default].dup
      end

      def prepare(scope, value)
        required_check = RequiredCheck.new(property, required)
        required_check.call(scope, value)
        value = convert(scope, value)
        required_check.call(scope, value)
        acceptance_check = AcceptanceCheck.new(property, accepts)
        raise InvalidValueError.new(scope, property, value) unless acceptance_check.call(scope, value)
        value
      end

      def set(scope, value)
        scope.instance_variable_set(instance_variable_name, prepare(scope, value))
      end

      def set_default(scope)
        return false if present?(scope)

        default_value = default(scope)
        return false if null_object?(default_value)

        set(scope, default_value)
        true
      end

      def get(scope)
        return nil unless scope.instance_variable_defined?(instance_variable_name)
        scope.instance_variable_get(instance_variable_name)
      end

      def to_h
        {
          accepter: self[:accepts],
          converter: self[:converts],
          default: self[:default],
          instance_variable_name: self[:instance_variable_name],
          required: self[:required],
          name: property.name,
          reader: property.reader,
        }
      end

      private

      def null_object?(object)
        object.nil?
      rescue NoMethodError => error
        # BasicObject does not respond to #nil? by default, so we need to double
        # check if somebody implemented it and it fails internally or if the
        # error occured because the method is actually not present.

        # This is a workaround for the fact that #singleton_class is defined on Object, but not BasicObject.
        the_singleton_class = (class << object; self; end)

        if the_singleton_class.public_instance_methods.include?(:nil?)
          # object defines #nil?, but it raised NoMethodError,
          # something is wrong with the implementation, so raise the exception.
          raise error
        else
          # treat the object as truthy because we don't know better.
          false
        end
      end
    end
	end
end
