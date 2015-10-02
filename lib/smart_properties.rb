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
  VERSION = "1.9.0"

  module ClassMethods
    ##
    # Returns a class's smart properties. This includes the properties that
    # have been defined in the parent classes.
    #
    # @return [Hash<String, Property>] A map of property names to property instances.
    #
    def properties
      @_smart_properties ||= PropertyCollection.for(self)
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
      properties[name] = Property.define(self, name, options)
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
        property.set(self, attrs[property.name])
      else
        missing_properties.push(property)
      end
    end

    # Exectue configuration block
    block.call(self) if block

    # Set defaults
    missing_properties.each do |property|
      variable = property.instance_variable_name
      if property.null_object?(instance_variable_get(variable)) && !property.null_object?(default_value = property.default(self))
        property.set(self, default_value)
      end
    end

    # Check presence of all required properties
    faulty_properties =
      properties.select { |_, property| property.required?(self) && property.null_object?(property.get(self)) }.map(&:last)
    unless faulty_properties.empty?
      error = SmartProperties::InitializationError.new(self, faulty_properties)
      raise error
    end
  end
end

require_relative 'smart_properties/property_collection'
require_relative 'smart_properties/property'
require_relative 'smart_properties/errors'
