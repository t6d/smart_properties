module RuboCop
  module Cop
    module SmartProperties
      class DefaultsPerInstance < Cop
        MSG = 'Use proc when defaults are mutable objects'

        def_node_matcher :property_definition?, <<-PATTERN
          (send nil? {:property} _ (hash $...))
        PATTERN

        def_node_matcher :default_option?, <<-PATTERN
          (pair (sym :default) !nil)
        PATTERN

        def_node_matcher :read_only?, <<-PATTERN
          (pair (sym :read_only) (true))
        PATTERN

        def_node_matcher :immutable_default?, <<-PATTERN
          (pair (sym :default) {({int float sym const} ...) (true) (false) (send _ :freeze)})
        PATTERN

        def_node_matcher :callable_default?, <<-PATTERN
          (pair (sym :default) (block ...))
        PATTERN

        def on_send(node)
          if options = property_definition?(node)
            check_options(options)
          end
        end

        private

        def check_options(options)
          return if options.none? { |o| default_option?(o) }
          return if options.any? { |o| read_only?(o) }

          default_value = default_option(options)

          unless immutable_default?(default_value) || callable_default?(default_value)
            add_offense(default_value, message: MSG)
          end
        end

        def default_option(options)
          options.find { |option| default_option?(option) }
        end
      end
    end
  end
end
