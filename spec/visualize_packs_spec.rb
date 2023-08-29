# frozen_string_literal: true

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


      result = VisualizePacks.remove_nested_packs([top_level_a, top_level_b, nested_a, nested_b])
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
    subject { VisualizePacks.limited_sentence(list) }

    context "with an empty list" do
      let(:list) { [] }

      it { is_expected.to eq "" }
    end

    context "with a list of 1 item" do
      let(:list) { ["foo"] }

      it { is_expected.to eq "foo" }
    end

    context "with a list of 2 items" do
      let(:list) { ["foo", "bar"] }

      it { is_expected.to eq "foo and bar" }
    end

    context "with a list of 3 items" do
      let(:list) { ["foo", "bar", "baz"] }

      it { is_expected.to eq "foo, bar, and 1 more" }
    end

    context "with a list of 4 items" do
      let(:list) { ["foo", "bar", "baz", "wow"] }

      it { is_expected.to eq "foo, bar, and 2 more" }
    end
  end

  describe ".todo_edge_width" do
    subject { VisualizePacks.todo_edge_width(todo_count, max_count) }

    # Define expectations this way:
    # [todo_count, max_count] => expected_value
    {
      [2, 3] => 5.5,
      [4, 10] => 4,
      [5, 10] => 5,
      [8, 10] => 8,
      [9, 10] => 9,
      [25, 100] => 3.18,
      [50, 100] => 5.45,
      [75, 100] => 7.73,
      [99, 100] => 9.91,
      [250, 1_000] => 3.24,
      [500, 1_000] => 5.5,
      [750, 1_000] => 7.75,
      [999, 1_000] => 9.99,
    }.group_by { |params, value| params.last }.each do |max_value, expectations|

      context "when max_count is #{max_value}" do
        let(:max_count) { max_value }

        context "and todo_count is 0" do
          let(:todo_count) { 0 }

          it { is_expected.to eq 0 }
        end

        context "and todo_count is 1" do
          let(:todo_count) { 1 }

          it { is_expected.to eq 1 }
        end

        expectations.each do |params, expected_value|
          count_value = params.first

          context "and todo_count is #{count_value}" do
            let(:todo_count) { count_value }

            it { is_expected.to eq expected_value }
          end
        end

        context "and todo_count is #{max_value}" do
          let(:todo_count) { max_value }

          it { is_expected.to eq 10 }
        end
      end
    end
  end

  describe '.exclude_pack?' do
    it 'does not exclude non-matches' do
      expect(VisualizePacks.exclude_pack?("pack", ["packs", "spack", "ack", "components"])).to be_falsy
    end

    it 'excludes matches' do
      expect(VisualizePacks.exclude_pack?("pack", ["pack", "park"])).to be_truthy
      expect(VisualizePacks.exclude_pack?("park", ["pack", "park"])).to be_truthy
    end

    it 'excludes matches using fnmatch' do
      expect(VisualizePacks.exclude_pack?("component", ["pack/*"])).to be_falsy
      expect(VisualizePacks.exclude_pack?("pack", ["pack/*"])).to be_falsy
      expect(VisualizePacks.exclude_pack?("pack/a", ["pack/*"])).to be_truthy
      expect(VisualizePacks.exclude_pack?("pack/a/b", ["pack/*"])).to be_truthy

      expect(VisualizePacks.exclude_pack?("pack/a/b", ["pack/*/b"])).to be_truthy
      expect(VisualizePacks.exclude_pack?("pack/a/c", ["pack/*/b"])).to be_falsy
    end
  end
end