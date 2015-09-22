##
# {SmartProperties} can be used to easily build more full-fledged accessors
# for standard Ruby classes. In contrast to regular accessors,
# {SmartProperties} support validation and conversion of input data, as well
# as, the specification of default values. Additionally, individual
# {SmartProperties} can be marked as required. This causes the runtime to
# throw an +ArgumentError+ whenever a required property has not been
# specified.
#
# In order to use {SmartProperties}, simply include the {SmartProperties}
# module and use the {ClassMethods#property} method to define properties.
#
# @see ClassMethods#property
#   More information on how to configure properties
#
# @example Definition of a property that makes use of all {SmartProperties} features.
#
#  property :language_code, :accepts => [:de, :en],
#                           :converts => :to_sym,
#                           :default  => :de,
#                           :required => true
#
module SmartProperties
  VERSION = "1.8.0"

  class Error < ::ArgumentError; end
  class ConfigurationError < Error; end

  class AssignmentError < Error
    attr_accessor :sender
    attr_accessor :property

    def initialize(sender, property, message)
      @sender = sender
      @property = property
      super(message)
    end
  end

  class MissingValueError < AssignmentError
    def initialize(sender, property)
      super(
        sender,
        property,
        "%s requires the property %s to be set" % [
          sender.class.name,
          property.name
        ]
      )
    end

    def to_hash
      Hash[property.name, "must be set"]
    end
  end

  class InvalidValueError < AssignmentError
    attr_accessor :value

    def initialize(sender, property, value)
      @value = value
      super(
        sender,
        property,
        "%s does not accept %s as value for the property %s" % [
          sender.class.name,
          value.inspect,
          property.name
        ]
      )
    end

    def to_hash
      Hash[property.name, "does not accept %s as value" % value.inspect]
    end
  end

  class InitializationError < Error
    attr_accessor :sender
    attr_accessor :properties

    def initialize(sender, properties)
      @sender = sender
      @properties = properties
      super(
        "%s requires the following properties to be set: %s" % [
          sender.class.name,
          properties.map(&:name).sort.join(', ')
        ]
      )
    end

    def to_hash
      properties.each_with_object({}) { |property, errors| errors[property.name] = "must be set" }
    end
  end

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

    def initialize(name, attrs = {})
      attrs = attrs.dup

      @name      = name.to_sym
      @default   = attrs.delete(:default)
      @converter = attrs.delete(:converts)
      @accepter  = attrs.delete(:accepts)
      @required  = attrs.delete(:required)

      unless attrs.empty?
        raise ConfigurationError, "SmartProperties do not support the following configuration options: #{attrs.keys.map { |m| m.to_s }.sort.join(', ')}."
      end
    end

    def required?(scope)
      @required.kind_of?(Proc) ? scope.instance_exec(&@required) : !!@required
    end

    def convert(value, scope)
      return value unless converter
      scope.instance_exec(value, &converter)
    end

    def default(scope)
      @default.kind_of?(Proc) ? scope.instance_exec(&@default) : @default
    end

    def accepts?(value, scope)
      return true unless value
      return true unless accepter

      if accepter.respond_to?(:to_proc)
        !!scope.instance_exec(value, &accepter)
      else
        Array(accepter).any? { |accepter| accepter === value }
      end
    end

    def prepare(value, scope)
      raise MissingValueError.new(scope, self) if required?(scope) && value.nil?
      value = convert(value, scope) unless value.nil?
      raise MissingValueError.new(scope, self) if required?(scope) && value.nil?
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
        instance_variable_set("@#{property.name}", property.prepare(value, self))
      end
    end

  end

  class PropertyCollection

    include Enumerable

    attr_reader :parent

    def initialize(parent = nil)
      @parent = parent
      @collection = {}
    end

    def []=(name, value)
      collection[name] = value
    end

    def [](name)
      collection_with_parent_collection[name]
    end

    def key?(name)
      collection_with_parent_collection.key?(name)
    end

    def each(&block)
      collection_with_parent_collection.each(&block)
    end

    protected

      attr_accessor :collection

      def collection_with_parent_collection
        parent.nil? ? collection : parent.collection.merge(collection)
      end

  end

  module ClassMethods

    ##
    # Returns a class's smart properties. This includes the properties that
    # have been defined in the parent classes.
    #
    # @return [Hash<String, Property>] A map of property names to property instances.
    #
    def properties
      @_smart_properties ||= begin
        parent = if self != SmartProperties
          (ancestors[1..-1].find { |klass| klass.ancestors.include?(SmartProperties) && klass != SmartProperties })
        end

        parent.nil? ? PropertyCollection.new : PropertyCollection.new(parent.properties)
      end
    end

    ##
    # Defines a new property from a name and a set of options. This results
    # results in creating an accessor that has additional features:
    #
    # 1. Validation of input data by specifiying the +:accepts+ option:
    #    If you use a class as value for this option, the setter will check
    #    if the value it is about to assign is of this type. If you use an
    #    array, the setter will check if the value it is about to assign is
    #    included in this array. Finally, if you specify a block, it will
    #    invoke the block with the value it is about to assign and check if
    #    the block returns a thruthy value, meaning anything but +false+ and
    #    +nil+.
    #
    # 2. Conversion of input data by specifiying the +:converts+ option:
    #    If you use provide a symbol as value for this option, the setter will
    #    invoke this method on the object it is about to assign and take the
    #    result of this call instead. If you provide a block, it will invoke
    #    the block with the value it is about to assign and take the result
    #    of the block instead.
    #
    # 3. Providing a default value by specifiying the +:default+ option.
    #
    # 4. Forcing a property to be present by setting the +:required+ option
    #    to true.
    #
    #
    # @param [Symbol] name the name of the property
    #
    # @param [Hash] options the list of options used to configure the property
    # @option options [Array, Class, Proc] :accepts
    #   specifies how the validation is done
    # @option options [Proc, Symbol] :converts
    #   specifies how the conversion is done
    # @option options :default
    #   specifies the default value of the property
    # @option options [true, false] :required
    #   specifies whether or not this property is required
    #
    # @return [Property] The defined property.
    #
    # @example Definition of a property that makes use of all {SmartProperties} features.
    #
    #  property :language_code, :accepts => [:de, :en],
    #                           :converts => :to_sym,
    #                           :default  => :de,
    #                           :required => true
    #
    def property(name, options = {})
      p = Property.new(name, options)
      p.define(self)

      properties[name] = p
    end
    protected :property

  end

  class << self

    private

      ##
      # Extends the class, which this module is included in, with a property
      # method to define properties.
      #
      # @param [Class] base the class this module is included in
      #
      def included(base)
        base.extend(ClassMethods)
      end

  end

  ##
  # Implements a key-value enabled constructor that acts as default
  # constructor for all {SmartProperties}-enabled classes.
  #
  # @param [Hash] attrs the set of attributes that is used for initialization
  #
  def initialize(*args, &block)
    attrs = args.last.is_a?(Hash) ? args.pop : {}
    super(*args)

    properties = self.class.properties.each.to_a
    missing_properties = []

    # Assign attributes or default values
    properties.each do |_, property|
      if attrs.key?(property.name)
        instance_variable_set("@#{property.name}", property.prepare(attrs[property.name], self))
      else
        missing_properties.push(property)
      end
    end

    # Exectue configuration block
    block.call(self) if block

    # Set defaults
    missing_properties.each do |property|
      variable = "@#{property.name}"
      if instance_variable_get(variable).nil? && !(default_value = property.default(self)).nil?
        instance_variable_set(variable, property.prepare(default_value, self))
      end
    end

    # Check presence of all required properties
    faulty_properties =
      properties.select { |_, property| property.required?(self) && instance_variable_get("@#{property.name}").nil? }.map(&:last)
    unless faulty_properties.empty?
      error = SmartProperties::InitializationError.new(self, faulty_properties)
      raise error
    end
  end
end
