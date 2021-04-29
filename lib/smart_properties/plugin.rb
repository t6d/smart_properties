module SmartProperties
  class Plugin < Module
    attr_reader :type

    def initialize(type, &block)
      raise ArgumentError, "Unkown plugin type" unless [:include, :extend].include?(type)
      @type = type
      super(&block)
    end

    def attach(target_class)
      target_class.send(type, self)
    end
  end
end
