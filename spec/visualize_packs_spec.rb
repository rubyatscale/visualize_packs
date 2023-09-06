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
      @options.only_todo_types = %w(privacy architecture)
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
    before do
      @options = Options.new

      @make_todo = ->(type, to_package_name) {
        ParsePackwerk::Violation.new(
          type: type.to_s,
          to_package_name: to_package_name,
          class_name: "SomeClass1",
          files: ["some_file1"]
        )
      }
      @make_pack = ->(name, dependencies = [], todos = []) {
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
      @pack_s_dependencies = []
      @pack_s_todos = []
      @pack_b_dependencies = []
      @pack_b_todos = []
    end

    let(:all_packs) {
      @pack_s = @make_pack.call('packs/something', @pack_s_dependencies, @pack_s_todos)
      @pack_a = @make_pack.call('packs/something/a')
      @pack_b = @make_pack.call('packs/something/b', @pack_b_dependencies, @pack_b_todos)
      @pack_c = @make_pack.call('packs/something_else/c')
      @pack_d = @make_pack.call('packs/something_else/d')
      @pack_e = @make_pack.call('packs/e')

      [@pack_s, @pack_a, @pack_b, @pack_c, @pack_d, @pack_e]
    }

    it 'works with empty package lists' do
      expect(VisualizePacks.filtered([], @options)).to match_packs([])
    end

    it 'returns unfiltered package lists' do
      expect(VisualizePacks.filtered(all_packs, @options)).to match_packs(all_packs)
    end

    context 'when using focus_pack' do
      it 'returns package lists filter with a list of focus packages (possibly with wildcards)' do
        @options.focus_pack = ['packs/something/a']
        expect(VisualizePacks.filtered(all_packs, @options)).to match_packs([@pack_a, @pack_s])

        @options.focus_pack = ['packs/*']
        expect(VisualizePacks.filtered(all_packs, @options)).to match_packs(all_packs)
      end

      it 'leaves parent packs in the result when filtering packages' do
        @options.focus_pack = ['packs/something/*']
        expect(VisualizePacks.filtered(all_packs, @options)).to match_packs([@pack_a, @pack_b, @pack_s])
      end

      it 'does not include non-focus dependencies if dependencies are not being shown' do
        @options.focus_pack = ['packs/something']
        @options.show_dependencies = false

        @pack_s_dependencies = ['packs/something/a']
        @pack_b_dependencies = ['packs/something']

        expect(VisualizePacks.filtered(all_packs, @options)).to match_packs([@pack_s])
      end

      it 'includes non-focus depdendents and dependees if dependencies are being shown' do
        @options.focus_pack = ['packs/something']
        @options.show_dependencies = true

        @pack_s_dependencies = ['packs/something/a']
        @pack_b_dependencies = ['packs/something']

        expect(VisualizePacks.filtered(all_packs, @options)).to match_packs([@pack_s, @pack_a, @pack_b])
      end

      it 'does not include non-focus packs with todos towards or from if todos are not being shown' do
        @options.focus_pack = ['packs/something']
        @options.show_todos = false

        @pack_s_todos = [@make_todo.call(:privacy, 'packs/something/a')]
        @pack_b_todos = [@make_todo.call(:privacy, 'packs/something')]

        expect(VisualizePacks.filtered(all_packs, @options)).to match_packs([@pack_s])
      end

      it 'does not include non-focus packs with todos towards or from if the todo type is being filtered' do
        @options.focus_pack = ['packs/something']
        @options.show_todos = true
        @options.only_todo_types = ['dependency']

        @pack_s_todos = [@make_todo.call(:privacy, 'packs/something/a')]
        @pack_b_todos = [@make_todo.call(:privacy, 'packs/something')]

        expect(VisualizePacks.filtered(all_packs, @options)).to match_packs([@pack_s])
      end

      it 'includes non-focus packs with todos from if the todo type is being shown' do
        @options.focus_pack = ['packs/something']
        @options.show_todos = true
        @options.only_todo_types = ['dependency']

        @pack_s_todos = [@make_todo.call(:dependency, 'packs/something/a'), @make_todo.call(:privacy, 'packs/something_else/c')]
        @pack_b_todos = [@make_todo.call(:dependency, 'packs/something')]

        expect(VisualizePacks.filtered(all_packs, @options)).to match_packs([@pack_s, @pack_a, @pack_b])
      end

      it 'includes non-focus packs with todos towards if the todo type is being shown IFF the direction is being shown (for Out)' do
        @options.focus_pack = ['packs/something']
        @options.show_todos = true
        @options.show_only_edges_to_focus_pack = FocusPackEdgeDirection::Out
        @options.only_todo_types = ['dependency']

        @pack_s_todos = [@make_todo.call(:dependency, 'packs/something/a')]
        @pack_b_todos = [@make_todo.call(:dependency, 'packs/something')]

        expect(VisualizePacks.filtered(all_packs, @options)).to match_packs([@pack_s, @pack_a])
      end

      it 'includes non-focus packs with todos towards if the todo type is being shown IFF the direction is being shown (for In)' do
        @options.focus_pack = ['packs/something']
        @options.show_todos = true
        @options.show_only_edges_to_focus_pack = FocusPackEdgeDirection::In
        @options.only_todo_types = ['dependency']

        @pack_s_todos = [@make_todo.call(:dependency, 'packs/something/a')]
        @pack_b_todos = [@make_todo.call(:dependency, 'packs/something')]

        expect(VisualizePacks.filtered(all_packs, @options)).to match_packs([@pack_s, @pack_b])
      end
    end

    context 'when using exclude_packs' do
      it 'returns package lists filter with a list of excluded packages (possibly with wildcards)' do
        @options.exclude_packs = ['packs/something/a']
        expect(VisualizePacks.filtered(all_packs, @options)).to match_packs([@pack_s, @pack_b, @pack_c, @pack_d, @pack_e])

        @options.exclude_packs = ['packs/something/*']
        expect(VisualizePacks.filtered(all_packs, @options)).to match_packs([@pack_s, @pack_c, @pack_d, @pack_e])

        @options.exclude_packs = ['packs/something', 'packs/something/*']
        expect(VisualizePacks.filtered(all_packs, @options)).to match_packs([@pack_c, @pack_d, @pack_e])
      end
    end
  end

  describe '.show_edge_builder' do
    subject {  VisualizePacks.show_edge_builder(@options, %w(a b c)) }

    it 'returns a proc' do
      @options = Options.new
      @package_names = []

      expect(subject).to be_a Proc
    end

    context "when show_only_edges_to_focus_pack is not set" do
      before do
        @options = Options.new
        @options.show_only_edges_to_focus_pack = FocusPackEdgeDirection::All
      end

      it "shows an edge IFF both start and end pack are in the list of packages" do
        expect(subject.call('a', 'b')).to be_truthy
        expect(subject.call('a', 'c')).to be_truthy
        expect(subject.call('a', 'd')).to be_falsy

        expect(subject.call('b', 'a')).to be_truthy
        expect(subject.call('b', 'c')).to be_truthy
        expect(subject.call('b', 'd')).to be_falsy

        expect(subject.call('c', 'a')).to be_truthy
        expect(subject.call('c', 'b')).to be_truthy
        expect(subject.call('c', 'd')).to be_falsy

        expect(subject.call('d', 'a')).to be_falsy
        expect(subject.call('d', 'b')).to be_falsy
        expect(subject.call('d', 'c')).to be_falsy
      end
    end

    context "when show_only_edges_to_focus_pack i set to in_out" do
      before do
        @options = Options.new
        @options.show_only_edges_to_focus_pack = FocusPackEdgeDirection::InOut
        @options.focus_pack = ['a']
      end

      it "shows an edge IFF both start and end pack are in the list of packages and one of the packs is the focus pack " do
        expect(subject.call('a', 'b')).to be_truthy
        expect(subject.call('a', 'c')).to be_truthy
        expect(subject.call('a', 'd')).to be_falsy

        expect(subject.call('b', 'a')).to be_truthy
        expect(subject.call('b', 'c')).to be_falsy
        expect(subject.call('b', 'd')).to be_falsy

        expect(subject.call('c', 'a')).to be_truthy
        expect(subject.call('c', 'b')).to be_falsy
        expect(subject.call('c', 'd')).to be_falsy

        expect(subject.call('d', 'a')).to be_falsy
        expect(subject.call('d', 'b')).to be_falsy
        expect(subject.call('d', 'c')).to be_falsy
      end
    end

    context "when show_only_edges_to_focus_pack i set to in" do
      before do
        @options = Options.new
        @options.show_only_edges_to_focus_pack = FocusPackEdgeDirection::In
        @options.focus_pack = ['a']
      end

      it "shows an edge IFF both start and end pack are in the list of packages and the arrow goes TOWARDS the focus pack" do
        expect(subject.call('a', 'b')).to be_falsy
        expect(subject.call('a', 'c')).to be_falsy
        expect(subject.call('a', 'd')).to be_falsy

        expect(subject.call('b', 'a')).to be_truthy
        expect(subject.call('b', 'c')).to be_falsy
        expect(subject.call('b', 'd')).to be_falsy

        expect(subject.call('c', 'a')).to be_truthy
        expect(subject.call('c', 'b')).to be_falsy
        expect(subject.call('c', 'd')).to be_falsy

        expect(subject.call('d', 'a')).to be_falsy
        expect(subject.call('d', 'b')).to be_falsy
        expect(subject.call('d', 'c')).to be_falsy
      end
    end

    context "when show_only_edges_to_focus_pack i set to out" do
      before do
        @options = Options.new
        @options.show_only_edges_to_focus_pack = FocusPackEdgeDirection::Out
        @options.focus_pack = ['a']
      end

      it "shows an edge IFF both start and end pack are in the list of packages and the arrow goes AWAY FROM the focus pack" do
        expect(subject.call('a', 'b')).to be_truthy
        expect(subject.call('a', 'c')).to be_truthy
        expect(subject.call('a', 'd')).to be_falsy

        expect(subject.call('b', 'a')).to be_falsy
        expect(subject.call('b', 'c')).to be_falsy
        expect(subject.call('b', 'd')).to be_falsy

        expect(subject.call('c', 'a')).to be_falsy
        expect(subject.call('c', 'b')).to be_falsy
        expect(subject.call('c', 'd')).to be_falsy

        expect(subject.call('d', 'a')).to be_falsy
        expect(subject.call('d', 'b')).to be_falsy
        expect(subject.call('d', 'c')).to be_falsy
      end
    end
  end
end