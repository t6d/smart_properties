module SmartProperties
  module Plugins
    Equality = SmartProperties::Plugin.new(:include) do
      def ==(other)
        other.class == self.class &&
          self.class.properties.all? { |_, property| self.send(property.reader) == other.send(property.reader) }
      end
    end
  end
end
