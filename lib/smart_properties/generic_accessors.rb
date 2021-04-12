module SmartProperties
  module GenericAccessors
    def [](name)
      return if name.nil?
      name = name.to_sym
      reader = self.class.properties[name].reader
      public_send(reader) if self.class.properties.key?(name)
    end

    def []=(name, value)
      return if name.nil?
      public_send(:"#{name.to_sym}=", value) if self.class.properties.key?(name)
    end
  end
end
