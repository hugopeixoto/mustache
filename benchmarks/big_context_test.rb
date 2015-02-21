require_relative 'helper'

require 'mustache'

class BigContextTest < Perftest::Test
  def initialize
    @view = Mustache.new

    ('a'..'z').each do |letter|
      @view[letter.to_sym] = letter
    end
  end

  def test_big_context
    @view.render("{{a}} {{z}}")
  end
end
