require "test_helper"

class RubyNative::SetCookieHeaderTest < Minitest::Test
  def test_read_returns_empty_array_when_header_is_missing
    assert_equal [], RubyNative::SetCookieHeader.read({})
  end

  def test_read_splits_a_rack2_newline_string
    headers = {"set-cookie" => "a=1; path=/\nb=2; path=/"}

    assert_equal ["a=1; path=/", "b=2; path=/"], RubyNative::SetCookieHeader.read(headers)
  end

  def test_read_returns_a_rack3_array_as_is
    headers = {"set-cookie" => ["a=1", "b=2"]}

    assert_equal ["a=1", "b=2"], RubyNative::SetCookieHeader.read(headers)
  end

  def test_read_accepts_the_capitalized_rack2_key
    headers = {"Set-Cookie" => "a=1"}

    assert_equal ["a=1"], RubyNative::SetCookieHeader.read(headers)
  end

  def test_rewrite_preserves_string_shape
    headers = {"set-cookie" => "a=1\nb=2"}

    RubyNative::SetCookieHeader.rewrite!(headers) { |c| c.upcase }

    assert_equal "A=1\nB=2", headers["set-cookie"]
  end

  def test_rewrite_preserves_array_shape
    headers = {"set-cookie" => ["a=1"]}

    RubyNative::SetCookieHeader.rewrite!(headers) { |c| c.upcase }

    assert_equal ["A=1"], headers["set-cookie"]
  end

  def test_rewrite_preserves_the_capitalized_rack2_key
    headers = {"Set-Cookie" => "a=1"}

    RubyNative::SetCookieHeader.rewrite!(headers) { |c| c.upcase }

    assert_equal({"Set-Cookie" => "A=1"}, headers)
  end

  def test_rewrite_is_a_no_op_without_the_header
    headers = {"content-type" => "text/html"}

    RubyNative::SetCookieHeader.rewrite!(headers) { |c| c.upcase }

    assert_equal({"content-type" => "text/html"}, headers)
  end
end
