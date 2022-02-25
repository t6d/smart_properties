module SmartProperties
	class Property
		BaseRuntime = Struct.new(:plugins, :default, :instance_variable_name, :property, keyword_init: true) do
			def default(scope)
				self[:default].kind_of?(Proc) ? scope.instance_exec(&self[:default]) : self[:default].dup
			end

			def set(scope, value)
				scope.instance_variable_set(instance_variable_name, prepare(scope, value))
			end

			def set_default(scope)
				return false if present?(scope)

				default_value = default(scope)
				return false if null_object?(default_value)

				set(scope, default_value)
				true
			end

			def get(scope)
				return nil unless scope.instance_variable_defined?(instance_variable_name)
				scope.instance_variable_get(instance_variable_name)
			end

			def prepare(scope, value)
				plugins.reduce(value) { |value, plugin| plugin.call(scope, value) }
			end

			def to_h
				{
					accepter: self[:accepts],
					converter: self[:converts],
					default: self[:default],
					instance_variable_name: self[:instance_variable_name],
					required: self[:required],
					name: property.name,
					reader: property.reader,
				}
			end
		end
	end
end
