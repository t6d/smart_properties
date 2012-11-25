module Matchers
  class SmartPropertyMatcher

    attr_reader :property_name
    attr_reader :instance

    def initialize(property_name)
      @property_name = property_name
    end

    def matches?(instance)
      @instance = instance
      smart_property_enabled? && is_smart_property?
    end

    def failure_message
      return "expected #{instance.class.name} to have a property named #{property_name}" if smart_property_enabled?
      return "expected #{instance.class.name} to be smart property enabled"
    end

    def negative_failure_message
      "expected #{instance.class.name} to not have a property named #{property_name}"
    end

    private

      def smart_property_enabled?
        instance.ancestors.include?(::SmartProperties)
      end

      def is_smart_property?
        instance.properties[property_name].kind_of?(::SmartProperties::Property)
      end

  end

  def has_smart_property(*args)
    SmartPropertyMatcher.new(*args)
  end

  alias :have_smart_property :has_smart_property
end

RSpec.configure do |spec|
  spec.include(Matchers)
end