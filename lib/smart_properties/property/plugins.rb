module SmartProperties
	class Property
		Plugin = Struct.new(:property, :config) do
			private

			def null_object?(object)
				object.nil?
			rescue NoMethodError => error
				# BasicObject does not respond to #nil? by default, so we need to double
				# check if somebody implemented it and it fails internally or if the
				# error occured because the method is actually not present.

				# This is a workaround for the fact that #singleton_class is defined on Object, but not BasicObject.
				the_singleton_class = (class << object; self; end)

				if the_singleton_class.public_instance_methods.include?(:nil?)
					# object defines #nil?, but it raised NoMethodError,
					# something is wrong with the implementation, so raise the exception.
					raise error
				else
					# treat the object as truthy because we don't know better.
					false
				end
			end
		end

		class RequiredCheck < Plugin
			def self.configuration_key
				:required
			end

			def enabled?(scope)
				config.kind_of?(Proc) ? scope.instance_exec(&config) : !!config
			end

			def call(scope, value)
				return value unless enabled?(scope)
				raise MissingValueError.new(scope, property) if config && null_object?(value)
				value
			end
		end

		class Conversion < Plugin
			def self.configuration_key
				:converts
			end

			def call(scope, value)
				return value unless config
				return value if null_object?(value)

				case config
				when Symbol
					config.to_proc.call(value)
				else
					scope.instance_exec(value, &config)
				end
			end
		end

		class AcceptanceCheck < Plugin
			def self.configuration_key
				:accepts
			end

			def call(scope, value)
				return true if accepts?(scope, value)
				raise InvalidValueError.new(scope, property, value)
			end

			private

			def accepts?(scope, value)
				return true unless config
				return true if null_object?(value)

				if config.respond_to?(:to_proc)
					!!scope.instance_exec(value, &config)
				else
					Array(config).any? { |config| config === value }
				end
			end
		end
	end
end
