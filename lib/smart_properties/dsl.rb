module SmartProperties
  module DSL
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

    def property!(name, options = {})
      options[:required] = true
      property(name, options)
    end
    protected :property!
  end
end
