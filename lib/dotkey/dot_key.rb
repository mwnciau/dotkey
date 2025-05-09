class DotKey
  class InvalidTypeError < StandardError; end

  class << self
    attr_writer :delimiter

    def delimiter
      defined?(@delimiter) ? @delimiter : "."
    end

    # = \get
    # Retrieves a value from a data structure (Hash, Array, or a nested combination) using
    # a dot-delimited key.
    #
    #   data = {a: {b: [1, 2]}, "c" => [{d: 3}, {e: 4}]}
    #
    #   DotKey.get(data, "a")       #=> {b: [1, 2]}
    #   DotKey.get(data, "a.b")     #=> [1, 2]
    #   DotKey.get(data, "a.b.0")   #=> 1
    #   DotKey.get(data, "c.0.d")   #=> 3
    #
    # If any values along the path are <tt>nil</tt>, <tt>nil</tt> is returned. However, if
    # a key along the path refers to a structure that is neither a Hash nor an Array, an
    # error is raised.
    #
    #   # `b.c` is nil so the result is nil
    #   DotKey.get({b: {}}, "b.c.d")        #=> nil
    #
    #   # `c` is not a valid key for an Array, so an error is raised
    #   DotKey.get({b: []}, "b.c.d")        #=> raises DotKey::InvalidTypeError
    #
    #   # `0` is a valid key but is nil so the result is nil
    #   DotKey.get({b: []}, "b.0.d")        #=> nil
    #
    #   # Strings cannot be traversed so an error is raised
    #   DotKey.get({a: "a string"}, "a.b")  #=> raises DotKey::InvalidTypeError
    #
    # This behaviour can be disabled by specifying the `raise_on_invalid` parameter:
    #
    #   DotKey.get({b: []}, "b.c.d", raise_on_invalid: false)        #=> nil
    #   DotKey.get({a: "a string"}, "a.b", raise_on_invalid: false)  #=> nil
    #
    # @param data [Hash,Array] The root data structure
    # @param key [String,Symbol] A dot-delimited string or symbol representing the path to be resolved.
    # @param raise_on_invalid [Boolean] A boolean indicating whether to raise an <tt>InvalidTypeError</tt> if a key path cannot be resolved due to an incompatible type. Defaults to <tt>true</tt>.
    # @return The value at the specified key path. Returns <tt>nil</tt> if any part of the path is missing or nil.
    # @raise [InvalidTypeError] If the key cannot be resolved due to an invalid type along the path, and <tt>raise_on_invalid</tt> is <tt>true</tt>.
    def get(data, key, raise_on_invalid: true)
      key_parts = key.to_s.split(delimiter)
      current = data

      key_parts.each do |key_part|
        if current.is_a?(Hash)
          current = current[key_part] || current[key_part.to_sym]
        elsif current.is_a?(Array)
          current = begin
            current[Integer(key_part)]
          rescue ArgumentError
            if raise_on_invalid
              raise InvalidTypeError.new "Unable to consume key #{key_part} on #{current.class}"
            end
          end
        elsif current.nil?
          return nil
        elsif raise_on_invalid
          raise InvalidTypeError.new "Unable to consume key #{key_part} on #{current.class}"
        else
          return nil
        end
      end

      current
    end

    # = \get_all
    # Retrieves all matching values from a data structure (Hash, Array, or a nested
    # combination) using a dot-delimited key.
    #
    # <tt>*</tt> and <tt>**</tt> can be used as wildcards for Array items and Hash keys
    # respectively:
    #
    #   data = {a: [{b: 1}, {b: 2, c: 3}], d: [4, 5]}
    #
    #   DotKey.get_all(data, "a.0.b") #=> {"a.0.b" => 1}
    #
    #   # Use `*` as a wildcard for Array indexes
    #   DotKey.get_all(data, "a.*.b") #=> {"a.0.b" => 1, "a.1.b" => 2}
    #
    #   # Use `**` as a wildcard for Hash keys
    #   DotKey.get_all(data, "a.1.**") #=> {"a.1.b" => 2, "a.1.c" => 3}
    #
    #   DotKey.get_all(data, "**.*") #=> {"a.0" => {b: 1}, "a.1" => {b: 2, c: 3}, "d.0" => 4, "d.1" => 5}
    #
    # If any values along the path are <tt>nil</tt>, <tt>nil</tt> is returned. However,
    # if a key along the path refers to a structure that is neither a Hash nor an Array,
    # an error is raised.
    #
    #   # `b.c` is nil so the result is nil
    #   DotKey.get({b: {}}, "b.c.d")        #=> nil
    #
    #   # `c` is not a valid key for an Array, so an error is raised
    #   DotKey.get({b: []}, "b.c.d")        #=> raises DotKey::InvalidTypeError
    #
    #   # `0` is a valid key for an array, but is nil so the result is nil
    #   DotKey.get({b: []}, "b.0.d")        #=> nil
    #
    #   # Strings cannot be traversed so an error is raised
    #   DotKey.get({a: "a string"}, "a.b")  #=> raises DotKey::InvalidTypeError
    #
    # This behaviour can be disabled by specifying the <tt>raise_on_invalid</tt> parameter.
    #
    #   DotKey.get({b: []}, "b.c.d", raise_on_invalid: false)        #=> nil
    #   DotKey.get({a: "a string"}, "a.b", raise_on_invalid: false)  #=> nil
    #
    # Missing values are included in the result as <tt>nil</tt> values, but these can be
    # omitted by specifying the <tt>include_missing</tt> parameter.
    #
    #   data = {a: [{b: 1}, {b: 2, c: 3}], d: 4}
    #
    #   DotKey.get_all(data, "a.*.c")                         #=> {"a.0.c" => nil, "a.1.c" => 3}
    #   DotKey.get_all(data, "a.*.c", include_missing: false) #=> {"a.1.c" => 3}
    #
    #   # This behaviour also affects `nil` values from invalid paths
    #   DotKey.get_all(data, "d.*", raise_on_invalid: false) #=> {"d.*" => nil}
    #   DotKey.get_all(data, "d.*", raise_on_invalid: false, include_missing: false) #=> {}
    #
    #   # Note that existing `nil` values are still included even when `include_missing` is false
    #   DotKey.get_all({a: nil}, "**", include_missing: false) #=> {"a" => nil})
    #
    # @param data [Hash,Array] The root data structure
    # @param key [String,Symbol] A dot-delimited string or symbol representing the path to be resolved. <tt>*</tt> and <tt>**</tt> can be used as wildcards for Array items and Hash keys respectively.
    # @param include_missing [Boolean] A boolean indicating whether to include missing keys with <tt>nil</tt> values when a part of the key path does not exist. Defaults to <tt>true</tt>.
    # @param raise_on_invalid [Boolean] A boolean indicating whether to raise an <tt>InvalidTypeError</tt> if a key path cannot be resolved due to an incompatible type. Defaults to <tt>true</tt>.
    # @return [Hash] A Hash mapping the fully qualified resolved key paths to their corresponding values. If partial matches or missing keys are permitted, values may include <tt>nil</tt>.
    # @raise [InvalidTypeError] If the key cannot be resolved due to an invalid type along the path, and <tt>raise_on_invalid</tt> is <tt>true</tt>.
    def get_all(data, key, include_missing: true, raise_on_invalid: true)
      key_parts = key.to_s.split(delimiter)
      values = {"" => data}

      key_parts.each do |key|
        key_as_int = nil

        values = if key == "*"
          values.each_with_object({}) do |(parent_key, array), object|
            key_prefix = (parent_key == "") ? "" : "#{parent_key}#{delimiter}"
            if array.is_a? Array
              array.each_with_index do |item, index|
                object["#{key_prefix}#{index}"] = item
              end
            elsif raise_on_invalid
              raise InvalidTypeError.new "Expected #{parent_key} to be an Array, but got #{array.class}"
            elsif include_missing
              object["#{key_prefix}*"] = nil
            end
          end
        elsif key == "**"
          values.each_with_object({}) do |(parent_key, hash), object|
            key_prefix = (parent_key == "") ? "" : "#{parent_key}#{delimiter}"
            if hash.is_a? Hash
              hash.each do |hash_key, item|
                object["#{key_prefix}#{hash_key}"] = item
              end
            elsif raise_on_invalid
              raise InvalidTypeError.new "Expected #{parent_key} to be a Hash, but got #{hash.class}"
            elsif include_missing
              object["#{key_prefix}**"] = nil
            end
          end
        else
          values.each_with_object({}) do |(parent_key, val), object|
            key_prefix = (parent_key == "") ? "" : "#{parent_key}#{delimiter}"

            if val.is_a?(Hash)
              if val.has_key?(key) || val.has_key?(key.to_sym)
                object["#{key_prefix}#{key}"] = val[key] || val[key.to_sym]
              elsif include_missing
                object["#{key_prefix}#{key}"] = nil
              end
            elsif val.is_a?(Array) && key_as_int != :invalid
              begin
                key_as_int ||= Integer(key)

                if val.length > key_as_int
                  object["#{key_prefix}#{key}"] = val[key_as_int]
                elsif include_missing
                  object["#{key_prefix}#{key}"] = nil
                end
              rescue ArgumentError
                key_as_int = :invalid

                if raise_on_invalid
                  raise InvalidTypeError.new "Expected #{key} to be an array key for Array #{parent_key}"
                elsif include_missing
                  object["#{key_prefix}#{key}"] = nil
                end
              end
            elsif raise_on_invalid
              if val.is_a?(Array) && key_as_int == :invalid
                raise InvalidTypeError.new "Expected #{key} to be an array key for Array #{parent_key}"
              else
                raise InvalidTypeError.new "Expected #{parent_key} to be a Hash or Array, but got #{val.class}"
              end
            elsif include_missing
              object["#{key_prefix}#{key}"] = nil
            end
          end
        end
      end

      values
    end

    # = \flatten
    # Converts a nested structure into a flat Hash, with the dot-delimited path to the
    # value as the key.
    #
    #   DotKey.flatten({a: {b: [1, 2]}, "c" => [{d: 3}, {e: 4}]})
    #   #=> {
    #   #   "a.b.0" => 1,
    #   #   "a.b.1" => 2,
    #   #   "c.0.d" => 3,
    #   #   "c.1.e" => 4,
    #   # }
    #
    # @param data [Hash, Array] The nested structure of Hashes and Arrays to be flattened.
    # @return [Hash] A flattened Hash representation of the structure where keys are the dot-delimited paths to the values.
    def flatten(data)
      _flatten(data, "")
    end

    private def _flatten(data, prefix)
      result = {}

      if data.is_a?(Hash)
        data.each do |key, value|
          path = (prefix == "") ? key.to_s : "#{prefix}#{delimiter}#{key}"
          result.merge! _flatten(value, path)
        end
      elsif data.is_a?(Array)
        data.each_with_index do |item, index|
          path = (prefix == "") ? index.to_s : "#{prefix}#{delimiter}#{index}"
          result.merge! _flatten(item, path)
        end
      else
        return {prefix => data}
      end

      result
    end

    # = \set!
    # Sets a value in a data structure (Hash, Array, or a nested combination) using a
    # dot-delimited key.
    #
    #  data = {a: {b: [1]}}
    #  DotKey.set!(data, "a.b.0", "a")
    #  DotKey.set!(data, "a.b.1", "b")
    #  DotKey.set!(data, "c", "d")
    #  data #=> {a: {b: ["a", "b"]}, :c => "d"}
    #
    # Intermediate structures are created as needed when traversing a path that includes
    # missing elements.
    #
    #  data = {}
    #  DotKey.set!(data, "a.b.c.0", 42)
    #  data #=> {a: {b: {c: [42]}}}
    #
    #  DotKey.set!(data, "a.b.c.2", 44)
    #  data #=> {a: {b: {c: [42, nil, 44]}}}
    #
    # By default, keys are created as symbols, but string keys can by specified using the
    # <tt>string_keys</tt> parameter.
    #
    #  data = {}
    #  DotKey.set!(data, "a", :symbol)
    #  DotKey.set!(data, "b", "string", string_keys: true)
    #  data #=> {a: :symbol, "b" => "string"}
    #
    # If a key along the path refers to a structure that is neither a Hash nor an Array,
    # an error is raised.
    #
    #  data = {a: "string"}
    #  DotKey.set!(data, "a.b", 42) #=> raises `DotKey::InvalidTypeError`
    #
    # @param data [Hash, Array] The root data structure.
    # @param key [String, Symbol] A dot-delimited string or symbol representing the path to be set.
    # @param value [Object] The value to set at the specified key path.
    # @param string_keys [Boolean] If true, keys will be created as strings
    # @raise [DotKey::InvalidTypeError] If the key cannot be resolved due to an invalid type along the path.
    def set!(data, key, value, string_keys: false)
      key_parts = key.to_s.split(delimiter)
      current = data

      key_parts.each_with_index do |next_key, i|
        break if i == key_parts.length - 1

        if current.is_a?(Hash)
          next_value = current[next_key] || current[next_key.to_sym]
        elsif current.is_a?(Array) && next_key.match?(/\A\d+\z/)
          next_key = begin
            Integer(next_key)
          rescue ArgumentError
            raise InvalidTypeError.new "Unable to consume key #{next_key}, expecting an integer"
          end

          next_value = current[next_key]
        else
          raise InvalidTypeError.new "Unable to consume key #{next_key}, expecting a Hash or Array, but got #{current.class}"
        end

        current = if next_value.is_a?(Hash) || next_value.is_a?(Array)
          next_value
        elsif next_value.nil?
          if key_parts[i + 1].match?(/\A\d+\z/)
            (current[(next_key.is_a?(Integer) || string_keys) ? next_key : next_key.to_sym] = [])
          else
            (current[(next_key.is_a?(Integer) || string_keys) ? next_key : next_key.to_sym] = {})
          end
        else
          raise InvalidTypeError.new "Invalid type for key #{next_key}, expecting a Hash, Array or nil, but got #{next_value.class}"
        end
      end

      last_key = key_parts.last
      if current.is_a?(Hash)
        last_key = if string_keys
          current.has_key?(last_key.to_sym) ? last_key.to_sym : last_key
        else
          current.has_key?(last_key) ? last_key : last_key.to_sym
        end

        current[last_key] = value
      elsif current.is_a?(Array)
        next_key = begin
          Integer(last_key)
        rescue ArgumentError
          raise InvalidTypeError.new "Unable to consume key #{last_key}, expecting an integer for Array index"
        end

        current[next_key] = value
      else
        raise InvalidTypeError.new "Unable to consume key #{last_key}, expecting a Hash or Array, but got #{current.class}"
      end
    end

    # = \delete!
    # Removes a value from a data structure (Hash, Array, or a nested combination) using
    # a dot-delimited key and returns the deleted value.
    #
    #   data = {a: {b: [1, 2]}, "c" => [{d: 3}, {e: 4}]}
    #
    #   DotKey.delete!(data, "a.b.0")   #=> 1
    #   data #=> {a: {b: [2]}, "c" => [{d: 3}, {e: 4}]}
    #
    #   DotKey.delete!(data, "c.0.d")   #=> 3
    #   data #=> {a: {b: [2]}, "c" => [{}, {e: 4}]}
    #
    # If any values along the path are <tt>nil</tt>, nothing happens and <tt>nil</tt> is
    # returned. However, if a key along the path refers to a structure that is neither a
    # Hash nor an Array, an error is raised.
    #
    #   # `b.c` is nil so the result is nil
    #   DotKey.delete!({b: {}}, "b.c.d")        #=> nil
    #
    #   # `c` is not a valid key for an Array, so an error is raised
    #   DotKey.delete!({b: []}, "b.c.d")        #=> raises DotKey::InvalidTypeError
    #
    #   # `0` is a valid key but is nil so the result is nil
    #   DotKey.delete!({b: []}, "b.0.d")        #=> nil
    #
    #   # Strings cannot be traversed so an error is raised
    #   DotKey.delete!({a: "a string"}, "a.b")  #=> raises DotKey::InvalidTypeError
    #
    # This behaviour can be disabled by specifying the `raise_on_invalid` parameter:
    #
    #   DotKey.delete!({b: []}, "b.c.d", raise_on_invalid: false)        #=> nil
    #   DotKey.delete!({a: "a string"}, "a.b", raise_on_invalid: false)  #=> nil
    #
    # @param data [Hash,Array] The root data structure
    # @param key [String,Symbol] A dot-delimited string or symbol representing the path to the value to be deleted.
    # @param raise_on_invalid [Boolean] A boolean indicating whether to raise an <tt>InvalidTypeError</tt> if a key path cannot be resolved due to an incompatible type. Defaults to <tt>true</tt>.
    # @return The deleted value at the specified key path. Returns <tt>nil</tt> if any part of the path is missing or nil.
    # @raise [InvalidTypeError] If the key cannot be resolved due to an invalid type along the path, and <tt>raise_on_invalid</tt> is <tt>true</tt>.
    def delete!(data, key, raise_on_invalid: true)
      key_parts = key.to_s.split(delimiter)
      current = data

      key_parts.each_with_index do |key_part, i|
        break if i == key_parts.length - 1

        if current.is_a?(Hash)
          current = current[key_part] || current[key_part.to_sym]
        elsif current.is_a?(Array)
          current = begin
            current[Integer(key_part)]
          rescue ArgumentError
            if raise_on_invalid
              raise InvalidTypeError.new "Expected #{key_part} to be an array key"
            end
          end
        elsif current.nil?
          return nil
        elsif raise_on_invalid
          raise InvalidTypeError.new "Unable to consume key #{key_part} on #{current.class}"
        else
          return nil
        end
      end

      last_key = key_parts.last
      if current.is_a?(Hash)
        current.delete(current.has_key?(last_key) ? last_key : last_key.to_sym)
      elsif current.is_a?(Array)
        begin
          current.delete_at Integer(last_key)
        rescue ArgumentError
          if raise_on_invalid
            raise InvalidTypeError.new "Expected #{last_key} to be an array key"
          end
        end
      elsif current.nil?
        nil
      elsif raise_on_invalid
        raise InvalidTypeError.new "Unable to consume key #{last_key} on #{current.class}"
      end
    end
  end
end
