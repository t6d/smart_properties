module SmartProperties
  module Plugins
    GenericAccessors = SmartProperties::Plugin.new(:include) do
      def [](name)
        return if name.nil?
        reader = self.class.properties[name.to_sym]&.reader
        reader ?  public_send(reader) : super
      end

      def []=(name, value)
        return if name.nil?
        self.class.properties.key?(name) ? public_send(:"#{name.to_sym}=", value) : super
      end
    end
  end
end
