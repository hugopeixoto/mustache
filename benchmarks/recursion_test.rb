require_relative 'helper'

require 'mustache'

class DeepPartialTest < Perftest::Test
  class Recursive < Mustache
    def partial name
      self.class.tpl
    end

    def self.tpl
      "({{#children}}{{> p}}{{/children}})"
    end
  end

  class A
    attr_accessor :children
    def initialize *c
      self.children = c
    end
  end

  def initialize
    @ctx = a(a(), a(a(a(),a(),a()), a(a(a(a(a(a(a()))))))))
    before = '{{#children}}('
    after = '){{/children}}'

    @rec_template = before*8 + after*8
  end

  def a *c
    A.new(*c)
  end

  def test_recursive_partial
    Recursive.render(Recursive.tpl, @ctx)
  end

  def test_nested_objects
    Mustache.render(@rec_template, @ctx)
  end
end
