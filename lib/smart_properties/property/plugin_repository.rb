module SmartProperties
	class Property
		class PluginRepository
			def self.build_runtime(*plugins)
				new.build_runtime(*plugins)
			end

			def build_runtime(*plugins)
				Class.new(BaseRuntime) do
					define_method(:initialize) do |**config|
						configured_plugins = plugins.map do |plugin|
							next unless config.key?(plugin.configuration_key)

							plugin.new(
								config.fetch(:property),
								config[plugin.configuration_key]
							)
						end
						.compact

						super(plugins: configured_plugins, **config.slice(:default, :instance_variable_name, :property))
					end
				end
			end
		end
	end
end
