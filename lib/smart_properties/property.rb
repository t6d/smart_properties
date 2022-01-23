require_relative "property/runtime"

module SmartProperties
  class Property
    MODULE_REFERENCE = :"@_smart_properties_method_scope"
    ALLOWED_DEFAULT_CLASSES = [Proc, Numeric, String, Range, TrueClass, FalseClass, NilClass, Symbol, Module].freeze

    attr_reader :name
    attr_reader :reader
    attr_reader :writable
    attr_reader :runtime

    def self.define(scope, name, options = {})
      new(name, options).tap { |p| p.define(scope) }
    end

    def initialize(name, attrs = {})
      attrs = attrs.dup

      @name = name.to_sym
      @reader = attrs.delete(:reader) || @name
      @writable = attrs.delete(:writable)

      @runtime = Runtime.new(
        required: attrs.delete(:required),
        converts: attrs.delete(:converts),
        accepts: attrs.delete(:accepts),
        default: attrs.delete(:default),
        instance_variable_name: :"@#{name}",
        property: self,
      )

      unless ALLOWED_DEFAULT_CLASSES.any? { |cls| @runtime[:default].is_a?(cls) }
        raise ConfigurationError, "Default attribute value #{@runtime[:default].inspect} cannot be specified as literal, "\
          "use the syntax `default: -> { ... }` instead."
      end

      unless attrs.empty?
        raise ConfigurationError, "SmartProperties do not support the following configuration options: #{attrs.keys.map { |m| m.to_s }.sort.join(', ')}."
      end
    end

    def define(klass)
      property = self

      scope =
        if klass.instance_variable_defined?(MODULE_REFERENCE)
          klass.instance_variable_get(MODULE_REFERENCE)
        else
          m = Module.new
          klass.send(:include, m)
          klass.instance_variable_set(MODULE_REFERENCE, m)
          m
        end

      scope.send(:define_method, reader) do
        property.runtime.get(self)
      end

      if writable?
        scope.send(:define_method, :"#{name}=") do |value|
          property.runtime.set(self, value)
        end
      end
    end

    def writable?
      return true if @writable.nil?
      @writable
    end

    def to_h
      runtime.to_h
    end
  end
end
