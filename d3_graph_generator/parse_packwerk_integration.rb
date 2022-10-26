require 'bundler/inline'
require 'json'

gemfile do
  source 'https://rubygems.org'
  gem 'parse_packwerk'
  gem 'pry'
end

d3_json = nil
Dir.chdir(ENV['RELATIVE_PATH_TO_REPOSITORY']) do
  d3_json = {
    "nodes" => ParsePackwerk.all.reject {|package| package.name === "."}.map do |package|
      readme_link = package.directory.join("README.md")
      readme = readme_link.exist? ? readme_link : nil
      {
        "id" => package.name,
        "group" => package.dependencies.length,
        "metadata" => {
          "README" => "https://github.com/#{ENV['GITHUB_REPO_SLUG']}/blob/main/#{readme}"
        }
      }
    end,
    "links" => ParsePackwerk.all.reject {|package| package.name === "."}.flat_map do |package|
      package.dependencies.map do |dependency|
        {
          "source" => package.name,
          "target" => dependency,
          "value" => 1
        }
      end
    end
  }
end

Pathname('src/utilities/packwerk_graph.json').write(d3_json.to_json)