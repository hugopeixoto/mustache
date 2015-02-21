require_relative 'helper'

require 'mustache'

class RenderCollectionTest < Perftest::Test
  DATASET_SIZES = [10, 100, 1000]

  def initialize
    @template = """
{{#products}}
  <li class='product'>
    <img src='images/{{image}}' />
    <a href={{url}} class='product_name'>
      {{external_index}}
    </a>
  </li>
{{/products}}
"""

    @compiled_template = Mustache::Template.new(@template)

    product = {
      external_index: 'product',
      url: '/products/1',
      image: 'products/category.jpg'
    }

    @datasets = Hash[ DATASET_SIZES.map{ |i| [i, { products: [product]*i }] } ]
  end

  DATASET_SIZES.each do |size|
    define_method "test_#{size}" do
      Mustache.render(@template, @datasets[size])
    end

    define_method "test_#{size}_without_escaping" do
      UnescapedView.render(@template, @datasets[size])
    end
  end

  def test_template_compilation
    Mustache::Template.new(@template)
  end

  class UnescapedView < Mustache
    def escapeHTML str
      str
    end
  end
end
