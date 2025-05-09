# DotKey

DotKey is a Ruby gem that allows you to easily interact with Ruby objects using dot notation.

## Getting started

Add DotKey to your Rails project by adding it to your Gemfile:

```shell
gem install dotkey
```

Or using bundler:

```shell
bundle add dotkey
```

## Usage

### get

Retrieves a value from a data structure (Hash, Array, or a nested combination) using a dot-delimited key.

```ruby
data = {a: {b: [1, 2]}, "c" => [{d: 3}, {e: 4}]}

DotKey.get(data, "a")       # => {b: [1, 2]}
DotKey.get(data, "a.b")     # => [1, 2]
DotKey.get(data, "a.b.0")   # => 1
DotKey.get(data, "c.0.d")   # => 3
```

If any values along the path are `nil`, `nil` is returned. However, trying to traverse something that is not a Hash or Array will cause an error:

```ruby
# `b.c` is nil so the result is nil
DotKey.get({b: {}}, "b.c.d")        # => nil

# `c` is not a valid key for an Array, so an error is raised
DotKey.get({b: []}, "b.c.d")        # => raises DotKey::InvalidTypeError

# `0` is a valid key for an array, but is nil so the result is nil
DotKey.get({b: []}, "b.0.d")        # => nil

# Strings cannot be traversed so an error is raised
DotKey.get({a: "a string"}, "a.b")  # => raises DotKey::InvalidTypeError
```

This behaviour can be disabled by specifying the `raise_on_invalid` parameter:

```ruby
DotKey.get({b: []}, "b.c.d", raise_on_invalid: false)        # => nil
DotKey.get({a: "a string"}, "a.b", raise_on_invalid: false)  # => nil
```

### get_all

Retrieves all matching values from a data structure (Hash, Array, or a nested combination) using a dot-delimited key with wildcards.

`*` and `**` can be used as wildcards for Array items and Hash keys respectively:

```ruby
data = {a: [{b: 1}, {b: 2, c: 3}], d: [4, 5]}

DotKey.get_all(data, "a.0.b") # => {"a.0.b" => 1}

# Use `*` as a wildcard for arrays
DotKey.get_all(data, "a.*.b") # => {"a.0.b" => 1, "a.1.b" => 2}

# Use `**` as a wildcard for Hashes
DotKey.get_all(data, "a.1.**") # => {"a.1.b" => 2, "a.1.c" => 3}

DotKey.get_all(data, "**.*") # => {"a.0" => {b: 1}, "a.1" => {b: 2, c: 3}, "d.0" => 4, "d.1" => 5}
```

If any values along the path are `nil`, `nil` is returned. However, trying to traverse something that is not a Hash or Array will cause an error:

```ruby
# `b.c` is nil so the result is nil
DotKey.get({b: {}}, "b.c.d")        # => nil

# `c` is not a valid key for an Array, so an error is raised
DotKey.get({b: []}, "b.c.d")        # => raises DotKey::InvalidTypeError

# `0` is a valid key for an array, but is nil so the result is nil
DotKey.get({b: []}, "b.0.d")        # => nil

# Strings cannot be traversed so an error is raised
DotKey.get({a: "a string"}, "a.b")  # => raises DotKey::InvalidTypeError
```

This behaviour can be disabled by specifying the `raise_on_invalid` parameter:

```ruby
DotKey.get({b: []}, "b.c.d", raise_on_invalid: false)        # => nil
DotKey.get({a: "a string"}, "a.b", raise_on_invalid: false)  # => nil
```

Missing values are included in the result as `nil` values, but these can be omitted by specifying the `include_missing` parameter:

```ruby
data = {a: [{b: 1}, {b: 2, c: 3}], d: 4}

DotKey.get_all(data, "a.*.c")                         # => {"a.0.c" => nil, "a.1.c" => 3}
DotKey.get_all(data, "a.*.c", include_missing: false) # => {"a.1.c" => 3}

# This behaviour also affects `nil` values from invalid paths
DotKey.get_all(data, "d.*", raise_on_invalid: false) # => {"d.*" => nil}
DotKey.get_all(data, "d.*", raise_on_invalid: false, include_missing: false) # => {}

# Note that existing `nil` values are still included even when `include_missing` is false
DotKey.get_all({a: nil}, "**", include_missing: false) #=> {"a" => nil})
```

### flatten

Converts a nested structure into a flat Hash, with the dot-delimited path to the value as the key.

```ruby
DotKey.flatten({a: {b: [1, 2]}, "c" => [{d: 3}, {e: 4}]})
# => {
#   "a.b.0" => 1,
#   "a.b.1" => 2,
#   "c.0.d" => 3,
#   "c.1.e" => 4,
# }
```

### set!

Sets a value in a data structure (Hash, Array, or a nested combination) using a dot-delimited key.

```ruby
data = {a: {b: [1]}}
DotKey.set!(data, "a.b.0", "a")
DotKey.set!(data, "a.b.1", "b")
DotKey.set!(data, "c", "d")
data #=> {a: {b: ["a", "b"]}, :c => "d"}
```

Intermediate structures are created as needed when traversing a path that includes
missing elements:

```ruby
data = {}
DotKey.set!(data, "a.b.c.0", 42)
data #=> {a: {b: {c: [42]}}}

DotKey.set!(data, "a.b.c.2", 44)
data #=> {a: {b: {c: [42, nil, 44]}}}
```

By default, keys are created as symbols, but string keys can by specified using the
`string_keys` parameter:

```ruby
data = {}
DotKey.set!(data, "a", :symbol)
DotKey.set!(data, "b", "string", string_keys: true)
data #=> {a: :symbol, "b" => "string"}
```

If a key along the path refers to a structure that is neither a Hash nor an Array,
an error is raised:

```ruby
data = {a: "string"}
DotKey.set!(data, "a.b", 42) #=> raises `DotKey::InvalidTypeError`
```

### delete!

Removes a value from a data structure (Hash, Array, or a nested combination) using a dot-delimited key and returns the deleted value.

```ruby
data = {a: {b: [1, 2]}, "c" => [{d: 3}, {e: 4}]}

DotKey.delete!(data, "a.b.0")   #=> 1
data #=> {a: {b: [2]}, "c" => [{d: 3}, {e: 4}]}

DotKey.delete!(data, "c.0.d")   #=> 3
data #=> {a: {b: [2]}, "c" => [{}, {e: 4}]}
```

If any values along the path are `nil`, nothing happens and `nil` is returned. However, if a key along the path refers to a structure that is neither a Hash nor an Array, an error is raised:

```ruby
# `b.c` is nil so the result is nil
DotKey.delete!({b: {}}, "b.c.d")        #=> nil

# `c` is not a valid key for an Array, so an error is raised
DotKey.delete!({b: []}, "b.c.d")        #=> raises DotKey::InvalidTypeError

# `0` is a valid key but is nil so the result is nil
DotKey.delete!({b: []}, "b.0.d")        #=> nil

# Strings cannot be traversed so an error is raised
DotKey.delete!({a: "a string"}, "a.b")  #=> raises DotKey::InvalidTypeError
```

This behaviour can be disabled by specifying the `raise_on_invalid` parameter:

```ruby
DotKey.delete!({b: []}, "b.c.d", raise_on_invalid: false)        #=> nil
DotKey.delete!({a: "a string"}, "a.b", raise_on_invalid: false)  #=> nil
```

## Configuration

The default delimiter for keys is a dot, `.`. However, this can be changed to any other String using the `DotKey.delimiter` option:

```ruby
DotKey.delimiter = "_"

DotKey.get({a: {b: [1]}}, "a_b_0") #=> 1
DotKey.flatten({a: {b: [1]}}) #=> {"a_b_0" => 1}
```

## Performance

Due to the parsing of string keys, DotKey won't be the most performant option when accessing data in nested objects:

```ruby
# Benchmarking DotKey.get vs native alternatives
object = {a: {b: {c: {d: {e: {f: {g: [[[1]]]}}}}}}}

Benchmark.ips do |bm|
  bm.report("dotkey") { DotKey.get(object, "a.b.c.d.e.f.g.0.0.0") }
  bm.report("dig") { object.dig(:a, :b, :c, :d, :e, :f, :g, 0, 0, 0) }
  bm.report("brackets") { object[:a][:b][:c][:d][:e][:f][:g][0][0][0] }
  bm.report("fetch") { object.fetch(:a).fetch(:b).fetch(:c).fetch(:d).fetch(:e).fetch(:f).fetch(:g).fetch(0).fetch(0).fetch(0) }
  bm.compare!
end

# brackets: 12132728.2 i/s
#      dig: 10368408.4 i/s - 1.17x  slower
#    fetch:  6080694.0 i/s - 2.00x  slower
#   dotkey:   494617.5 i/s - 24.53x  slower (!!)
```

However, DotKey excels at providing a concise and flexible approach to working with nested data structures:
it offers customisable handling of missing values and error conditions, while seamlessly supporting
both string and symbol keys without requiring explicit type conversion.

While much slower than the alternatives, it is still quick and efficient enough for most use cases. In fact, comparing `DotKey.get` again using Rails' HashWithIndifferentAccess, the performance is comparable to using `dig`:

```ruby
# Benchmarking DotKey.get vs alternatives using HashWithIndifferentAccess
object = {a: {"b" => {c: {"d" => {e: {"f" => {g: [[[1]]]}}}}}}}
indifferent = ActiveSupport::HashWithIndifferentAccess.new(
  {a: {"b" => {c: {"d" => {e: {"f" => {g: [[[1]]]}}}}}}},
)

Benchmark.ips do |bm|
  bm.report("dotkey") { DotKey.get(object, "a.b.c.d.e.f.g.0.0.0") }
  bm.report("indifferent dotkey") { DotKey.get(indifferent, "a.b.c.d.e.f.g.0.0.0") }
  bm.report("indifferent dig") { indifferent.dig(:a, :b, :c, :d, :e, :f, :g, 0, 0, 0) }
  bm.report("indifferent brackets") { indifferent[:a][:b][:c][:d][:e][:f][:g][0][0][0] }
  bm.report("indifferent fetch") { indifferent.fetch(:a).fetch(:b).fetch(:c).fetch(:d).fetch(:e).fetch(:f).fetch(:g).fetch(0).fetch(0).fetch(0) }
  bm.compare!
end

# indifferent brackets:  1738761.7 i/s
#    indifferent fetch:  1026543.3 i/s - 1.69x  slower
#               dotkey:   547557.6 i/s - 3.18x  slower
#      indifferent dig:   526314.7 i/s - 3.30x  slower
#   indifferent dotkey:   477155.6 i/s - 3.64x  slower
```

The performance for setting values is much more comparable, but with significantly more succinct code:

```
# brackets set:
#     431898.9 i/s
# brackets set with missing intermediate values:
#     394861.3 i/s - 1.09x  slower
# dotkey set:
#     212933.4 i/s - 2.03x  slower
# dotkey set with missing intermediate values:
#     168456.3 i/s - 2.56x  slower
```

See the [performance test suite](test/unit/benchmark_test.rb) for more details.
