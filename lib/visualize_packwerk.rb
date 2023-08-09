# typed: strict

require 'packs'
require 'parse_packwerk'
require 'graphviz'

require 'erb'

module VisualizePackwerk
  extend T::Sig

  sig { params(all_packages: T::Array[Packs::Pack]).void }
  def self.package_graph!(all_packages)
    config = ParsePackwerk::Configuration.fetch

    grouped_packages = all_packages.inject({}) do |result, package|
      result[package.config['layer'] || "NotInLayer"] ||= []
      result[package.config['layer'] || "NotInLayer"] << package
      result
    end
    file = File.open(File.expand_path File.dirname(__FILE__) + "/graph.dot.erb")
    template = ERB.new(file.read)
    puts template.result(binding)
  end
end
