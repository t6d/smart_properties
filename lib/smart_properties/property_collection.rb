module SmartProperties
  class PropertyCollection
    include Enumerable

    attr_reader :parent

    def initialize(parent = nil)
      @parent = parent
      @collection = {}
    end

    def []=(name, value)
      collection[name] = value
    end

    def [](name)
      collection_with_parent_collection[name]
    end

    def key?(name)
      collection_with_parent_collection.key?(name)
    end

    def keys
      collection_with_parent_collection.keys
    end

    def values
      collection_with_parent_collection.values
    end

    def each(&block)
      collection_with_parent_collection.each(&block)
    end

    protected

    attr_accessor :collection

    def collection_with_parent_collection
      parent.nil? ? collection : parent.collection.merge(collection)
    end
  end
end
