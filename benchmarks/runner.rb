Dir["benchmarks/*_test.rb"].each do |f|
  require_relative File.basename(f)
end
