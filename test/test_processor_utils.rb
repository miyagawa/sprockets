require 'minitest/autorun'
require 'sprockets/processor_utils'

require 'sprockets/cache'
require 'sprockets/coffee_script_processor'
require 'sprockets/uglifier_compressor'

class TestProcessorUtils < MiniTest::Test
  include Sprockets::ProcessorUtils

  def test_compose_nothing
    a = compose_processors()

    input = { data: " " }
    assert result = a.call(input)
    assert_equal " ", result[:data]
  end

  def test_compose_single_function
    a = proc { |input| { data: input[:data] + ",a" } }
    b = compose_processors(a)

    input = { data: " " }
    assert result = b.call(input)
    assert_equal " ,a", result[:data]
  end

  def test_compose_hash_return
    a = proc { |input| { data: input[:data] + ",a" } }
    b = proc { |input| { data: input[:data] + ",b" } }
    c = compose_processors(b, a)

    input = { data: " " }
    assert result = c.call(input)
    assert_equal " ,a,b", result[:data]
  end

  def test_compose_string_return
    a = proc { |input| input[:data] + ",a" }
    b = proc { |input| input[:data] + ",b" }
    c = compose_processors(b, a)

    input = { data: " " }
    assert result = c.call(input)
    assert_equal " ,a,b", result[:data]
  end

  def test_compose_noop_return
    a = proc { |input| input[:data] + ",a" }
    b = proc { |input| nil }
    c = compose_processors(a, b)
    d = compose_processors(a, b)

    input = { data: " " }
    assert result = c.call(input)
    assert_equal " ,a", result[:data]
    assert result = d.call(input)
    assert_equal " ,a", result[:data]
  end

  def test_compose_metadata
    a = proc { |input| { a: true } }
    b = proc { |input| { b: true } }
    c = compose_processors(a, b)

    input = {}
    assert result = c.call(input)
    assert result[:a]
    assert result[:b]
  end

  def test_compose_metadata_merge
    a = proc { |input| { trace: input[:metadata][:trace] + [:a] } }
    b = proc { |input| { trace: input[:metadata][:trace] + [:b] } }
    c = compose_processors(b, a)

    input = { metadata: { trace: [] } }
    assert result = c.call(input)
    assert_equal [:a, :b], result[:trace]
  end

  def test_multiple_functional_compose
    a = proc { |input| { data: input[:data] + ",a" } }
    b = proc { |input| { data: input[:data] + ",b" } }
    c = proc { |input| { data: input[:data] + ",c" } }
    d = proc { |input| { data: input[:data] + ",d" } }
    e = compose_processors(d, compose_processors(c, compose_processors(b, compose_processors(a))))

    input = { data: " " }
    assert result = e.call(input)
    assert_equal " ,a,b,c,d", result[:data]
  end

  def test_multiple_functional_compose_metadata
    a = proc { |input| { trace: input[:metadata][:trace] + [:a] } }
    b = proc { |input| { trace: input[:metadata][:trace] + [:b] } }
    c = proc { |input| { trace: input[:metadata][:trace] + [:c] } }
    d = proc { |input| { trace: input[:metadata][:trace] + [:d] } }
    e = compose_processors(d, compose_processors(c, compose_processors(b, compose_processors(a))))

    input = { metadata: { trace: [].freeze } }
    assert result = e.call(input)
    assert_equal [:a, :b, :c, :d], result[:trace]
  end

  def test_multiple_array_compose
    a = proc { |input| { data: input[:data] + ",a" } }
    b = proc { |input| { data: input[:data] + ",b" } }
    c = proc { |input| { data: input[:data] + ",c" } }
    d = proc { |input| { data: input[:data] + ",d" } }
    e = compose_processors(d, c, b, a)

    input = { data: " " }
    assert result = e.call(input)
    assert_equal " ,a,b,c,d", result[:data]
  end

  def test_multiple_array_compose_metadata
    a = proc { |input| { trace: input[:metadata][:trace] + [:a] } }
    b = proc { |input| { trace: input[:metadata][:trace] + [:b] } }
    c = proc { |input| { trace: input[:metadata][:trace] + [:c] } }
    d = proc { |input| { trace: input[:metadata][:trace] + [:d] } }
    e = compose_processors(d, c, b, a)

    input = { metadata: { trace: [] } }
    assert result = e.call(input)
    assert_equal [:a, :b, :c, :d], result[:trace]
  end

  def test_compose_coffee_and_uglifier
    processor = compose_processors(Sprockets::UglifierCompressor, Sprockets::CoffeeScriptProcessor)

    input = {
      content_type: 'application/javascript',
      data: "self.square = (n) -> n * n",
      cache: Sprockets::Cache.new
    }
    assert result = processor.call(input)
    assert_match "self.square=function", result[:data]
  end

  def test_bad_processor_return_type
    a = proc { |input| Object.new }
    b = compose_processors(a)

    input = { data: " " }
    assert_raises(TypeError) do
      b.call(input)
    end
  end
end
