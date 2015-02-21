$:.unshift 'lib'

require 'benchmark/ips'

module Perftest
  class Test
    class << self
      def inherited base
        @x ||= []

        @x.push(base)
      end

      def classes
        @x || []
      end
    end
  end

  def self.test_cases
    Test.classes.each do |test_class|
      obj = test_class.new
      obj.methods.grep(/test_.*/).each do |test_method|
        yield obj, test_method
      end
    end
  end

  def self.run
    Benchmark.ips do |bm|

      self.test_cases do |obj, method|
        bm.report("#{obj.class}##{method}") do |t|
          obj.send method
        end
      end
    end
  end
end

at_exit { Perftest.run }
