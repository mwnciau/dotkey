require "test_case"

class DotKeyTest < TestCase
  def test_get_hash
    assert_equal 1, DotKey.get({a: 1}, "a")
    assert_equal({b: {c: 1}}, DotKey.get({a: {b: {c: 1}}}, "a"))
    assert_equal({c: 1}, DotKey.get({a: {b: {c: 1}}}, "a.b"))
    assert_equal(1, DotKey.get({a: {b: {c: 1}}}, "a.b.c"))

    assert_nil DotKey.get({}, "a")
    assert_nil DotKey.get({}, "a.b")
    assert_nil DotKey.get({a: {}}, "b")
  end

  def test_get_array
    assert_equal(1, DotKey.get([1, 2, 3], "0"))
    assert_equal(1, DotKey.get([[1, 2]], "0.0"))
    assert_equal(2, DotKey.get([[1, 2]], "0.1"))

    assert_nil DotKey.get([], "0")
    assert_nil DotKey.get([], "0.1")
    assert_nil DotKey.get([[1, 2]], "0.2")
  end

  def test_get_mixed
    assert_equal(2, DotKey.get({a: [1, 2, 3]}, "a.1"))
    assert_equal(1, DotKey.get({a: [{c: [0, {d: 1}]}]}, "a.0.c.1.d"))
  end

  def test_get_mixed_keys
    assert_equal 1, DotKey.get({a: 1}, :a)
    assert_equal 1, DotKey.get({"a" => 1}, :a)
    assert_equal 1, DotKey.get({"a" => 1}, "a")

    assert_equal(1, DotKey.get({a: {"1": 1}}, "a.1"))
    assert_equal(1, DotKey.get({a: [0, 1]}, "a.1"))
  end

  def test_get_invalid
    assert_raises(DotKey::InvalidTypeError) { DotKey.get("", "a") }
    assert_raises(DotKey::InvalidTypeError) { DotKey.get({a: ""}, "a.b") }
    assert_raises(DotKey::InvalidTypeError) { DotKey.get({a: []}, "a.b") }
    assert_raises(DotKey::InvalidTypeError) { DotKey.get({a: 1}, "a.b") }

    assert_nil DotKey.get("", "a", raise_on_invalid: false)
    assert_nil DotKey.get({a: ""}, "a.b", raise_on_invalid: false)
    assert_nil DotKey.get({a: []}, "a.b", raise_on_invalid: false)
    assert_nil DotKey.get({a: 1}, "a.b", raise_on_invalid: false)
  end

  def test_get_readme
    data = {a: {b: [1, 2]}, "c" => [{d: 3}, {e: 4}]} # rubocop:disable Style/HashSyntax

    assert_equal({b: [1, 2]}, DotKey.get(data, "a"))
    assert_equal [1, 2], DotKey.get(data, "a.b")
    assert_equal 1, DotKey.get(data, "a.b.0")
    assert_equal 3, DotKey.get(data, "c.0.d")

    assert_nil DotKey.get({b: {}}, "b.c.d")
    assert_raises(DotKey::InvalidTypeError) { DotKey.get({b: []}, "b.c.d") }
    assert_nil DotKey.get({b: []}, "b.0.d")
    assert_raises(DotKey::InvalidTypeError) { DotKey.get({a: "a string"}, "a.b") }

    assert_nil DotKey.get({b: []}, "b.c.d", raise_on_invalid: false)
    assert_nil DotKey.get({a: "a string"}, "a.b", raise_on_invalid: false)
  end

  def test_get_all
    assert_equal({"a" => 1}, DotKey.get_all({a: 1}, "a"))
    assert_equal({"a" => 1}, DotKey.get_all({"a" => 1}, "a"))
    assert_equal({"0" => 1}, DotKey.get_all([1], "0"))
    assert_equal({"0" => 1}, DotKey.get_all({"0": 1}, "0"))

    assert_equal({"a" => nil}, DotKey.get_all({}, "a"))
    assert_equal({}, DotKey.get_all({}, "a", include_missing: false))
    assert_equal({"0" => nil}, DotKey.get_all([], "0"))
    assert_equal({}, DotKey.get_all([], "0", include_missing: false))
    assert_equal({"a.b" => nil}, DotKey.get_all({a: nil}, "a.b"))
    assert_equal({}, DotKey.get_all({a: nil}, "a.b", include_missing: false))

    assert_equal({"a" => nil}, DotKey.get_all({a: nil}, "**"))
    assert_equal({"a" => nil}, DotKey.get_all({a: nil}, "**", include_missing: false))
  end

  def test_get_all_invalid
    assert_raises(DotKey::InvalidTypeError) { DotKey.get_all("", "a") }
    assert_raises(DotKey::InvalidTypeError) { DotKey.get_all([], "a") }

    assert_equal({"a" => nil}, DotKey.get_all("", "a", raise_on_invalid: false))
    assert_equal({}, DotKey.get_all("", "a", raise_on_invalid: false, include_missing: false))

    assert_equal({"a" => nil}, DotKey.get_all([], "a", raise_on_invalid: false))
    assert_equal({}, DotKey.get_all([], "a", raise_on_invalid: false, include_missing: false))
  end

  def test_get_all_array
    assert_equal(
      {"0" => 1, "1" => 2, "2" => 3},
      DotKey.get_all([1, 2, 3], "*"),
    )
    assert_equal(
      {"a.0" => 1, "a.1" => 2, "a.2" => 3},
      DotKey.get_all({a: [1, 2, 3]}, "a.*"),
    )
    assert_equal(
      {"a.0.b" => 1, "a.1.b" => 2, "a.2.b" => 3},
      DotKey.get_all({a: [{b: 1}, {b: 2}, {b: 3}]}, "a.*.b"),
    )

    assert_equal(
      {},
      DotKey.get_all([], "*"),
    )
    assert_equal(
      {},
      DotKey.get_all({a: []}, "a.*.b"),
    )

    assert_equal(
      {"a.0.b" => 1, "a.1.b" => 2, "a.2.b" => nil},
      DotKey.get_all({a: [{b: 1}, {b: 2}, {c: 3}]}, "a.*.b"),
    )
    assert_equal(
      {"a.0.b" => 1, "a.1.b" => 2},
      DotKey.get_all({a: [{b: 1}, {b: 2}, {c: 3}]}, "a.*.b", include_missing: false),
    )

    assert_equal(
      {"0" => 1, "1" => nil, "2" => 3},
      DotKey.get_all([1, nil, 3], "*", include_missing: false),
    )

    assert_equal(
      {"a.*" => nil},
      DotKey.get_all({a: nil}, "a.*"),
    )
  end

  def test_get_all_invalid_array
    assert_raises(DotKey::InvalidTypeError) { DotKey.get_all("", "*") }
    assert_raises(DotKey::InvalidTypeError) { DotKey.get_all({a: {}}, "a.*") }
    assert_raises(DotKey::InvalidTypeError) { DotKey.get_all([1, 2], "a") }
    assert_raises(DotKey::InvalidTypeError) { DotKey.get_all([{a: 1}, []], "*.a") }

    assert_equal({"*" => nil}, DotKey.get_all("", "*", raise_on_invalid: false))
    assert_equal({}, DotKey.get_all("", "*", raise_on_invalid: false, include_missing: false))

    assert_equal({"a.*" => nil}, DotKey.get_all({a: {}}, "a.*", raise_on_invalid: false))
    assert_equal({}, DotKey.get_all({a: {}}, "a.*", raise_on_invalid: false, include_missing: false))

    assert_equal({"a" => nil}, DotKey.get_all([1, 2], "a", raise_on_invalid: false))
    assert_equal({}, DotKey.get_all([1, 2], "a", raise_on_invalid: false, include_missing: false))

    assert_equal({"0.a" => 1, "1.a" => nil}, DotKey.get_all([{a: 1}, []], "*.a", raise_on_invalid: false))
    assert_equal({"0.a" => 1}, DotKey.get_all([{a: 1}, []], "*.a", raise_on_invalid: false, include_missing: false))
  end

  def test_get_all_hash
    assert_equal(
      {"a" => 1, "b" => 2, "c" => 3},
      DotKey.get_all({a: 1, b: 2, c: 3}, "**"),
    )
    assert_equal(
      {"0.a" => 1, "0.b" => 2, "0.c" => 3},
      DotKey.get_all([{a: 1, b: 2, c: 3}], "0.**"),
    )
    assert_equal(
      {"0.a.0" => 1, "0.b.0" => 2, "0.c.0" => 3},
      DotKey.get_all([{a: [1], b: [2], c: [3]}], "0.**.0"),
    )

    assert_equal(
      {},
      DotKey.get_all({}, "**"),
    )
    assert_equal(
      {},
      DotKey.get_all({a: {}}, "a.**.b"),
    )

    assert_equal(
      {"0.a.0" => 1, "0.b.0" => 2, "0.c.0" => nil},
      DotKey.get_all([{a: [1], b: [2], c: []}], "0.**.0"),
    )
    assert_equal(
      {"0.a.0" => 1, "0.b.0" => 2},
      DotKey.get_all([{a: [1], b: [2], c: []}], "0.**.0", include_missing: false),
    )

    assert_equal(
      {"a.**" => nil},
      DotKey.get_all({a: nil}, "a.**"),
    )
  end

  def test_get_all_invalid_hash
    assert_raises(DotKey::InvalidTypeError) { DotKey.get_all("", "**") }
    assert_raises(DotKey::InvalidTypeError) { DotKey.get_all({a: []}, "a.**") }

    assert_equal(
      {"**" => nil},
      DotKey.get_all("", "**", raise_on_invalid: false),
    )
    assert_equal(
      {},
      DotKey.get_all("", "**", raise_on_invalid: false, include_missing: false),
    )

    assert_equal(
      {"a.**" => nil},
      DotKey.get_all({a: []}, "a.**", raise_on_invalid: false),
    )
    assert_equal(
      {},
      DotKey.get_all({a: []}, "a.**", raise_on_invalid: false, include_missing: false),
    )
  end

  def test_get_all_mixed
    assert_equal(
      {"0.a" => 1, "1.b" => 2, "2.c" => 3},
      DotKey.get_all([{a: 1}, {b: 2}, {c: 3}], "*.**"),
    )
    assert_equal(
      {"0.a.a" => 1, "1.b.a" => 2, "2.c.a" => 3},
      DotKey.get_all([{a: {a: 1}}, {b: {a: 2}}, {c: {a: 3}}], "*.**.a"),
    )

    assert_equal(
      {"a.0" => 1, "b.0" => 2, "c.0" => 3},
      DotKey.get_all({a: [1], b: [2], c: [3]}, "**.*"),
    )
    assert_equal(
      {"a.0.a" => 1, "b.0.a" => 2, "c.0.a" => 3},
      DotKey.get_all({a: [{a: 1}], b: [{a: 2}], c: [{a: 3}]}, "**.*.a"),
    )
  end

  def test_get_all_invalid_mixed
    assert_equal(
      {"a.*.**" => nil},
      DotKey.get_all({a: {}}, "a.*.**", raise_on_invalid: false),
    )
    assert_equal(
      {},
      DotKey.get_all({a: {}}, "a.*.**", raise_on_invalid: false, include_missing: false),
    )

    assert_equal(
      {"a.**.*" => nil},
      DotKey.get_all({a: []}, "a.**.*", raise_on_invalid: false),
    )
    assert_equal(
      {},
      DotKey.get_all({a: []}, "a.**.*", raise_on_invalid: false, include_missing: false),
    )
  end

  def test_get_all_readme
    data = {a: [{b: 1}, {b: 2, c: 3}], d: [4, 5]}

    assert_equal(
      {"a.0.b" => 1},
      DotKey.get_all(data, "a.0.b"),
    )

    assert_equal(
      {"a.0.b" => 1, "a.1.b" => 2},
      DotKey.get_all(data, "a.*.b"),
    )

    assert_equal(
      {"a.1.b" => 2, "a.1.c" => 3},
      DotKey.get_all(data, "a.1.**"),
    )

    assert_equal(
      {"a.0" => {b: 1}, "a.1" => {b: 2, c: 3}, "d.0" => 4, "d.1" => 5},
      DotKey.get_all(data, "**.*"),
    )

    data = {a: [{b: 1}, {b: 2, c: 3}], d: 4}

    assert_raises(DotKey::InvalidTypeError) { DotKey.get_all(data, "d.e") }
    assert_raises(DotKey::InvalidTypeError) { DotKey.get_all(data, "d.*") }
    assert_raises(DotKey::InvalidTypeError) { DotKey.get_all(data, "**.*") }

    assert_equal(
      {"a.0" => {b: 1}, "a.1" => {b: 2, c: 3}, "d.*" => nil},
      DotKey.get_all(data, "**.*", raise_on_invalid: false),
    )

    assert_equal(
      {"b.c.d" => nil},
      DotKey.get_all({b: {}}, "b.c.d"),
    )
    assert_raises(DotKey::InvalidTypeError) { DotKey.get_all({b: []}, "b.c.d") }
    assert_equal(
      {"b.0.d" => nil},
      DotKey.get_all({b: []}, "b.0.d"),
    )
    assert_raises(DotKey::InvalidTypeError) { DotKey.get_all({a: "a string"}, "a.b") }


    assert_equal(
      {"b.c.d" => nil},
      DotKey.get_all({b: []}, "b.c.d", raise_on_invalid: false),
    )
    assert_equal(
      {"a.b" => nil},
      DotKey.get_all({a: "a string"}, "a.b", raise_on_invalid: false),
    )
    assert_equal(
      {"a.0.c" => nil, "a.1.c" => 3},
      DotKey.get_all(data, "a.*.c"),
    )
    assert_equal(
      {"a.1.c" => 3},
      DotKey.get_all(data, "a.*.c", include_missing: false),
    )

    assert_equal(
      {"d.*" => nil},
      DotKey.get_all(data, "d.*", raise_on_invalid: false),
    )
    assert_equal(
      {},
      DotKey.get_all(data, "d.*", raise_on_invalid: false, include_missing: false),
    )

    assert_equal(
      {"a" => nil},
      DotKey.get_all({a: nil}, "**", include_missing: false),
    )
  end

  def test_flatten
    assert_equal({"a" => 1, "b" => 2, "c" => 3}, DotKey.flatten({a: 1, b: 2, c: 3}))
    assert_equal({"a" => 1, "b" => 2, "c" => 3}, DotKey.flatten({"a" => 1, "b" => 2, "c" => 3}))
    assert_equal({"a.b.c" => 1, "a.b.d" => 2}, DotKey.flatten({a: {b: {c: 1, d: 2}}}))

    assert_equal({"0" => 1, "1" => 2, "2" => 3}, DotKey.flatten([1, 2, 3]))
    assert_equal({"0.0" => 1, "0.1" => 2, "1.0" => 3, "1.1" => 4}, DotKey.flatten([[1, 2], [3, 4]]))

    assert_equal({"a.0" => 1, "a.1" => 2, "a.2" => 3}, DotKey.flatten({a: [1, 2, 3]}))
    assert_equal({"a.0.b" => 1, "a.1.b" => 2, "a.2.b" => 3}, DotKey.flatten({a: [{b: 1}, {b: 2}, {b: 3}]}))
  end

  def test_flatten_readme
    data = {a: {b: [1, 2]}, "c" => [{d: 3}, {e: 4}]} # rubocop:disable Style/HashSyntax

    assert_equal(
      {
        "a.b.0" => 1,
        "a.b.1" => 2,
        "c.0.d" => 3,
        "c.1.e" => 4,
      },
      DotKey.flatten(data),
    )
  end

  def assert_set(key, expected, value: 1, on: {}, string_keys: false)
    DotKey.set!(on, key, value, string_keys: string_keys)
    assert_equal(expected, on)
  end

  def test_set_hash
    assert_set("a", {a: 1})
    assert_set("a", {a: 1}, on: {a: 0})
    assert_set("a", {a: 1}, on: {a: {b: 1}})
    assert_set("a.b.c", {a: {b: {c: 1}}})
    assert_set("a.b.c", {a: {b: {c: 1}}}, on: {a: {}})
    assert_set("a.b.c", {a: {b: {c: 1}}}, on: {a: {b: {}}})

    # Other keys remain unchanged
    assert_set("a.b.c", {a: {b: {c: 1, f: 1}, e: 1}, d: 1}, on: {a: {b: {f: 1}, e: 1}, d: 1})
  end

  def test_set_array
    assert_set("0", [1], on: [])
    assert_set("0", [1], on: [0])
    assert_set("2", [1, 2, 1], on: [1, 2, 3])

    assert_set("0.0", [[1, 0]], on: [[0, 0]])
    assert_set("0.1", [[0, 1]], on: [[0, 0]])
    assert_set("1.0", [[0, 0], [1]], on: [[0, 0]])
    assert_set("0.0.1", [[[nil, 1]]], on: [])
  end

  def test_set_mixed_values
    assert_set("a.0", {a: [1]})
    assert_set("a.0", {a: {"0": 1}}, on: {a: {}})

    assert_set("a.0.c", {a: [{c: 1}]})
    assert_set("a.0.c.1.d", {a: [{c: [nil, {d: 1}]}]})
  end

  def test_set_string_keys
    # Existing keys are used
    assert_set("a.b.c", {"a" => {"b" => {"c" => 1}}}, on: {"a" => {"b" => {"c" => 0}}})
    assert_set("a.b.c", {a: {b: {c: 1}}}, on: {a: {b: {c: 0}}}, string_keys: true)

    # New keys are created as strings
    assert_set("a", {"a" => 1}, string_keys: true)
    assert_set("a.b.c", {"a" => {"b" => {"c" => 1}}}, string_keys: true)
    assert_set("a.b.c", {a: {b: {"c" => 1}}}, on: {a: {b: {}}}, string_keys: true)
  end

  def test_set_invalid
    assert_raises(DotKey::InvalidTypeError) { DotKey.set!("", "a", 1) }
    assert_raises(DotKey::InvalidTypeError) { DotKey.set!("", "a.b", 1) }
    assert_raises(DotKey::InvalidTypeError) { DotKey.set!([], "a", 1) }
    assert_raises(DotKey::InvalidTypeError) { DotKey.set!([], "a.b", 1) }
    assert_raises(DotKey::InvalidTypeError) { DotKey.set!({a: ""}, "a.b", 1) }
    assert_raises(DotKey::InvalidTypeError) { DotKey.set!({a: ""}, "a.b.c", 1) }
    assert_raises(DotKey::InvalidTypeError) { DotKey.set!({a: []}, "a.b", 1) }
    assert_raises(DotKey::InvalidTypeError) { DotKey.set!({a: []}, "a.b.c", 1) }
    assert_raises(DotKey::InvalidTypeError) { DotKey.set!({a: 1}, "a.b", 1) }
  end

  def test_set_readme
    data = {a: {b: [1]}}
    DotKey.set!(data, "a.b.0", "a")
    DotKey.set!(data, "a.b.1", "b")
    DotKey.set!(data, "c", "d")
    assert_equal({a: {b: ["a", "b"]}, c: "d"}, data)

    data = {}
    DotKey.set!(data, "a.b.c.0", 42)
    assert_equal({a: {b: {c: [42]}}}, data)

    DotKey.set!(data, "a.b.c.2", 44)
    assert_equal({a: {b: {c: [42, nil, 44]}}}, data)

    data = {}
    DotKey.set!(data, "a", :symbol)
    DotKey.set!(data, "b", "string", string_keys: true)
    assert_equal({a: :symbol, "b" => "string"}, data) # rubocop:disable Style/HashSyntax

    data = {a: "string"}
    assert_raises(DotKey::InvalidTypeError) { DotKey.set!(data, "a.b", 42) }
  end

  def test_delete_hash
    data = {a: 1}
    DotKey.delete!(data, "a")
    assert_equal({}, data)

    data = {"a" => 1}
    DotKey.delete!(data, "a")
    assert_equal({}, data)

    data = {a: {b: 1}}
    DotKey.delete!(data, "a.b")
    assert_equal({a: {}}, data)

    data = {a: {b: {c: 1}}}
    DotKey.delete!(data, "a.b.c")
    assert_equal({a: {b: {}}}, data)

    # Other keys remain unchanged
    data = {a: {b: {c: 1, f: 1}, e: 1}, d: 1}
    DotKey.delete!(data, "a.b.c")
    assert_equal({a: {b: {f: 1}, e: 1}, d: 1}, data)
  end

  def test_delete_array
    data = [1]
    DotKey.delete!(data, "0")
    assert_equal([], data)

    data = [[1, 2]]
    DotKey.delete!(data, "0.0")
    assert_equal([[2]], data)

    data = [[1, 2], [3, 4]]
    DotKey.delete!(data, "1")
    assert_equal([[1, 2]], data)
  end

  def test_delete_mixed
    data = {a: [1, 2]}
    DotKey.delete!(data, "a.0")
    assert_equal({a: [2]}, data)

    data = {a: [{b: 1}, {c: 2}]}
    DotKey.delete!(data, "a.0.b")
    assert_equal({a: [{}, {c: 2}]}, data)
  end

  def test_delete_invalid
    assert_raises(DotKey::InvalidTypeError) { DotKey.delete!({a: ""}, "a.b") }
    assert_raises(DotKey::InvalidTypeError) { DotKey.delete!({a: []}, "a.b") }
    assert_raises(DotKey::InvalidTypeError) { DotKey.delete!({a: 1}, "a.b") }

    # Non-existent paths return nil
    assert_nil(DotKey.delete!({}, "a"))
    assert_nil(DotKey.delete!({a: {}}, "a.b"))
    assert_nil(DotKey.delete!({a: {}}, "a.b.c"))
    assert_nil(DotKey.delete!({a: []}, "a.0"))
    assert_nil(DotKey.delete!({a: []}, "a.0.1"))

    # raise_on_invalid parameter works
    assert_nil(DotKey.delete!({a: ""}, "a.b", raise_on_invalid: false))
    assert_nil(DotKey.delete!({a: []}, "a.b", raise_on_invalid: false))
    assert_nil(DotKey.delete!({a: 1}, "a.b", raise_on_invalid: false))
  end

  def test_delete_readme
    data = {a: {b: [1, 2]}, "c" => [{d: 3}, {e: 4}]} # rubocop:disable Style/HashSyntax

    assert_equal(1, DotKey.delete!(data, "a.b.0"))
    assert_equal({a: {b: [2]}, "c" => [{d: 3}, {e: 4}]}, data) # rubocop:disable Style/HashSyntax

    assert_equal(3, DotKey.delete!(data, "c.0.d"))
    assert_equal({a: {b: [2]}, "c" => [{}, {e: 4}]}, data) # rubocop:disable Style/HashSyntax

    # `b.c` is nil so the result is nil
    assert_nil(DotKey.delete!({b: {}}, "b.c.d"))

    # `c` is not a valid key for an Array, so an error is raised
    assert_raises(DotKey::InvalidTypeError) { DotKey.delete!({b: []}, "b.c.d") }

    # `0` is a valid key but is nil so the result is nil
    assert_nil(DotKey.delete!({b: []}, "b.0.d"))

    # Strings cannot be traversed so an error is raised
    assert_raises(DotKey::InvalidTypeError) { DotKey.delete!({a: "a string"}, "a.b") }

    assert_nil(DotKey.delete!({b: []}, "b.c.d", raise_on_invalid: false))
    assert_nil(DotKey.delete!({a: "a string"}, "a.b", raise_on_invalid: false))
  end

  def test_configuration
    DotKey.delimiter = "_"

    assert_equal(1, DotKey.get({a: {b: [1]}}, "a_b_0"))

    assert_equal(
      {"a_b_0" => 1},
      DotKey.get_all({a: {b: [1]}}, "a_**_*"),
    )

    assert_equal(
      {"a_b_0" => 1},
      DotKey.flatten({a: {b: [1]}}),
    )

    data = {}
    DotKey.set!(data, "a_b_0", 1)
    assert_equal({a: {b: [1]}}, data)

    data = {a: {b: [1]}}
    DotKey.delete!(data, "a_b_0")
    assert_equal({a: {b: []}}, data)
  ensure
    DotKey.delimiter = "."
  end

  def test_example
    data = {users: [
      {name: "Alice", languages: ["English", "French"]},
      {name: "Bob", languages: ["German", "French"]},
    ]}

    DotKey.get(data, "users.0.name")
      #=> "Alice"

    DotKey.get_all(data, "users.*.languages.*").values.uniq
      #=> ["English", "French", "German"]

    DotKey.set!(data, "users.0", {name: "Charlie", languages: ["English"]})
    DotKey.delete!(data, "users.1")
    DotKey.flatten(data)
      #=> {"users.0.name" => "Charlie", "users.0.languages.0" => "English"}
  end
end
