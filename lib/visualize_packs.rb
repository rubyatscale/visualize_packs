# frozen_string_literal: true
# typed: strict

require 'erb'
require 'packs-specification'
require 'parse_packwerk'
require 'digest/md5'

require 'visualize_packs/options'
require 'visualize_packs/options_parser'

module VisualizePacks
  extend T::Sig

  class ArrowHead < T::Enum
    enums do
      DependencyTodo = new('color=darkred style=dashed arrowhead=odiamond')
      PrivacyTodo = new('color=darkred style=dashed arrowhead=crow')
      ArchitectureTodo = new('color=darkred style=dashed arrowhead=obox')
      VisibilityTodo = new('color=darkred style=dashed arrowhead=tee')
      NestedVisibilityTodo = new('color=darkred style=dashed arrowhead=odot')
      ConfiguredDependency = new('color=darkgreen')
      ConfiguredVisibileTo = new('color=blue')
      ConfiguredNested = new('color=purple')
    end
  end

  sig { params(args: T::Array[String], raw_config: T::Hash[String, T.untyped], packages: T::Array[ParsePackwerk::Package]).returns(String) }
  def self.package_graph!(args, raw_config, packages)
    options = OptionsParser.parse(args)

    all_packages = filtered(packages, options).compact.sort_by {|x| x.name }
    all_packages = remove_nested_packs(all_packages, options)
    all_package_names = all_packages.map &:name

    show_edge = show_edge_builder(options, all_package_names)
    node_color = node_color_builder()
    node_protection = package_based_todos_text_maker()
    max_todo_count = max_todo_count(all_packages, show_edge, options)

    title = diagram_title(args, options, max_todo_count)

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

  sig { params(args: T::Array[String], options: Options, max_todo_count: T.nilable(Integer)).returns(String) }
  def self.diagram_title(args, options, max_todo_count)
    sub_title1_length = 0
    options_to_display = args.inject('') do |result, item|
      sub_title1_length += item.length
      if sub_title1_length > 90
        sub_title1_length = 0
        result += "<br/>#{item}"
      else
        result += " #{item}"
      end
      result
    end
    sub_title1 = "<br/>#{options_to_display}"

    return "<<b>#{options.title}</b>#{sub_title1}>" if options.title

    focus_info = if options.focus_pack
      "Focus on #{limited_sentence(options.focus_pack)} (Edge mode: #{options.show_only_edges_to_focus_pack.serialize})"
    else 
      "All packs"
    end

    hidden_aspects = [
      options.show_legend ? nil : "legend",
      options.show_layers ? nil : "layers",
      options.show_dependencies ? nil : "dependencies",
      options.show_relationship_todos ? nil : "edge todos",
      options.show_privacy ? nil : "privacy",
      options.show_teams ? nil : "teams",
      options.show_node_todos ? nil : "node todos",
      options.show_visibility ? nil : "visibility",
      options.roll_nested_into_parent_packs ? "nested packs" : nil,
      options.show_nested_relationships ? nil : "nested relationships",
    ].compact.join(', ').strip
    hidden_aspects_title = hidden_aspects != '' ? "Hiding #{hidden_aspects}" : nil

    todo_types = EdgeTodoTypes.values.size == options.relationship_todo_types.size ? nil : "Only #{options.relationship_todo_types.map &:serialize} todos",

    exclusions = options.exclude_packs.empty? ? nil : "Excluding pack#{options.exclude_packs.size > 1 ? 's' : ''}: #{limited_sentence(options.exclude_packs)}",

    main_title = [focus_info, hidden_aspects_title, todo_types, exclusions].compact.join('. ')

    if options.show_relationship_todos && max_todo_count
      sub_title2 = "<br/><font point-size='12'>Widest todo edge is #{max_todo_count} todo#{max_todo_count > 1 ? 's' : ''}</font>"
    end
    "<<b>#{main_title}</b>#{sub_title1}#{sub_title2}>"
  end

  sig { params(list: T.nilable(T::Array[String])).returns(T.nilable(String)) }
  def self.limited_sentence(list)
    return nil if !list || list.empty?

    if list.size <= 2
      list.join(" and ")
    else
      "#{T.must(list[0, 2]).join(", ")}, and #{list.size - 2} more"
    end
  end

  sig { params(options: Options, all_package_names: T::Array[String]).returns(T.proc.params(arg0: String, arg1: String).returns(T::Boolean)) }
  def self.show_edge_builder(options, all_package_names)
    return lambda do |start_node, end_node|
      all_package_names.include?(start_node) && 
      all_package_names.include?(end_node) && 
      (
        case options.show_only_edges_to_focus_pack
        when FocusPackEdgeDirection::All then
          true
        when FocusPackEdgeDirection::None then
          match_packs?(start_node, options.focus_pack) && match_packs?(end_node, options.focus_pack)
        when FocusPackEdgeDirection::InOut then
          match_packs?(start_node, options.focus_pack) || match_packs?(end_node, options.focus_pack)
        when FocusPackEdgeDirection::In then
          match_packs?(end_node, options.focus_pack)
        when FocusPackEdgeDirection::Out then
          match_packs?(start_node, options.focus_pack)
        end
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

  sig { params(all_packages: T::Array[ParsePackwerk::Package], show_edge: T.proc.params(arg0: String, arg1: String).returns(T::Boolean), options: Options).returns(T.nilable(Integer)) }
  def self.max_todo_count(all_packages, show_edge, options)
    todo_counts = {}
    if options.show_relationship_todos
      all_packages.each do |package|
        todos_by_package = package.violations&.group_by(&:to_package_name)
        todos_by_package&.keys&.each do |todos_to_package|
          todo_types = todos_by_package&& todos_by_package[todos_to_package]&.group_by(&:type)
          todo_types&.keys&.each do |todo_type|
            if options.relationship_todo_types.include?(EdgeTodoTypes.deserialize(todo_type))
              if show_edge.call(package.name, todos_to_package)
                key = "#{package.name}->#{todos_to_package}:#{todo_type}"
                todo_counts[key] = todo_types && todo_types[todo_type]&.count
              end
            end
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
    width_delta = 0 if width_delta.nan?

    edge_width = min_width + width_delta
    edge_width.round(2)
  end

  sig { params(packages: T::Array[ParsePackwerk::Package], options: Options).returns(T::Array[ParsePackwerk::Package]) }
  def self.filtered(packages, options)
    focus_pack = options.focus_pack
    exclude_packs = options.exclude_packs

    return packages unless focus_pack || exclude_packs.any?

    nested_packages = all_nested_packages(packages.map { |p| p.name })

    packages_by_name = packages.inject({}) do |res, p|
      res[p.name] = p
      res
    end
 
    result = T.let([], T::Array[T.nilable(String)])
    result = packages.map { |pack| pack.name }

    if focus_pack
      result = []
      focus_pack_name = packages.map { |pack| pack.name }.select { |p| match_packs?(p, focus_pack) }
      result += focus_pack_name

      dependents = options.show_dependencies ? dependents_on(packages, focus_pack_name) : []
      dependencies = options.show_dependencies ? dependencies_of(packages, focus_pack_name) : []
      todos_out = options.show_relationship_todos ? todos_out(packages, focus_pack_name, options) : []
      todos_in = options.show_relationship_todos ? todos_in(packages, focus_pack_name, options) : []

      case options.show_only_edges_to_focus_pack
      when FocusPackEdgeDirection::All, FocusPackEdgeDirection::InOut then
        result += dependents + dependencies + todos_out + todos_in
      when FocusPackEdgeDirection::In then
        result += dependents + todos_in
      when FocusPackEdgeDirection::Out then
        result += dependencies + todos_out 
      when FocusPackEdgeDirection::None then
        # nothing to do
      end

      parent_packs = result.inject([]) do |res, package_name|
        res << nested_packages[package_name]
        res
      end

      result = (result + parent_packs).uniq.compact
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

  sig { params(packages: T::Array[ParsePackwerk::Package], options: Options).returns(T::Array[ParsePackwerk::Package]) }
  def self.remove_nested_packs(packages, options)
    return packages unless options.roll_nested_into_parent_packs

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

  sig { params(pack: String, packs_name_with_wildcards: T.nilable(T::Array[String])).returns(T::Boolean) }
  def self.match_packs?(pack, packs_name_with_wildcards)
    !packs_name_with_wildcards || packs_name_with_wildcards.any? {|p| File.fnmatch(p, pack)}
  end

  sig { params(all_packages: T::Array[ParsePackwerk::Package], focus_packs_names: T::Array[String]).returns(T::Array[String]) }
  def self.dependencies_of(all_packages, focus_packs_names)
    focus_packs = all_packages.select { focus_packs_names.include?(_1.name)}
    
    focus_packs.inject([]) do |result, pack|
      result += pack.dependencies
      result
    end.uniq
  end

  sig { params(all_packages: T::Array[ParsePackwerk::Package], focus_packs_names: T::Array[String]).returns(T::Array[String]) }
  def self.dependents_on(all_packages, focus_packs_names)
    all_packages.select { |pack| pack.dependencies.any? { focus_packs_names.include?(_1) }}.map &:name
  end

  sig { params(all_packages: T::Array[ParsePackwerk::Package], focus_packs_names: T::Array[String], options: Options).returns(T::Array[String]) }
  def self.todos_in(all_packages, focus_packs_names, options)
    all_packages.select do |p|
      (p.violations || []).inject([]) do |res, todo|
        res << todo.to_package_name if options.relationship_todo_types.include?(EdgeTodoTypes.deserialize(todo.type))
        res
      end.any? { |v| focus_packs_names.include?(v) }
    end.map { |pack| pack.name }
  end

  sig { params(all_packages: T::Array[ParsePackwerk::Package], focus_packs_names: T::Array[String], options: Options).returns(T::Array[String]) }
  def self.todos_out(all_packages, focus_packs_names, options)
    all_packages.inject([]) do |result, p|
      focus_packs_names.include?(p.name) && (p.violations || []).each do |todo|
        result << todo.to_package_name if options.relationship_todo_types.include?(EdgeTodoTypes.deserialize(todo.type))
      end
      result
    end
  end

  sig { params(protection: String, package_name: String, rubocop_config: T.any(NilClass, T::Boolean, T::Hash[String, T.untyped]), rubocop_todo: T.any(NilClass, T::Boolean, T::Hash[String, T.untyped])).returns(T.nilable(Integer)) }
  def self.package_based_todos_for(protection, package_name, rubocop_config,  rubocop_todo)
    rubocop_config = {} if rubocop_config.is_a?(TrueClass) || rubocop_config.is_a?(FalseClass) || rubocop_config.is_a?(NilClass)
    rubocop_todo = {} if rubocop_todo.is_a?(TrueClass) || rubocop_todo.is_a?(FalseClass) || rubocop_todo.is_a?(NilClass)

    raise ArgumentError unless ['Packs/ClassMethodsAsPublicApis', 'Packs/DocumentedPublicApis', 'Packs/RootNamespaceIsPackName', 'Packs/TypedPublicApis'].include?(protection)
    return nil unless (rubocop_config.dig(protection)&.dig('Enabled'))
    
    (rubocop_todo.dig(protection)&.dig('Exclude') || []).inject(0) do |result, todo|
      result += 1 if todo.start_with?("#{package_name}/")
      result
    end
  end

  sig { returns(T.untyped) }
  def self.package_based_todos_text_maker
    ->(package_name) {
      [
        'Packs/ClassMethodsAsPublicApis', 
        'Packs/DocumentedPublicApis', 
        'Packs/RootNamespaceIsPackName', 
        'Packs/TypedPublicApis'
      ].map do |protection|
        rubocop_config = File.exist?("#{package_name}/.rubocop.yml") ? YAML.load_file("#{package_name}/.rubocop.yml") : {}
        rubocop_todo = File.exist?(".rubocop_todo.yml") ? YAML.load_file(".rubocop_todo.yml") : {}

        todo_value = package_based_todos_for(protection, package_name, rubocop_config,  rubocop_todo)
        abbreviation = T.must(protection.split('/')[1]).chars[0]
        
        "#{abbreviation}: #{todo_value}" if todo_value
      end.compact.join(", ")
    }
  end
end
