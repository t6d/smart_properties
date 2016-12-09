require 'byebug'
module SmartProperties
  class Property
    MODULE_REFERENCE = :"@_smart_properties_method_scope"

    # Defines the two index methods #[] and #[]=. This module will be included
    # in the SmartProperties method scope.
    module IndexMethods
      def [](name)
        return if name.nil?
        name = name.to_sym
        reader = self.class.properties[name].reader
        public_send(reader) if self.class.properties.key?(name)
      end

      def []=(name, value)
        return if name.nil?
        public_send(:"#{name.to_sym}=", value) if self.class.properties.key?(name)
      end
    end

    attr_reader :name
    attr_reader :converter
    attr_reader :accepter
    attr_reader :reader
    attr_reader :responder
    attr_reader :instance_variable_name

    def self.define(scope, name, options = {})
      new(name, options).tap { |p| p.define(scope) }
    end

    def initialize(name, attrs = {})
      attrs = attrs.dup

      @name      = name.to_sym
      @default   = attrs.delete(:default)
      @converter = attrs.delete(:converts)
      @accepter  = attrs.delete(:accepts)
      @required  = attrs.delete(:required)
      @responder = attrs.delete(:responds_to)
      @reader    = attrs.delete(:reader)
      @reader    ||= @name

      @instance_variable_name = :"@#{name}"

      unless attrs.empty?
        raise ConfigurationError, "SmartProperties do not support the following configuration options: #{attrs.keys.map { |m| m.to_s }.sort.join(', ')}."
      end
    end

    def required?(scope)
      @required.kind_of?(Proc) ? scope.instance_exec(&@required) : !!@required
    end

    def optional?(scope)
      !required?(scope)
    end

    def missing?(scope)
      required?(scope) && !present?(scope)
    end

    def present?(scope)
      !null_object?(get(scope))
    end

    def convert(scope, value)
      return value unless converter
      return value if null_object?(value)
      scope.instance_exec(value, &converter)
    end

    def default(scope)
      @default.kind_of?(Proc) ? scope.instance_exec(&@default) : @default
    end

    def accepts?(value, scope)
      return true unless accepter
      return true if null_object?(value)

      if accepter.respond_to?(:to_proc)
        !!scope.instance_exec(value, &accepter)
      else
        Array(accepter).any? { |accepter| accepter === value }
      end
    end

    def responds_to?(value, scope)
      return true if null_object?(value)
      return true unless responder
      methods = value.methods
      responder.each { |method| return false unless methods.include? method }
      true
    end

    def prepare(scope, value)
      required = required?(scope)
      raise MissingValueError.new(scope, self) if required && null_object?(value)
      value = convert(scope, value)
      raise MissingValueError.new(scope, self) if required && null_object?(value)
      raise InvalidValueError.new(scope, self, value) unless accepts?(value, scope)
      raise InvalidValueError.new(scope, self, value) unless responds_to?(value, scope)
      value
    end

    def define(klass)
      property = self

      scope =
        if klass.instance_variable_defined?(MODULE_REFERENCE)
          klass.instance_variable_get(MODULE_REFERENCE)
        else
          m = Module.new { include IndexMethods }
          klass.send(:include, m)
          klass.instance_variable_set(MODULE_REFERENCE, m)
          m
        end

      scope.send(:define_method, reader) do
        property.get(self)
      end
      scope.send(:define_method, :"#{name}=") do |value|
        property.set(self, value)
      end
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

    private

    def null_object?(object)
      return true if object == nil
      return true if object.nil?
      false
    rescue NoMethodError => error
      # BasicObject does not respond to #nil? by default, so we need to double
      # check if somebody implemented it and it fails internally or if the
      # error occured because the method is actually not present. In the former
      # case, we want to raise the exception because there is something wrong
      # with the implementation of object#nil?. In the latter case we treat the
      # object as truthy because we don't know better.
      raise error if (class << object; self; end).public_instance_methods.include?(:nil?)
      false
    end
  end
end
