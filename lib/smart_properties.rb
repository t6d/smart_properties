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

  VERSION = "1.4.0"

  class ArgumentError < ::ArgumentError
    attr_accessor :errors
  end

  class Property

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
        raise SmartProperties::ArgumentError, "SmartProperties do not support the following configuration options: #{attrs.keys.map { |m| m.to_s }.sort.join(', ')}."
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
      if required?(scope) && value.nil?
        error = SmartProperties::ArgumentError.new "#{scope.class.name} requires the property #{self.name} to be set"
        error.errors = Hash[self.name, "must be set"]
        raise error
      end

      value = convert(value, scope) unless value.nil?

      unless accepts?(value, scope)
        error = SmartProperties::ArgumentError.new "#{scope.class.name} does not accept #{value.inspect} as value for the property #{self.name}"
        error.errors = Hash[self.name, "does not accept #{value.inspect} as value"]
        raise error
      end

      value
    end

    def define(klass)
      property = self

      scope = klass.instance_variable_get(:"@_smart_properties_method_scope") || begin
        m = Module.new
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
  def initialize(attrs = {}, &block)
    attrs ||= {}
    properties = self.class.properties.each.to_a

    # Assign attributes or default values
    properties.each do |_, property|
      value = attrs.fetch(property.name, property.default(self))
      send(:"#{property.name}=", value) unless value.nil?
    end

    # Exectue configuration block
    block.call(self) if block

    # Check presence of all required properties
    faulty_properties = properties.select { |_, property| property.required?(self) && send(property.name).nil? }
    unless faulty_properties.empty?
      error = SmartProperties::ArgumentError.new "#{self.class.name} requires the following properties to be set: #{faulty_properties.map { |_, property| property.name }.sort.join(' ')}"
      error.errors = faulty_properties.each_with_object({}){|property,hash| hash[property.first] = "must be set" }
      raise error
    end
  end

end
