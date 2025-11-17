# -*- encoding: utf-8 -*-

$:.unshift(File.dirname(__FILE__) + '/../lib')

require 'rubygems'
require 'test/unit'
require 'robotstxt-parser'
require 'test_helper'

class TestRobotstxt < Test::Unit::TestCase

  def test_absense
    stub_request(:get, "http://example.com/robots.txt").to_return(status: [404, "Not found"])
    assert true == Robotstxt.get_allowed?("http://example.com/index.html", "Google")
  end

  def test_error
    stub_request(:get, "http://example.com/robots.txt").to_return(status: [500, "Internal Server Error"])
    assert true == Robotstxt.get_allowed?("http://example.com/index.html", "Google")
  end

  def test_unauthorized
    stub_request(:get, "http://example.com/robots.txt").to_return(status: [401, "Unauthorized"])
    assert false == Robotstxt.get_allowed?("http://example.com/index.html", "Google")
  end

  def test_forbidden
    stub_request(:get, "http://example.com/robots.txt").to_return(status: [403, "Forbidden"])
    assert false == Robotstxt.get_allowed?("http://example.com/index.html", "Google")
  end

  def test_uri_object
    stub_request(:get, "http://example.com/robots.txt").to_return(body: "User-agent:*\nDisallow: /test")
    robotstxt = Robotstxt.get(URI.parse("http://example.com/index.html"), "Google")

    assert true == robotstxt.allowed?("/index.html")
    assert false == robotstxt.allowed?("/test/index.html")
  end

  def test_existing_http_connection
    stub_request(:get, "http://example.com/robots.txt").to_return(body: "User-agent:*\nDisallow: /test")

    Net::HTTP.start("example.com", 80) do |http|
      robotstxt = Robotstxt.get(http, "Google")
      assert true == robotstxt.allowed?("/index.html")
      assert false == robotstxt.allowed?("/test/index.html")
    end
  end

  def test_redirects
    stub_request(:get, "http://example.com/robots.txt").to_return(status: [303, "See Other"], headers: {'Location' => 'http://www.exemplar.com/robots.txt'})
    stub_request(:get, "http://www.exemplar.com/robots.txt").to_return(body: "User-agent:*\nDisallow: /private")

    robotstxt = Robotstxt.get("http://example.com/", "Google")

    assert true == robotstxt.allowed?("/index.html")
    assert false == robotstxt.allowed?("/private/index.html")
  end

  # def test_encoding
  #   # "User-agent: *\n Disallow: /encyclop@dia" where @ is the ae ligature (U+00E6)
  #   stub_request(:get, "http://example.com/robots.txt").to_return("HTTP/1.1 200 OK\nContent-type: text/plain; charset=utf-16\n\n" +
  #       "\xff\xfeU\x00s\x00e\x00r\x00-\x00a\x00g\x00e\x00n\x00t\x00:\x00 \x00*\x00\n\x00D\x00i\x00s\x00a\x00l\x00l\x00o\x00w\x00:\x00 \x00/\x00e\x00n\x00c\x00y\x00c\x00l\x00o\x00p\x00\xe6\x00d\x00i\x00a\x00")
  #   robotstxt = Robotstxt.get("http://example.com/#index", "Google")

  #   assert true == robotstxt.allowed?("/index.html")
  #   assert false == robotstxt.allowed?("/encyclop%c3%a6dia/index.html")

  # end

end
