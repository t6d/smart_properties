module SmartProperties
  class Property
    # Defines the two index methods #[] and #[]=. This module will be included
    # in the SmartProperties method scope.
    module IndexMethods
      def [](name)
        return if name.nil?
        name &&= name.to_sym
        public_send(name) if self.class.properties.key?(name)
      end

      def []=(name, value)
        return if name.nil?
        public_send(:"#{name.to_sym}=", value) if self.class.properties.key?(name)
      end
    end

    attr_reader :name
    attr_reader :converter
    attr_reader :accepter
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

      @instance_variable_name = :"@#{name}"

      unless attrs.empty?
        raise ConfigurationError, "SmartProperties do not support the following configuration options: #{attrs.keys.map { |m| m.to_s }.sort.join(', ')}."
      end
    end

    def required?(scope)
      @required.kind_of?(Proc) ? scope.instance_exec(&@required) : !!@required
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

    def prepare(scope, value)
      required = required?(scope)
      raise MissingValueError.new(scope, self) if required && null_object?(value)
      value = convert(scope, value)
      raise MissingValueError.new(scope, self) if required && null_object?(value)
      raise InvalidValueError.new(scope, self, value) unless accepts?(value, scope)
      value
    end

    def define(klass)
      property = self

      scope = klass.instance_variable_get(:"@_smart_properties_method_scope") || begin
        m = Module.new { include IndexMethods }
        klass.send(:include, m)
        klass.instance_variable_set(:"@_smart_properties_method_scope", m)
        m
      end

      scope.send(:attr_reader, name)
      scope.send(:define_method, :"#{name}=") do |value|
        instance_variable_set("@#{property.name}", property.prepare(self, value))
      end
    end

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
