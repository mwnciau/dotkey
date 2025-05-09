require "test_case"
require "benchmark/ips"

class BenchmarkTest < TestCase
  # Benchmark is disabled by default. Remove the leading underscore to run.
  def _test_get_performance
    object = {a: {b: {c: {d: {e: {f: {g: [[[1]]]}}}}}}}

    assert_equal 1, DotKey.get(object, "a.b.c.d.e.f.g.0.0.0")
    assert_equal 1, object.dig(:a, :b, :c, :d, :e, :f, :g, 0, 0, 0)
    assert_equal 1, object[:a][:b][:c][:d][:e][:f][:g][0][0][0]
    assert_equal 1, object.fetch(:a).fetch(:b).fetch(:c).fetch(:d).fetch(:e).fetch(:f).fetch(:g).fetch(0).fetch(0).fetch(0)

    Benchmark.ips do |bm|
      bm.report("dotkey") { DotKey.get(object, "a.b.c.d.e.f.g.0.0.0") }
      bm.report("dig") { object.dig(:a, :b, :c, :d, :e, :f, :g, 0, 0, 0) }
      bm.report("brackets") { object[:a][:b][:c][:d][:e][:f][:g][0][0][0] }
      bm.report("fetch") { object.fetch(:a).fetch(:b).fetch(:c).fetch(:d).fetch(:e).fetch(:f).fetch(:g).fetch(0).fetch(0).fetch(0) }
      bm.compare!
    end
  end

  # Benchmark is disabled by default. Remove the leading underscore to run.
  # Rails needs to be installed to run this benchmark
  def _test_indifferent_get_performance
    require "active_support/core_ext/hash/indifferent_access"

    object = {a: {"b" => {c: {"d" => {e: {"f" => {g: [[[1]]]}}}}}}}
    indifferent = ActiveSupport::HashWithIndifferentAccess.new(
      {a: {"b" => {c: {"d" => {e: {"f" => {g: [[[1]]]}}}}}}},
    )

    assert_equal 1, DotKey.get(indifferent, "a.b.c.d.e.f.g.0.0.0")
    assert_equal 1, indifferent.dig(:a, :b, :c, :d, :e, :f, :g, 0, 0, 0)
    assert_equal 1, indifferent[:a][:b][:c][:d][:e][:f][:g][0][0][0]
    assert_equal 1, indifferent.fetch(:a).fetch(:b).fetch(:c).fetch(:d).fetch(:e).fetch(:f).fetch(:g).fetch(0).fetch(0).fetch(0)

    Benchmark.ips do |bm|
      bm.report("dotkey") { DotKey.get(object, "a.b.c.d.e.f.g.0.0.0") }
      bm.report("indifferent dotkey") { DotKey.get(indifferent, "a.b.c.d.e.f.g.0.0.0") }
      bm.report("indifferent dig") { indifferent.dig(:a, :b, :c, :d, :e, :f, :g, 0, 0, 0) }
      bm.report("indifferent brackets") { indifferent[:a][:b][:c][:d][:e][:f][:g][0][0][0] }
      bm.report("indifferent fetch") { indifferent.fetch(:a).fetch(:b).fetch(:c).fetch(:d).fetch(:e).fetch(:f).fetch(:g).fetch(0).fetch(0).fetch(0) }
      bm.compare!
    end
  end

  # Benchmark is disabled by default. Remove the leading underscore to run.
  def _test_set_performance
    Benchmark.ips do |bm|
      bm.report("dotkey set") {
        data = {a: {b: {c: {d: [[]]}}}}
        DotKey.set!(data, "a.b.c.d.0.0", 1)
        assert_equal({a: {b: {c: {d: [[1]]}}}}, data)
      }
      bm.report("dotkey set with missing intermediate values") {
        data = {}
        DotKey.set!(data, "a.b.c.d.0.0", 1)
        assert_equal({a: {b: {c: {d: [[1]]}}}}, data)
      }
      bm.report("brackets set") {
        data = {a: {b: {c: {d: [[]]}}}}
        data[:a][:b][:c][:d][0][0] = 1
        assert_equal({a: {b: {c: {d: [[1]]}}}}, data)
      }
      bm.report("brackets set with missing intermediate values") {
        data = {}
        data[:a] ||= {}
        data[:a][:b] ||= {}
        data[:a][:b][:c] ||= {}
        data[:a][:b][:c][:d] ||= []
        data[:a][:b][:c][:d][0] ||= []
        data[:a][:b][:c][:d][0][0] = 1
        assert_equal({a: {b: {c: {d: [[1]]}}}}, data)
      }
      bm.compare!
    end
  end
end
