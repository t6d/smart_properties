module SmartProperties
  module Plugins
    HashSerialization = SmartProperties::Plugin.new(:include) do
      def self.without_optionals
        customize do
          def to_hash
            super.compact
          end
        end
      end

      def self.with_optionals
        self
      end

      def self.included(target)
        target.define_singleton_method(:to_proc) do
          ->(value) do
            initialize = target.method(:new).to_proc

            case value
            when Hash
              initialize[value]
            when Array
              value.map(&initialize)
            else
              raise ArgumentError, "Unexpected type: #{value.class}"
            end
          end
        end
      end

      def to_h
        to_hash
      end

      def to_hash
        is_hashable = ->(obj) { obj.respond_to?(:to_hash) }
        is_collection_of_hashables = ->(obj) { obj.is_a?(Enumerable) && obj.all?(&is_hashable) }

        self.class.properties.each.reduce({}) do |data, (_, property)|
          data.merge(property.name => self.send(property.reader).yield_self do |value|
            case value
            when is_collection_of_hashables
              value.map(&:to_hash)
            when is_hashable
              value.to_hash
            else
              value
            end
          end)
        end
      end
    end
  end
end
