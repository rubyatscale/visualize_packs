# frozen_string_literal: true

require 'packs-specification'
require 'sorbet-runtime'

require_relative '../lib/visualize_packs'

RSpec.describe "VisualizePacks" do
  describe ".all_nested_packages" do
    it "has an empty result if there are no nested packs" do
      input = %w(. packs/a packs/b )
      expected_output = {} 

      expect(VisualizePacks.all_nested_packages(input)).to eq(expected_output)
    end

    it "works for nested packs" do
      input = %w(. packs/a packs/a/z packs/b packs/b/packs/x packs/b/packs/y)
      expected_output = {
        "packs/a/z" => "packs/a",
        "packs/b/packs/x" => "packs/b",
        "packs/b/packs/y" => "packs/b"
      } 

      expect(VisualizePacks.all_nested_packages(input)).to eq(expected_output)
    end

    it "works for multiply nested packages" do
      input = %w(. packs/a packs/a/b packs/a/b/c)

      expected_output = {
        "packs/a/b" => "packs/a",
        "packs/a/b/c" => "packs/a",
      } 

      expect(VisualizePacks.all_nested_packages(input)).to eq(expected_output)
    end
  end

  describe ".remove_nested_packs" do
    it "removes nested packs" do
      top_level_a = ParsePackwerk::Package.new(
        name: "packs/a",
        enforce_dependencies: true,
        enforce_privacy: false,
        public_path: 'app/public',
        metadata: {},
        dependencies: ['packs/b', 'packs/b/nested', 'packs/a/nested'],
        config: {enforce_dependencies: true, enforce_privacy: true},
      )
      allow(top_level_a).to receive(:violations) do
        [
          ParsePackwerk::Violation.new(
            type: 'privacy', 
            to_package_name: "packs/b", 
            class_name: "SomeClass1", 
            files: ["some_file1"]
          ),
          ParsePackwerk::Violation.new(
            type: 'privacy', 
            to_package_name: "packs/b/nested", 
            class_name: "SomeClass2", 
            files: ["some_file2"]
          ),
        ]
      end
      nested_a = ParsePackwerk::Package.new(
        name: "packs/a/nested",
        enforce_dependencies: true,
        enforce_privacy: false,
        public_path: 'app/public',
        metadata: {},
        dependencies: ['packs/a', 'packs/b'],
        config: {enforce_dependencies: true, enforce_privacy: true},
      )
      allow(nested_a).to receive(:violations) do
        [
          ParsePackwerk::Violation.new(
            type: 'privacy', 
            to_package_name: "packs/b", 
            class_name: "SomeClass7", 
            files: ["some_file7"]
          ),
          ParsePackwerk::Violation.new(
            type: 'privacy', 
            to_package_name: "packs/b/nested", 
            class_name: "SomeClass8", 
            files: ["some_file8"]
          ),
        ]
      end

      top_level_b = ParsePackwerk::Package.new(
        name: "packs/b",
        enforce_dependencies: true,
        enforce_privacy: false,
        public_path: 'app/public',
        metadata: {},
        dependencies: ['packs/b/nested'],
        config: {enforce_dependencies: true, enforce_privacy: true},
      )
      allow(top_level_b).to receive(:violations) do
        [
          ParsePackwerk::Violation.new(
            type: 'privacy', 
            to_package_name: "packs/b/nested", 
            class_name: "SomeClass4", 
            files: ["some_file4"]
          ),
        ]
      end

      nested_b = ParsePackwerk::Package.new(
        name: "packs/b/nested",
        enforce_dependencies: true,
        enforce_privacy: false,
        public_path: 'app/public',
        metadata: {},
        dependencies: ['packs/a', 'packs/b'],
        config: {enforce_dependencies: true, enforce_privacy: true},
      )
      allow(nested_b).to receive(:violations) do
        [
          ParsePackwerk::Violation.new(
            type: 'privacy', 
            to_package_name: "packs/a", 
            class_name: "SomeClass5", 
            files: ["some_file5"]
          ),
          ParsePackwerk::Violation.new(
            type: 'privacy', 
            to_package_name: "packs/b", 
            class_name: "SomeClass6", 
            files: ["some_file6"]
          ),
        ]
      end

      options = Options.new
      options.roll_nested_into_parent_packs = true

      result = VisualizePacks.remove_nested_packs([top_level_a, top_level_b, nested_a, nested_b], options)
      expect(result.count).to eq 2

      new_top_level_a = result[0]
      expect(new_top_level_a.name).to eq "packs/a"

      new_top_level_b = result[1]
      expect(new_top_level_b.name).to eq "packs/b"

      expect(new_top_level_a.dependencies).to eq ['packs/b']
      expect(new_top_level_a.violations.map(&:inspect)).to eq [
        ParsePackwerk::Violation.new(
          type: 'privacy', 
          to_package_name: "packs/b", 
          class_name: "SomeClass1", 
          files: ["some_file1"]
        ),
        ParsePackwerk::Violation.new(
          type: 'privacy', 
          to_package_name: "packs/b", ## this is no longer pointing to the nested package!
          class_name: "SomeClass2", 
          files: ["some_file2"]
        ),

        # violations from the nested package

        ParsePackwerk::Violation.new(
          type: 'privacy', 
          to_package_name: "packs/b", 
          class_name: "SomeClass7", 
          files: ["some_file7"]
        ),
        ParsePackwerk::Violation.new(
          type: 'privacy', 
          to_package_name: "packs/b", ## this is no longer pointing to the nested package!
          class_name: "SomeClass8", 
          files: ["some_file8"]
        ),
      ].map(&:inspect)

      expect(new_top_level_b.dependencies).to eq ['packs/a']
      ## this does not include a self reference to packs/b
      ## it does now include the dependency on packs/a from the nested pack

      expect(new_top_level_b.violations.map(&:inspect)).to eq [
        ParsePackwerk::Violation.new(
          type: 'privacy', 
          to_package_name: "packs/a", 
          class_name: "SomeClass5", 
          files: ["some_file5"]
        ),
      ].map(&:inspect)
      ## this does not contain any self-violations
      ## it does include the violation from the nested pack onto a
    end
  end

  describe ".limited_sentence" do
    it "outputs a lossy (but always short) versiin if the original list" do
      expect(VisualizePacks.limited_sentence(nil)).to eq nil
      expect(VisualizePacks.limited_sentence([])).to eq nil
      expect(VisualizePacks.limited_sentence(["foo"])).to eq "foo"
      expect(VisualizePacks.limited_sentence(["foo", "bar"])).to eq "foo and bar"
      expect(VisualizePacks.limited_sentence(["foo", "bar", "baz"])).to eq "foo, bar, and 1 more"
      expect(VisualizePacks.limited_sentence(["foo", "bar", "baz", "wow"])).to eq "foo, bar, and 2 more"
    end
  end

  describe ".todo_edge_width" do
    # Define expectations this way:
    # [todo_count, max_count, expected_value]
    [
      [0,       1,     0],
      [1,       1,     1],
      [0,       3,     0],
      [2,       3,   5.5],
      [3,       3,    10],
      [0,      10,     0],
      [4,      10,     4],
      [9,      10,     9],
      [10,     10,    10],
      [0,     100,     0],
      [25,    100,  3.18],
      [75,    100,  7.73],
      [99,    100,  9.91],
    ].each do |todo_count, max_count, expectation|
      it "returns #{expectation} for a todo count of #{todo_count} and max todos being #{max_count}" do
        expect(VisualizePacks.todo_edge_width(todo_count, max_count)).to eq expectation
      end
    end
  end

  describe '.max_todo_count' do
    before do
      @package_with_todos = -> (todos) {
        x = ParsePackwerk::Package.new(
          name: "packs/a",
          enforce_dependencies: true,
          enforce_privacy: false,
          public_path: 'app/public',
          metadata: {},
          dependencies: [],
          config: {},
        )
        allow(x).to receive(:violations) do
          todos.keys.inject([]) do |result, todo_type|
            todos[todo_type].times do
              result << ParsePackwerk::Violation.new(
                type: todo_type.to_s,
                to_package_name: "packs/b",
                class_name: "SomeClass1",
                files: ["some_file1"]
              )
            end
            result
          end
        end
        x
      }
      @options = Options.new
    end

    let(:show_edge) { VisualizePacks.show_edge_builder(@options, [@package.name, 'packs/b']) }

    it "is nil if todos aren't being shown" do
      @options.show_todos = false
      @package = @package_with_todos.call({privacy: 1})

      expect(VisualizePacks.max_todo_count([@package], show_edge, @options)).to be nil
    end

    it "is nil if there aren't any todos" do
      @options.show_todos = true
      @package = @package_with_todos.call({})

      expect(VisualizePacks.max_todo_count([@package], show_edge, @options)).to be nil
    end

    it "returns the highest number of todos found in shown package relationships" do
      @options.show_todos = true
      @package = @package_with_todos.call({privacy: 3, dependency: 1})

      expect(VisualizePacks.max_todo_count([@package], show_edge, @options)).to be 3
    end

    it "does not include counts from todo types that are not being shown" do
      @options.show_todos = true
      @options.only_todo_types = [EdgeTodoTypes::Privacy, EdgeTodoTypes::Architecture]
      @package = @package_with_todos.call({privacy: 3, dependency: 4, architecture: 2})

      expect(VisualizePacks.max_todo_count([@package], show_edge, @options)).to be 3
    end
  end

  describe '.match_packs?' do
    it 'does not exclude non-matches' do
      expect(VisualizePacks.match_packs?("pack", ["packs", "spack", "ack", "components"])).to be_falsy
    end

    it 'excludes matches' do
      expect(VisualizePacks.match_packs?("pack", ["pack", "park"])).to be_truthy
      expect(VisualizePacks.match_packs?("park", ["pack", "park"])).to be_truthy
    end

    it 'excludes matches using fnmatch' do
      expect(VisualizePacks.match_packs?("component", ["pack/*"])).to be_falsy
      expect(VisualizePacks.match_packs?("pack", ["pack/*"])).to be_falsy
      expect(VisualizePacks.match_packs?("pack/a", ["pack/*"])).to be_truthy
      expect(VisualizePacks.match_packs?("pack/a/b", ["pack/*"])).to be_truthy

      expect(VisualizePacks.match_packs?("pack/a/b", ["pack/*/b"])).to be_truthy
      expect(VisualizePacks.match_packs?("pack/a/c", ["pack/*/b"])).to be_falsy
    end
  end

  describe '.filtered' do
    let(:pack_name_lookup) { 
      { 
        'a' => 'packs/a', 
        '1' => 'packs/a/1', 
        '2' => 'packs/a/2', 
        '3' => 'packs/b/3', 
        '4' => 'packs/b/4', 
        'c' => 'packs/c' 
      } 
    }
    let(:pack_lookup) {
      { 
        'a' => @pack_a, 
        '1' => @pack_1, 
        '2' => @pack_2, 
        '3' => @pack_3, 
        '4' => @pack_4, 
        'c' => @pack_c 
      } 
    }
    let(:edge_type_lookup) { 
      { 
        'd' => EdgeTodoTypes::Dependency, 
        'p' => EdgeTodoTypes::Privacy, 
        'a' => EdgeTodoTypes::Architecture, 
        'v' => EdgeTodoTypes::Visibility 
      } 
    }
    let(:edge_mode_lookup) { 
      { 
        'a' => FocusPackEdgeDirection::All, 
        'i' => FocusPackEdgeDirection::In, 
        'o' => FocusPackEdgeDirection::Out, 
        'b' => FocusPackEdgeDirection::InOut, 
        'n' => FocusPackEdgeDirection::None 
      } 
    }

    let(:dependency_generate) { ->(str, node_name) { str.split(' ').map { _1[0] == node_name ? pack_name_lookup[_1[1]]: nil}.compact } }

    let(:make_todo) { 
      ->(type, to_package_name) { 
        ParsePackwerk::Violation.new( 
          type: type.serialize, 
          to_package_name: to_package_name, 
          class_name: "SomeClass1", 
          files: ["some_file1"]
        ) 
      }
    }
    let(:todo_generate) { 
      ->(str, node_name) { 
        str.split(' ').map { _1[0] == node_name ? make_todo.(edge_type_lookup[_1[1]], pack_name_lookup[_1[2]]): nil}.compact 
      } 
    }

    let(:make_pack) { 
      ->(name, dependencies = [], todos = []) { 
        ParsePackwerk::Package.new( 
          name: name, 
          enforce_dependencies: true, 
          enforce_privacy: false, 
          public_path: '', 
          metadata: {}, 
          dependencies: dependencies, 
          config: {}, 
          violations: todos
        )
      } 
    }

    true_ = true

    cases = [
      # packages        show_todos  edge_focus_mode            todos        focus_pack        exclude_packs    expectation   test_description
      #         show_deps   only_todo_types    dependencies
      # 0           1       2       3     4        5         6              7                          8            9

      #basic usage
      ['      ',   true_, false, 'dpav', 'a',  '     ', '               ',           nil,                    [], '      ', 'empty list works'],
      ['a1234c',   true_, false, 'dpav', 'a',  '     ', '               ',           nil,                    [], 'a1234c', 'unfiltered list works'],
      # Filtering (including wildcards)
      ['a1234c',   true_, true_, 'dpav', 'a',  '     ', '               ', %w(packs/a/1),                    [], 'a1    ', 'basic filtering works'],
      ['a1234c',   true_, true_, 'dpav', 'a',  '     ', '               ',   %w(packs/*),                    [], 'a1234c', 'filtering with wildcard works'],
      ['a1234c',   true_, true_, 'dpav', 'a',  '     ', '               ', %w(packs/a/*),                    [], 'a12   ', 'parent gets added when filtering'],
      #Filtering + dependencies
      ['a1234c',   false, true_, 'dpav', 'a',  'a1 2a', '               ',   %w(packs/a),                    [], 'a     ', 'dependency nodes not shown if dependency edges not shown'],
      ['a1234c',   true_, true_, 'dpav', 'a',  'a1 2a', '               ',   %w(packs/a),                    [], 'a12   ', 'dependency nodes shown if dependency edges shown'],
      ['a1234c',   true_, true_, 'dpav', 'n',  'a1 2a', '               ',   %w(packs/a),                    [], 'a     ', 'dependency nodes not shown if edge mode none'],
      ['a1234c',   true_, true_, 'dpav', 'o',  'a1 2a', '               ',   %w(packs/a),                    [], 'a1    ', 'only out dependency nodes shown if edge mode out'],
      ['a1234c',   true_, true_, 'dpav', 'i',  'a1 2a', '               ',   %w(packs/a),                    [], 'a 2   ', 'only in dependency nodes shown if edge mode in'],
      ['a1234c',   true_, true_, 'dpav', 'b',  'a1 2a', '               ',   %w(packs/a),                    [], 'a12   ', 'dependency nodes shown if edge mode inout'],
      #Filtering + todos
      ['a1234c',   true_, false, 'dpav', 'b',  '     ', '        ap1 2pa',   %w(packs/a),                    [], 'a     ', 'todo nodes not shown if todos not shown'],
      ['a1234c',   true_, true_, 'dpav', 'b',  '     ', '        ap1 2pa',   %w(packs/a),                    [], 'a12   ', 'todo nodes shown if todos shown'],
      ['a1234c',   true_, true_, 'dpav', 'b',  '     ', 'ad1 ap2 aa3 av4',   %w(packs/a),                    [], 'a1234 ', 'todo nodes shown for all todo types'],
      ['a1234c',   true_, true_, 'd   ', 'b',  '     ', '        ap1 2pa',   %w(packs/a),                    [], 'a     ', 'todo nodes not shown if todo type filtered'],
      ['a1234c',   true_, true_, 'd   ', 'b',  '     ', '    ad1 ap1 2pa',   %w(packs/a),                    [], 'a1    ', 'todo nodes shown if specific todo type not filtered'],
      ['a1234c',   true_, true_, 'dpav', 'n',  '     ', '        ap1 2pa',   %w(packs/a),                    [], 'a     ', 'todo nodes not shown if edge mode none'],
      ['a1234c',   true_, true_, 'dpav', 'o',  '     ', '        ap1 2pa',   %w(packs/a),                    [], 'a1    ', 'only out todo nodes shown if edge mode out'],
      ['a1234c',   true_, true_, 'dpav', 'i',  '     ', '        ap1 2pa',   %w(packs/a),                    [], 'a 2   ', 'only in todo nodes shown if edge mode in'],
      ['a1234c',   true_, true_, 'dpav', 'b',  '     ', '        ap1 2pa',   %w(packs/a),                    [], 'a12   ', 'todo nodes shown if edge mode inout'],
      #Filtering + excluding (including wildcards)
      ['a1234c',   true_, true_, 'dpav', 'a',  '     ', '               ',           nil,         %w(packs/a/1), 'a 234c', 'exclude_packs removes node'],
      ['a1234c',   true_, true_, 'dpav', 'a',  '     ', '               ',           nil,         %w(packs/a/*), 'a  34c', 'exclude_packs with wildcard removes nodes'],
      ['a1234c',   true_, true_, 'dpav', 'a',  '     ', '               ',           nil, %w(packs/a packs/a/*), '   34c', 'exclude_packs with multiple exludes works'],
      ['a1234c',   true_, true_, 'dpav', 'a',  '     ', '               ',   %w(packs/a),           %w(packs/a), '      ', 'exclude_packs exludes focus'],
      ['a1234c',   true_, true_, 'dpav', 'a',  'a1   ', '               ',   %w(packs/a),           %w(packs/a), ' 1    ', 'exclude_packs exludes focus but keeps dependency'],
      ['a1234c',   true_, true_, 'dpav', 'a',  '     ', '            ad1',   %w(packs/a),           %w(packs/a), ' 1    ', 'exclude_packs exludes focus but keeps todo'],
      #Filtering + dependencies + todos + excluding
      ['a1234c',   true_, true_, ' pa ', 'o',  'a1 2a', '    ad3 4aa apc',   %w(packs/a),           %w(packs/a), ' 1   c', 'combination of todo filtering, edge mode, focus, and exclude works'],
     ].each do |c|
      
      it "#{c[10]}" do
        options = Options.new
        options.focus_pack = c[7]
        options.exclude_packs = c[8]
        options.show_dependencies = c[1]
        options.show_todos = c[2]
        options.only_todo_types = c[3].gsub(' ', '').chars.map { edge_type_lookup[_1] } 
        options.show_only_edges_to_focus_pack = edge_mode_lookup[c[4]]

        @pack_a = make_pack.(pack_name_lookup['a'], dependency_generate.(c[5], 'a'), todo_generate.(c[6], 'a'))
        @pack_1 = make_pack.(pack_name_lookup['1'], dependency_generate.(c[5], '1'), todo_generate.(c[6], '1'))
        @pack_2 = make_pack.(pack_name_lookup['2'], dependency_generate.(c[5], '2'), todo_generate.(c[6], '2'))
        @pack_3 = make_pack.(pack_name_lookup['3'], dependency_generate.(c[5], '3'), todo_generate.(c[6], '3'))
        @pack_4 = make_pack.(pack_name_lookup['4'], dependency_generate.(c[5], '4'), todo_generate.(c[6], '4'))
        @pack_c = make_pack.(pack_name_lookup['c'], dependency_generate.(c[5], 'c'), todo_generate.(c[6], 'c'))

        input_packages = c[0].gsub(' ', '').chars.map { pack_lookup[_1] } 
        expected_output_packages =  c[9].gsub(' ', '').chars.map { pack_lookup[_1] } 

        expect(VisualizePacks.filtered(input_packages, options)).to match_packs(expected_output_packages)
      end
    end
  end

  describe '.show_edge_builder' do
    subject {  VisualizePacks.show_edge_builder(@options, %w(a b c d)) }

    it 'returns a proc' do
      @options = Options.new
      @package_names = []

      expect(subject).to be_a Proc
    end

    true_ = true

    tests___ = ['a b', 'a c', 'a d', 'a e', 'b a', 'b c', 'b d', 'b e', 'c a', 'c b', 'c d', 'c e', 'd a', 'd b', 'd c', 'd e', 'e a', 'e b', 'e c', 'e d']
    cases = [
      [:all__, [true_, true_, true_, false, true_, true_, true_, false, true_, true_, true_, false, true_, true_, true_, false, false, false, false, false]],
      [:inout, [true_, true_, true_, false, true_, true_, true_, false, true_, true_, false, false, true_, true_, false, false, false, false, false, false]],
      [:in___, [true_, false, false, false, true_, false, false, false, true_, true_, false, false, true_, true_, false, false, false, false, false, false]],
      [:out__, [true_, true_, true_, false, true_, true_, true_, false, false, false, false, false, false, false, false, false, false, false, false, false]],
      [:none_, [true_, false, false, false, true_, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false]],
    ].each do |edge_mode_line|
      edge_mode = FocusPackEdgeDirection.deserialize(edge_mode_line[0].to_s.gsub('_', ''))
      expectations = edge_mode_line[1]
      (0..tests___.size-1).to_a.each do |index|
        it "returns #{expectations[index]} for mode #{edge_mode.serialize} with nodes a, b, c, d and focus nodes a, b for the edge #{tests___[index]}" do
          @options = Options.new
          @options.show_only_edges_to_focus_pack = edge_mode
          @options.focus_pack = ['a', 'b']

          edge_show = VisualizePacks.show_edge_builder(@options, %w(a b c d))

          expect(edge_show.call(*tests___[index].split(' '))).to eq(expectations[index])
        end
      end
    end
  end

  describe '.diagram_title' do
    context 'with a custom title from options' do
      it "returns whatever is set" do
        options = Options.new
        options.title = "Some title"

        expect(VisualizePacks.diagram_title(options, 42)).to eq("<<b>Some title</b>>")
      end
    end

    context 'without a custom title from options' do
      describe 'with basic options and nil max edge count' do
        it "with " do
          options = Options.new

          expect(VisualizePacks.diagram_title(options, 0)).to eq(
            "<<b>visualize_packs: All packs</b><br/><font point-size='12'>Widest todo edge is 0 todo</font>>"
          )
        end
      end

      describe 'with basic options and 0 max edge count' do
        it "with " do
          options = Options.new

          expect(VisualizePacks.diagram_title(options, 0)).to eq(
            "<<b>visualize_packs: All packs</b><br/><font point-size='12'>Widest todo edge is 0 todo</font>>"
          )
        end
      end

      describe 'with basic options and 1 max edge count' do
        it "with " do
          options = Options.new

          expect(VisualizePacks.diagram_title(options, 1)).to eq(
            "<<b>visualize_packs: All packs</b><br/><font point-size='12'>Widest todo edge is 1 todo</font>>"
          )
        end
      end

      describe 'with basic options and non-zero max edge count' do
        it "with " do
          options = Options.new

          expect(VisualizePacks.diagram_title(options, 19)).to eq(
            "<<b>visualize_packs: All packs</b><br/><font point-size='12'>Widest todo edge is 19 todos</font>>"
          )
        end
      end
    end
  end
end