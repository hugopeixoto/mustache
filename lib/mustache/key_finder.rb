class Mustache
  module KeyFinder
    # Finds a key in an object, using whatever method is most
    # appropriate. If the object is a hash, does a simple hash lookup.
    # If it's an object that responds to the key as a method call,
    # invokes that method. You get the idea.
    #
    # @param [Object] obj The object to perform the lookup on.
    # @param [String,Symbol] key The key whose value you want
    # @param [Object] default An optional default value, to return if the key is not found.
    #
    # @return [Object] The value of key in object if it is found, and default otherwise.
    #
    def self.find(obj, key, default)
      v = :__missing
      v = find_in_hash(obj.to_hash, key, v) if obj.respond_to?(:to_hash)

      return v unless :__missing == v

      key = to_tag(key)
      return default unless obj.respond_to?(key)

      meth = obj.method(key) rescue proc { obj.send(key) }
      meth.arity == 1 ? meth.to_proc : meth.call
    end

    private
    # If a class, we need to find tags (methods) per Parser::ALLOWED_CONTENT.
    def self.to_tag key
      key.to_s.tr('-','_').to_sym
    end

    # Fetches a hash key if it exists, or returns the given default.
    def self.find_in_hash(obj, key, default)
      obj.fetch key do
        obj.fetch key.to_s, default
      end
    end
  end
end
