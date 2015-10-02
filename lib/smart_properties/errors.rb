module SmartProperties
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
end
