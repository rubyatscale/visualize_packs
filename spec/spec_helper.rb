# frozen_string_literal: true
# typed: ignore

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end

RSpec::Matchers.define :match_packs do |expected_array|
  match do |actual_array|
    expected_array.map(&:name).sort == actual_array.map(&:name).sort
  end

  failure_message do |actual_array|
    "Expected packs #{actual_array.map(&:name).sort} to eq: #{expected_array.map(&:name).sort}"
  end
end

