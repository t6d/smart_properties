module SmartProperties
  Initializer = SmartProperties::Plugin.new(:include) do
    ##
    # Implements a key-value enabled constructor that acts as default
    # constructor for all {SmartProperties}-enabled classes. Positional arguments
    # or keyword arguments that do not correspond to a property are forwarded to
    # the super class constructor.
    #
    # @param [Hash] attrs the set of attributes that is used for initialization
    #
    # @raise [SmartProperties::ConstructorArgumentForwardingError] when unknown arguments were supplied that could not be processed by the super class initializer either.
    # @raise [SmartProperties::InitializationError] when incorrect values were supplied or required values weren't been supplied.
    #
    def initialize(*args, &block)
      attrs = args.last.is_a?(Hash) ? args.pop.dup : {}
      properties = self.class.properties

      # Track missing properties
      missing_properties = []

      # Set values
      properties.each do |name, property|
        if attrs.key?(name)
          property.set(self, attrs.delete(name))
        elsif attrs.key?(name.to_s)
          property.set(self, attrs.delete(name.to_s))
        else
          missing_properties.push(property)
        end
      end

      # Call the super constructor and forward unprocessed arguments
      begin
        attrs.empty? ? super(*args) : super(*args.dup.push(attrs))
      rescue ArgumentError
        raise SmartProperties::ConstructorArgumentForwardingError.new(args, attrs)
      end

      # Execute configuration block
      block.call(self) if block

      # Set default values for missing properties
      missing_properties.delete_if { |property| property.set_default(self) }

      # Recheck - cannot be done while assigning default values because
      # one property might depend on the default value of another property
      missing_properties.delete_if { |property| property.present?(self) || property.optional?(self) }

      raise SmartProperties::InitializationError.new(self, missing_properties) unless missing_properties.empty?
    end
  end
end
