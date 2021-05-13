module SmartProperties
  module Plugins
    Bootstrap = SmartProperties::Plugin.new(:extend) do
      def included(target)
        super
        target.include(SmartProperties)
      end
    end
  end
end
