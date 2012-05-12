module SmartProperties
  
  VERSION = "0.0.1"
  
  class Property

    attr_accessor :name
    attr_accessor :default
    attr_accessor :converter
    attr_accessor :validator

    def initialize(name, attrs = {})
      attrs[:viewable] = true unless attrs[:viewable] == false

      self.name = name

      attrs.each do |attr, value|
        send(:"#{attr}=", value) if respond_to?(:"#{attr}=")
      end

      self.converter = attrs[:converts]
      self.validator = attrs[:accepts]
    end

    def required=(value)
      @required = !!value
    end

    def required?
      @required
    end

    def convert(widget, value)
      return value unless converter

      if converter.respond_to?(:call)
        widget.instance_exec(value, &converter)
      else
        begin
          value.send(:"#{converter}")
        rescue NoMethodError
          raise ArgumentError, "#{value.class.name} does not respond to ##{converter}"
        end
      end
    end

    def valid?(widget, value)
      return true unless value
      return true unless validator

      if validator.respond_to?(:call)
        !!widget.instance_exec(value, &validator)
      elsif validator.kind_of?(Enumerable)
        validator.include?(value)
      else
        validator === value
      end
    end

    def define(scope)
      property = self
      
      scope.send(:attr_reader, property.name)

      scope.instance_eval do
        define_method(:"#{property.name}=") do |value|
          if property.required? && value.nil?
            raise ArgumentError, "#{self.class.name} requires the property #{property.name} to be set"
          end

          value = property.convert(self, value) unless value.nil?

          unless property.valid?(self, value)
            raise ArgumentError, "#{self.class.name} does not accept #{value.inspect} as value for the property #{property.name}"
          end

          instance_variable_set(:"@#{property.name}", value)
        end
      end
    end

  end
  
  module ClassMethods

    ##
    # Returns the list of properties for a widget. This includes the
    # properties than have been defined in the parent classes.
    #
    # @return [Array<Property>] The list of properties for this widget.
    #
    def properties
      result =  (@properties ||= []).dup
      
      parent = if self != SmartProperties
        (ancestors[1..-1].find { |klass| klass.ancestors.include?(SmartProperties) && klass != SmartProperties })
      end
      
      result = parent.properties + result if parent
      result
    end

    ##
    # Defines a new property from a name and a set of options. This basically
    # results in creating a getter and setter pair that provides some
    # additional features:
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
    # 3. Providing a default value by specifiying an +:default+ option.
    #
    # 4. Forcing a property to be present by setting the +:required+ option
    #    to true.
    #
    #
    # @param [Symbol] name the name of the property
    #
    # @param [Hash] options the list of options used to configure the property
    # @option options [Array, Class, Proc] :accepted
    #   specifies how the validation is done
    # @option options [Proc, Symbol] :convert
    #   specifies how the conversion is done
    # @option options :default
    #   specifies the default value of the property
    # @option options [true, false] :required
    #   specifies whether or not this property is required
    #
    # @return [Property] The defined property.
    #
    # @example Definition of a property that is mandatory, converts the provided input to a symbol, checks that the symbol is either +:de+ or +:en+, and defaults to +:de+.
    #
    #  property :language_code, :accepts => [:de, :en],
    #                           :converts => :to_sym,
    #                           :default  => :de,
    #                           :required => true
    #
    def property(name, options = {})
      @smart_property_scope ||= begin
        m = Module.new
        include m
        m
      end
      
      @properties ||= []
      @properties << Property.new(name, options)
      @properties.last.define(@smart_property_scope)
      @properties.last
    end

  end
  
  ##
  # Extends the class, which this module is included in, with a property 
  # method to define properties.
  #
  # @param [Class] base the class this module is included in
  #
  def self.included(base)
    base.extend(ClassMethods)
  end
  
  ##
  # Creates a new widget from the provided attributes.
  #
  # @param [Hash] attrs the set of attributes that holds the values for the
  #   various properties of this widget
  #
  def initialize(attrs = {})
    attrs ||= {}

    self.class.properties.each do |property|
      value = attrs.key?(property.name) ? attrs.delete(property.name) : property.default
      send(:"#{property.name}=", value)
    end
  end

end
