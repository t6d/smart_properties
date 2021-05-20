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

    def customize(&customizations)
      original_implementation = self
      self.class.new(type) do
        include original_implementation
        define_singleton_method(:included, &original_implementation.method(:included))
        module_eval(&customizations)
      end
    end
  end
end
