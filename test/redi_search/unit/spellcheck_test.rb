# frozen_string_literal: true

require "test_helper"

module RediSearch
  class SpellcheckTest < Minitest::Test
    def setup
      @index = Index.new(:users, first: :text, last: :text)
    end

    def test_query_execution
      mock_client("foo", 1, [["TERM", "foo", [["0.5", "foob"]]]]) do
        suggestions = Spellcheck.new(@index, "foo").load
        assert_equal 1, suggestions.size
        assert_equal "foo", suggestions.first.term
        assert_equal 1, suggestions.first.suggestions.size
      end
    end

    def test_distance
      mock_client("foo", 2, [["TERM", "foo", [["0.5", "foob"]]]]) do
        suggestions = Spellcheck.new(@index, "foo", distance: 2).load
        assert_equal 1, suggestions.size
      end
    end

    def test_raises_validation_error_when_distance_is_to_large
      assert_raises ValidationError do
        Spellcheck.new(@index, "foo", distance: 10).load
      end
    end

    def test_raises_validation_error_when_distance_is_too_specific
      assert_raises ValidationError do
        Spellcheck.new(@index, "foo", distance: 3.5).load
      end
    end

    private

    def mock_client(terms, distance, response)
      client = Minitest::Mock.new.expect(
        :call!, Client::Response.new(response),
        ["SPELLCHECK", @index.name, terms, "DISTANCE", distance].compact
      )

      RediSearch.stub(:client, client) { yield }

      assert_mock client
    end
  end
end
