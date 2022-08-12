# typed: ignore

require 'visualize_packwerk'
require 'rails'

module VisualizePackwerk
  class Railtie < Rails::Railtie
    railtie_name :visualize_packwerk

    rake_tasks do
      path = File.expand_path(__dir__)
      Dir.glob("#{path}/tasks/visualize_packwerk.rake").each { |f| load f }
    end
  end
end
