# frozen_string_literal: true
# typed: strict

require 'erb'
require 'packs-specification'
require 'parse_packwerk'
require 'digest/md5'

module VisualizePacks
  extend T::Sig

  sig { params(options: Options, raw_config: T::Hash[String, T.untyped], packages: T::Array[ParsePackwerk::Package]).returns(String) }
  def self.package_graph!(options, raw_config, packages)
    all_packages = filtered(packages, options).compact.sort_by {|x| x.name }
    all_package_names = all_packages.map &:name

    all_packages = remove_nested_packs(all_packages) if options.roll_nested_into_parent_packs

    show_edge = show_edge_builder(options, all_package_names)
    node_color = node_color_builder()
    max_todo_count = max_todo_count(all_packages, show_edge)

    title = diagram_title(options, max_todo_count)

    architecture_layers = (raw_config['architecture_layers'] || []) + ["NotInLayer"]
    grouped_packages = architecture_layers.inject({}) do |result, key|
      result[key] = []
      result
    end

    all_packages.each do |package|
      key = package.config['layer'] || "NotInLayer"
      if architecture_layers.include?(key)
        grouped_packages[key] << package
      else
        raise RuntimeError, "Package #{package.name} has architecture layer key #{key}. Known layers are only #{architecture_layers.join(", ")}"
      end
    end


    all_team_names = all_packages.map { |p| code_owner(p) }.uniq

    file = File.open(File.expand_path File.dirname(__FILE__) + "/graph.dot.erb")
    templ = file.read.gsub(/^ *(<%.+%>) *$/, '\1')
    template = ERB.new(templ, trim_mode: "<>-")
    template.result(binding)
  end

  private 

  sig { params(package: ParsePackwerk::Package).returns(T.nilable(String)) }
  def self.code_owner(package)
    package.config.dig("metadata", "owner") || package.config["owner"]
  end

  sig { params(options: Options, max_todo_count: T.nilable(Integer)).returns(String) }
  def self.diagram_title(options, max_todo_count)
    app_name = File.basename(Dir.pwd)
    focus_edge_info = options.focus_package.any? && options.show_only_edges_to_focus_package ? "showing only edges to/from focus pack" : "showing all edges between visible packs"
    focus_info = options.focus_package.any? || options.focus_folder ? "Focus on #{[options.focus_package, options.focus_folder].compact.join(' and ')} (#{focus_edge_info})" : "All packs"
    skipped_info = 
    [
      options.show_legend ? nil : "hiding legend",
      options.show_layers ? nil : "hiding layers",
      options.show_dependencies ? nil : "hiding dependencies",
      options.show_todos ? nil : "hiding todos",
      options.only_todo_types.empty? ? nil : "only #{limited_sentence(options.only_todo_types)} todos",
      options.show_privacy ? nil : "hiding privacy",
      options.show_teams ? nil : "hiding teams",
      options.roll_nested_into_parent_packs ? "hiding nested packs" : nil,
      options.show_nested_relationships ? nil : "hiding nested relationships",
      options.include_packs ? "including only: #{limited_sentence(options.include_packs)}" : nil,
      options.exclude_packs.empty? ? nil : "excluding pack#{options.exclude_packs.size > 1 ? 's' : ''}: #{limited_sentence(options.exclude_packs)}",
    ].compact.join(', ').strip
    main_title = "#{app_name}: #{focus_info}#{skipped_info != '' ? ' - ' + skipped_info : ''}"
    sub_title = ""
    if options.show_todos && max_todo_count
      sub_title = "<br/><font point-size='12'>Widest todo edge is #{max_todo_count} todo#{max_todo_count > 1 ? 's' : ''}</font>"
    end
    "<<b>#{main_title}</b>#{sub_title}>"
  end

  sig { params(list: T.nilable(T::Array[String])).returns(String) }
  def self.limited_sentence(list)
    return '' unless list

    if list.size <= 2
      list.join(" and ")
    else
      "#{T.must(list[0, 2]).join(", ")}, and #{list.size - 2} more"
    end
  end

  sig { params(options: Options, all_package_names: T::Array[String]).returns(T.proc.params(arg0: String, arg1: String).returns(T::Boolean)) }
  def self.show_edge_builder(options, all_package_names)
    return lambda do |start_node, end_node|
      (
        !options.show_only_edges_to_focus_package && 
        all_package_names.include?(start_node) && 
        all_package_names.include?(end_node)
      ) ||
      (
        options.show_only_edges_to_focus_package && 
        all_package_names.include?(start_node) && 
        all_package_names.include?(end_node) && 
        [start_node, end_node].include?(options.focus_package)
      )
    end
  end

  sig { returns(T.nilable(T.proc.params(arg0: String).returns(String))) }
  def self.node_color_builder
    return lambda do |text|
      return unless text
      hash_value = Digest::SHA256.hexdigest(text.encode('utf-8'))
      color_code = hash_value[0, 6]
      r = color_code[0, 2].to_i(16) % 128 + 128
      g = color_code[2, 2].to_i(16) % 128 + 128
      b = color_code[4, 2].to_i(16) % 128 + 128
      hex = "#%02X%02X%02X" % [r, g, b]
    end
  end

  sig { params(all_packages: T::Array[ParsePackwerk::Package], show_edge: T.proc.params(arg0: String, arg1: String).returns(T::Boolean)).returns(T.nilable(Integer)) }
  def self.max_todo_count(all_packages, show_edge)
    todo_counts = {}
    all_packages.each do |package|
      todos_by_package = package.violations&.group_by(&:to_package_name)
      todos_by_package&.keys&.each do |todos_to_package|
        todo_types = todos_by_package&& todos_by_package[todos_to_package]&.group_by(&:type)
        todo_types&.keys&.each do |todo_type|
          if show_edge.call(package.name, todos_to_package)
            key = "#{package.name}->#{todos_to_package}:#{todo_type}"
            todo_counts[key] = todo_types && todo_types[todo_type]&.count
          end
        end
      end
    end
    todo_counts.values.max
  end

  sig { params(todo_count: Integer, max_count: Integer).returns(T.any(Float, Integer)) }
  def self.todo_edge_width(todo_count, max_count)
    # Limits
    min_width = 1
    max_width = 10
    min_count = 1 # Number of todos equivalent to min_width

    # Ensure safe values
    return 0 if todo_count < min_count
    return max_width if todo_count > max_count

    todo_range = max_count - min_count
    width_range = max_width - min_width
    count_delta = todo_count - min_count

    width_delta = count_delta / todo_range.to_f * width_range
    edge_width = min_width + width_delta
    edge_width.round(2)
 end

 sig { params(packages: T::Array[ParsePackwerk::Package], options: Options).returns(T::Array[ParsePackwerk::Package]) }
 def self.filtered(packages, options)
    focus_package = options.focus_package
    focus_folder = options.focus_folder 
    include_packs = options.include_packs 
    exclude_packs = options.exclude_packs

    return packages unless focus_package.any? || focus_folder || include_packs || exclude_packs.any?

    packages_by_name = packages.inject({}) do |res, p|
      res[p.name] = p
      res
    end
 
    result = packages.map { |pack| pack.name }

    if !focus_package.empty?
      result = []
      result += packages.map { |pack| pack.name }.select { |p| match_packs?(p, focus_package) }
      result += packages.select{ |p| p.dependencies.any? { |d| match_packs?(d, focus_package) }}.map { |pack| pack.name }
      result += packages.select{ |p| p.violations&.map(&:to_package_name)&.any? { |v| match_packs?(v, focus_package) }}.map { |pack| pack.name }
      packages.map { |pack| pack.name }.select { |p| match_packs?(p, focus_package) }.each do |p|
        result += packages_by_name[p].dependencies
        packages_by_name[p].violations.map(&:to_package_name)
      end
      result = result.uniq
    end

    if focus_folder
      result = result.select { |p| p.include? focus_folder }
    end

    if include_packs
      result = result.select { |p| match_packs?(p, include_packs) }
    end

    if exclude_packs.any?
      result = result.reject { |p| match_packs?(p, exclude_packs) }
    end

    result.map { |pack_name| packages_by_name[pack_name] }
  end

  sig { params(all_package_names: T::Array[String]).returns(T::Hash[String, String]) }
  def self.all_nested_packages(all_package_names)
    all_package_names.reject { |p| p == '.' }.inject({}) do |result, package|
      package_map_tally = all_package_names.map { |other_package| Pathname.new(package).parent.to_s.include?(other_package) }

      acc = []
      all_package_names.each_with_index { |pack, idx| acc << pack if package_map_tally[idx] }
      acc.sort_by(&:length)
      result[package] = acc.first unless acc.empty?

      result
    end
  end

  sig { params(packages: T::Array[ParsePackwerk::Package]).returns(T::Array[ParsePackwerk::Package]) }
  def self.remove_nested_packs(packages)
    nested_packages = all_nested_packages(packages.map { |p| p.name })

    # top-level packages
    morphed_packages = packages.map do |package|
      if nested_packages.include?(package.name)
        package
      else
        # nested packages
        nested_packages.keys.each do |nested_package_name|
          if nested_packages[nested_package_name] == package.name
            nested_package = packages.find { |p| p.name == nested_package_name }

            package = ParsePackwerk::Package.new(
              name: package.name,
              enforce_dependencies: package.enforce_dependencies,
              enforce_privacy: package.enforce_privacy,
              public_path: package.public_path,
              metadata: package.metadata,
              dependencies: package.dependencies + T.must(nested_package).dependencies,
              config: package.config,
              violations: T.must(package.violations) + T.must(T.must(nested_package).violations)
            )
          end
        end


        morphed_dependencies = package.dependencies.map do |d|
          nested_packages[d] || d
        end.uniq.reject { |p| p == package.name }

        morphed_todos = T.must(package.violations).map do |v|
          ParsePackwerk::Violation.new(
            type: v.type, 
            to_package_name: nested_packages[v.to_package_name] || v.to_package_name, 
            class_name: v.class_name, 
            files: v.files
          )
        end.reject { |v| v.to_package_name == package.name }


        new_package = ParsePackwerk::Package.new(
          name: package.name,
          enforce_dependencies: package.enforce_dependencies,
          enforce_privacy: package.enforce_privacy,
          public_path: package.public_path,
          metadata: package.metadata,
          dependencies: morphed_dependencies,
          config: package.config,
          violations: morphed_todos
        )
      end
    end

    morphed_packages.reject { |p| nested_packages.keys.include?(p.name) }
  end

  sig { params(pack: String, packs_name_with_wildcards: T::Array[String]).returns(T::Boolean) }
  def self.match_packs?(pack, packs_name_with_wildcards)
    packs_name_with_wildcards.any? {|p| File.fnmatch(p, pack)}
  end
end
