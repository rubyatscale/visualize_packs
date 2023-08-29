# frozen_string_literal: true
# typed: false

require 'erb'
require 'packs-specification'
require 'parse_packwerk'
require 'digest/md5'

module VisualizePacks

  def self.package_graph!(options, raw_config, packages)
    raise ArgumentError, "Package #{options.focus_package} does not exist. Found packages #{packages.map(&:name).join(", ")}" if options.focus_package && !packages.map(&:name).include?(options.focus_package)

    all_packages = filtered(packages, options.focus_package, options.focus_folder, options.exclude_packs).sort_by {|x| x.name }
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

  def self.code_owner(package)
    package.config.dig("metadata", "owner") || package.config["owner"]
  end

  def self.diagram_title(options, max_todo_count)
    app_name = File.basename(Dir.pwd)
    focus_edge_info = options.focus_package && options.show_only_edges_to_focus_package ? "showing only edges to/from focus pack" : "showing all edges between visible packs"
    focus_info = options.focus_package || options.focus_folder ? "Focus on #{[options.focus_package, options.focus_folder].compact.join(' and ')} (#{focus_edge_info})" : "All packs"
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
      options.exclude_packs.empty? ? nil : "excluding pack#{options.exclude_packs.size > 1 ? 's' : ''}: #{limited_sentence(options.exclude_packs)}",
    ].compact.join(', ').strip
    main_title = "#{app_name}: #{focus_info}#{skipped_info != '' ? ' - ' + skipped_info : ''}"
    sub_title = ""
    if options.show_todos && max_todo_count
      sub_title = "<br/><font point-size='12'>Widest todo edge is #{max_todo_count} todo#{max_todo_count > 1 ? 's' : ''}</font>"
    end
    "<<b>#{main_title}</b>#{sub_title}>"
  end

  def self.limited_sentence(list)
    if list.size <= 2
      list.join(" and ")
    else
      "#{list[0, 2].join(", ")}, and #{list.size - 2} more"
    end
  end

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

  def self.max_todo_count(all_packages, show_edge)
    todo_counts = {}
    all_packages.each do |package|
      todos_by_package = package.violations.group_by(&:to_package_name)
      todos_by_package.keys.each do |todos_to_package|
        todo_types = todos_by_package[todos_to_package].group_by(&:type)
        todo_types.keys.each do |todo_type|
          if show_edge.call(package.name, todos_to_package)
            key = "#{package.name}->#{todos_to_package}:#{todo_type}"
            todo_counts[key] = todo_types[todo_type].count
            # todo_counts[key] += 1
          end
        end
      end
    end
    todo_counts.values.max
  end

  def self.todo_edge_width(todo_count, max_todo_count)
    max_edge_width = 10
    (todo_count / max_todo_count.to_f * max_edge_width).to_i
  end

  def self.filtered(packages, filter_package, filter_folder, exclude_packs)
    return packages unless filter_package || filter_folder || exclude_packs.any?

    result = packages.map { |pack| pack.name }

    if filter_package
      result = [filter_package]
      result += packages.select{ |p| p.dependencies.include? filter_package }.map { |pack| pack.name }
      result += ParsePackwerk.find(filter_package).dependencies
      result += packages.select{ |p| p.violations.map(&:to_package_name).include? filter_package }.map { |pack| pack.name }
      result += ParsePackwerk.find(filter_package).violations.map(&:to_package_name)
      result = result.uniq
    end

    if filter_folder
      result = result.select { |p| p.include? filter_folder }
    end

    if exclude_packs.any?
      result = result.reject { |p| exclude_packs.include? p }
    end

    result.map { |pack_name| ParsePackwerk.find(pack_name) }
  end

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
              dependencies: package.dependencies + nested_package.dependencies,
              config: package.config,
              violations: package.violations + nested_package.violations
            )
          end
        end


        morphed_dependencies = package.dependencies.map do |d|
          nested_packages[d] || d
        end.uniq.reject { |p| p == package.name }

        morphed_todos = package.violations.map do |v|
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
        # add dependencies TO nested packages to top-level package
        # add todos TO nested packages to top-level package
      end
    end

    morphed_packages.reject { |p| nested_packages.keys.include?(p.name) }
  end
end
